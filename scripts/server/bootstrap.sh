#!/usr/bin/env bash
# ==============================================================================
# Govia Server Self-Bootstrapping Script (Idempotent Setup)
# ==============================================================================
set -euo pipefail

echo "========================================================"
echo "🚀 Govia Production Server Bootstrap (Idempotent Setup)"
echo "========================================================"

# 1. Memory Swapfile Setup (2GB swap if total swap < 1.5GB)
CURRENT_SWAP=$(free -m | awk '/Swap:/ {print $2}')
if [ "$CURRENT_SWAP" -lt 1500 ]; then
  echo "🧠 Configuring 2GB Swapfile to prevent Out-Of-Memory spikes..."
  if [ ! -f /swapfile ]; then
    if ! fallocate -l 2G /swapfile 2>/dev/null; then
      dd if=/dev/zero of=/swapfile bs=1M count=2048
    fi
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile || true
    if ! grep -q "/swapfile" /etc/fstab; then
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
    echo "✅ 2GB Swapfile successfully activated!"
  else
    swapon /swapfile 2>/dev/null || true
  fi
else
  echo "✅ Memory swap already present (${CURRENT_SWAP}MB)."
fi

# 2. Package Dependencies (Wait for any in-flight background apt locks)
echo "📦 Checking package manager locks and updating system packages..."
while fuser /var/lib/dpkg/lock >/dev/null 2>&1 || fuser /var/lib/apt/lists/lock >/dev/null 2>&1 || fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do
  echo "⏳ Waiting for concurrent apt lock to release..."
  sleep 2
done

apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq \
  curl ca-certificates gnupg lsb-release \
  nginx certbot python3-certbot-nginx ufw cron

# 3. Docker Engine & Docker Compose Plugin
if ! command -v docker &>/dev/null; then
  echo "🐳 Docker not found. Installing Docker Engine & Compose plugin..."
  curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
  sh /tmp/get-docker.sh
  systemctl enable docker
  systemctl start docker
  echo "✅ Docker successfully installed!"
else
  echo "✅ Docker is already installed: $(docker --version)"
fi

# 4. Setup Govia Production Directories
echo "📁 Preparing directory structure..."
mkdir -p /adnan/govia/scripts/server
mkdir -p /adnan/govia/backups/mongodb

# Copy backup script into production path
if [ -f /adnan/govia/scripts/server/backup-mongo.sh ]; then
  cp /adnan/govia/scripts/server/backup-mongo.sh /adnan/govia/scripts/backup-mongo.sh
  chmod +x /adnan/govia/scripts/backup-mongo.sh
fi

# 5. Schedule Automated Daily MongoDB Backup (02:00 AM UTC, 7-day retention)
CRON_JOB="0 2 * * * /adnan/govia/scripts/backup-mongo.sh >> /adnan/govia/backups/mongodb/backup.log 2>&1"
if ! crontab -l 2>/dev/null | grep -Fq "backup-mongo.sh"; then
  echo "⏰ Registering daily MongoDB backup cron job..."
  (crontab -l 2>/dev/null || true; echo "$CRON_JOB") | crontab -
  echo "✅ Backup cron job scheduled at 02:00 AM UTC."
else
  echo "✅ Backup cron job is already scheduled."
fi

# 6. Setup Nginx Upstreams & Reverse Proxy
echo "🌐 Configuring Nginx Upstreams & Sites..."
mkdir -p /etc/nginx/conf.d

if [ ! -f /etc/nginx/conf.d/govia_upstreams.conf ]; then
  cat << 'EOF' > /etc/nginx/conf.d/govia_upstreams.conf
upstream govia_api_upstream {
    server 127.0.0.1:9777;
    keepalive 32;
}

upstream govia_admin_upstream {
    server 127.0.0.1:8777;
    keepalive 32;
}
EOF
fi

if [ -f /adnan/govia/scripts/server/nginx-govia.conf ]; then
  cp /adnan/govia/scripts/server/nginx-govia.conf /etc/nginx/sites-available/govia.conf
  ln -sf /etc/nginx/sites-available/govia.conf /etc/nginx/sites-enabled/govia.conf
  rm -f /etc/nginx/sites-enabled/default || true
fi

# Test and enable/reload Nginx
systemctl enable nginx || true
if nginx -t 2>/dev/null; then
  systemctl restart nginx || systemctl reload nginx || true
  echo "✅ Nginx reverse proxy active and configured."
else
  echo "⚠️ Nginx test warning. Will be reloaded during deployment."
fi

# Enable Certbot auto-renewal timer
systemctl enable --now certbot.timer 2>/dev/null || true

# 7. Firewall Configuration (UFW)
echo "🛡️ Configuring UFW firewall rules..."
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 9777/tcp || true
ufw allow 9778/tcp || true
ufw allow 8777/tcp || true
ufw allow 8778/tcp || true
ufw --force enable || true

# 8. Ensure MongoDB Container is Running (with 256MB WiredTiger memory limit)
if [ -f /adnan/govia/docker-compose.bluegreen.yml ]; then
  echo "🍃 Booting persistent MongoDB container (256MB cache cap)..."
  cd /adnan/govia
  docker compose -f docker-compose.bluegreen.yml up -d adnan-govia-mongo || true
fi

echo "========================================================"
echo "🎉 Server bootstrap successfully completed!"
echo "========================================================"
