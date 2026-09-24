#!/usr/bin/env bash
# ==============================================================================
# Govia Zero-Downtime Blue/Green Deployment Engine
# ==============================================================================
set -euo pipefail

cd /adnan/govia

echo "========================================================"
echo "🚀 Starting Govia Zero-Downtime Blue/Green Deployment"
echo "========================================================"

# Check if host Nginx is active
if ! systemctl is-active --quiet nginx 2>/dev/null; then
  echo "ℹ️ Host Nginx is not active (shared reverse proxy detected). Deploying production stack directly on ports 9777 & 8777..."
  docker compose -f docker-compose.prod.yml pull
  docker compose -f docker-compose.prod.yml up -d --remove-orphans
  docker image prune -f || true
  sleep 5
  docker compose -f docker-compose.prod.yml ps
  echo "========================================================"
  echo "🎉 GOVIA DEPLOYMENT SUCCESSFUL!"
  echo "   👉 API:   http://127.0.0.1:9777/api/v1/docs"
  echo "   👉 Admin: http://127.0.0.1:8777"
  echo "========================================================"
  exit 0
fi

# 1. Determine currently active color
ACTIVE_COLOR_FILE="/adnan/govia/.active_color"
CURRENT_COLOR="blue"

if [ -f "$ACTIVE_COLOR_FILE" ]; then
  CURRENT_COLOR=$(cat "$ACTIVE_COLOR_FILE" | tr -d '[:space:]')
fi

# Determine standby (target) color and ports
if [ "$CURRENT_COLOR" = "blue" ]; then
  TARGET_COLOR="green"
  TARGET_API_PORT=9778
  TARGET_ADMIN_PORT=8778
  PREV_API_PORT=9777
  PREV_ADMIN_PORT=8777
else
  TARGET_COLOR="blue"
  TARGET_API_PORT=9777
  TARGET_ADMIN_PORT=8777
  PREV_API_PORT=9778
  PREV_ADMIN_PORT=8778
fi

echo "🟢 Currently active environment: ${CURRENT_COLOR}"
echo "🎯 Target standby environment:   ${TARGET_COLOR} (API: ${TARGET_API_PORT} | Admin: ${TARGET_ADMIN_PORT})"

# 2. Pull latest images from GHCR
echo "📥 Pulling latest images..."
docker compose -f docker-compose.bluegreen.yml pull adnan-govia-mongo || true
docker compose -f docker-compose.bluegreen.yml --profile "$TARGET_COLOR" pull

# 3. Ensure shared MongoDB is healthy
echo "🍃 Ensuring MongoDB is running and healthy..."
docker compose -f docker-compose.bluegreen.yml up -d adnan-govia-mongo

# 4. Start Target Standby Environment
echo "🚀 Booting ${TARGET_COLOR} containers..."
docker compose -f docker-compose.bluegreen.yml --profile "$TARGET_COLOR" up -d --remove-orphans

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

  if [ "$API_STATUS" = "200" ] && { [ "$ADMIN_STATUS" = "200" ] || [ "$ADMIN_STATUS" = "307" ] || [ "$ADMIN_STATUS" = "308" ]; }; then
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

  nginx -t && nginx -s reload
  echo "🎉 Zero-downtime traffic switch completed via Nginx reload!"

  # Record new active color
  echo "$TARGET_COLOR" > "$ACTIVE_COLOR_FILE"

  # Stop and remove previous color containers
  echo "🛑 Tearing down previous (${CURRENT_COLOR}) containers..."
  docker compose -f docker-compose.bluegreen.yml --profile "$CURRENT_COLOR" stop || true
  docker compose -f docker-compose.bluegreen.yml --profile "$CURRENT_COLOR" rm -f || true

  # Also remove any legacy unprofiled containers from old compose setup
  docker rm -f adnan-govia-api adnan-govia-admin 2>/dev/null || true

  # Clean up dangling images
  echo "🧹 Pruning unused Docker images..."
  docker image prune -f || true

  echo "========================================================"
  echo "🎉 GOVIA DEPLOYMENT SUCCESSFUL! ACTIVE: ${TARGET_COLOR}"
  echo "   👉 API:   http://127.0.0.1:${TARGET_API_PORT}/api/v1/docs"
  echo "   👉 Admin: http://127.0.0.1:${TARGET_ADMIN_PORT}"
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

  echo "✅ Active (${CURRENT_COLOR}) environment remains LIVE with zero interruption."
  exit 1
fi
