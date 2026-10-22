#!/usr/bin/env bash
# ==============================================================================
# Govia Zero-Downtime Blue/Green Deployment Engine
# ==============================================================================
set -euo pipefail

cd /adnan/govia

# Ensure GitHub Container Registry owner is lowercase
export GH_REPO_OWNER="${GH_REPO_OWNER:-adnanmahmud0}"
GH_REPO_OWNER=$(echo "$GH_REPO_OWNER" | tr '[:upper:]' '[:lower:]')
export GH_REPO_OWNER

echo "========================================================"
echo "🚀 Starting Govia Zero-Downtime Blue/Green Deployment"
echo "========================================================"

# Ensure Nginx is running
if ! systemctl is-active --quiet nginx 2>/dev/null; then
  echo "🌐 Starting Nginx service..."
  systemctl start nginx || true
fi

# 1. Determine currently active color
ACTIVE_COLOR_FILE="/adnan/govia/.active_color"

if docker ps --format '{{.Names}}' | grep -q "adnan-govia-api-blue"; then
  CURRENT_COLOR="blue"
  TARGET_COLOR="green"
  TARGET_API_PORT=9778
  TARGET_ADMIN_PORT=8778
elif docker ps --format '{{.Names}}' | grep -q "adnan-govia-api-green"; then
  CURRENT_COLOR="green"
  TARGET_COLOR="blue"
  TARGET_API_PORT=9777
  TARGET_ADMIN_PORT=8777
elif [ -f "$ACTIVE_COLOR_FILE" ] && [ "$(cat "$ACTIVE_COLOR_FILE" | tr -d '[:space:]')" = "green" ]; then
  CURRENT_COLOR="green"
  TARGET_COLOR="blue"
  TARGET_API_PORT=9777
  TARGET_ADMIN_PORT=8777
else
  # Clean server fallback: deploy to primary blue ports first
  CURRENT_COLOR="none"
  TARGET_COLOR="blue"
  TARGET_API_PORT=9777
  TARGET_ADMIN_PORT=8777
fi

echo "🟢 Currently active environment: ${CURRENT_COLOR}"
echo "🎯 Target standby environment:   ${TARGET_COLOR} (API: ${TARGET_API_PORT} | Admin: ${TARGET_ADMIN_PORT})"

# 2. Pull latest images from GHCR
echo "📥 Pulling latest images from GHCR..."
docker compose -f docker-compose.bluegreen.yml pull adnan-govia-mongo || true
docker compose -f docker-compose.bluegreen.yml --profile "$TARGET_COLOR" pull

# 3. Ensure shared MongoDB is healthy
echo "🍃 Ensuring MongoDB is running and healthy..."
docker compose -f docker-compose.bluegreen.yml up -d adnan-govia-mongo

# 4. Start Target Standby Environment
echo "🚀 Booting ${TARGET_COLOR} containers on standby ports..."
docker compose -f docker-compose.bluegreen.yml --profile "$TARGET_COLOR" up -d

# 5. Health Check Polling Loop (Max 90s)
echo "⏳ Validating ${TARGET_COLOR} health (timeout: 90s)..."
MAX_ATTEMPTS=30
ATTEMPT=0
HEALTHY=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  ATTEMPT=$((ATTEMPT + 1))
  sleep 3

  API_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${TARGET_API_PORT}/health" 2>/dev/null || echo "000")
  ADMIN_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${TARGET_ADMIN_PORT}/" 2>/dev/null || echo "000")

  echo "   [Attempt ${ATTEMPT}/${MAX_ATTEMPTS}] API :${TARGET_API_PORT} -> HTTP ${API_STATUS} | Admin :${TARGET_ADMIN_PORT} -> HTTP ${ADMIN_STATUS}"

  if [ "$API_STATUS" = "200" ] && [[ "$ADMIN_STATUS" =~ ^(200|301|302|307|308)$ ]]; then
    HEALTHY=1
    break
  fi
done

# 6. Switch Traffic or Rollback
if [ $HEALTHY -eq 1 ]; then
  echo "✅ Target environment (${TARGET_COLOR}) is 100% HEALTHY!"

  echo "🔄 Switching Nginx upstream traffic to ${TARGET_COLOR}..."
  cat << EOF > /etc/nginx/conf.d/govia_upstreams.conf
upstream govia_api_upstream {
    server 127.0.0.1:${TARGET_API_PORT};
    keepalive 32;
}

upstream govia_admin_upstream {
    server 127.0.0.1:${TARGET_ADMIN_PORT};
    keepalive 32;
}
EOF

  if nginx -t; then
    nginx -s reload || systemctl reload nginx
    echo "🎉 Zero-downtime traffic switch completed via Nginx reload!"
  else
    echo "⚠️ Nginx test failed. Restarting Nginx service..."
    systemctl restart nginx
  fi

  # Record new active color
  echo "$TARGET_COLOR" > "$ACTIVE_COLOR_FILE"

  # Stop and remove previous color containers if they were running
  if [ "$CURRENT_COLOR" != "none" ] && [ "$CURRENT_COLOR" != "$TARGET_COLOR" ]; then
    echo "🛑 Tearing down previous (${CURRENT_COLOR}) containers..."
    docker stop "adnan-govia-api-${CURRENT_COLOR}" "adnan-govia-admin-${CURRENT_COLOR}" 2>/dev/null || true
    docker rm -f "adnan-govia-api-${CURRENT_COLOR}" "adnan-govia-admin-${CURRENT_COLOR}" 2>/dev/null || true
    # Guarantee MongoDB container is running and healthy
    docker compose -f docker-compose.bluegreen.yml up -d adnan-govia-mongo
  fi

  # Clean up any legacy unprofiled containers from old compose setup
  docker rm -f adnan-govia-api adnan-govia-admin 2>/dev/null || true

  # Clean up dangling images older than 24h
  echo "🧹 Pruning unused Docker images..."
  docker image prune -af --filter "until=24h" || docker image prune -f || true

  echo "========================================================"
  echo "🎉 GOVIA DEPLOYMENT SUCCESSFUL! ACTIVE: ${TARGET_COLOR}"
  echo "   👉 API Backend:    http://127.0.0.1:${TARGET_API_PORT}/health"
  echo "   👉 Admin Frontend: http://127.0.0.1:${TARGET_ADMIN_PORT}"
  echo "========================================================"
else
  echo "❌ ERROR: Target environment (${TARGET_COLOR}) FAILED health check!"
  echo "📋 API Logs (${TARGET_COLOR}):"
  docker logs "adnan-govia-api-${TARGET_COLOR}" --tail 30 || true

  echo "📋 Admin Logs (${TARGET_COLOR}):"
  docker logs "adnan-govia-admin-${TARGET_COLOR}" --tail 30 || true

  echo "🛡️ ROLLING BACK: Tearing down failed ${TARGET_COLOR} containers..."
  docker compose -f docker-compose.bluegreen.yml --profile "$TARGET_COLOR" stop || true
  docker compose -f docker-compose.bluegreen.yml --profile "$TARGET_COLOR" rm -f || true

  if [ "$CURRENT_COLOR" != "none" ]; then
    echo "✅ Active (${CURRENT_COLOR}) environment remains LIVE with zero interruption."
  fi
  exit 1
fi
