#!/usr/bin/env bash
# ==============================================================================
# Govia Server Self-Bootstrapping Script (Idempotent)
# ==============================================================================
set -euo pipefail

echo "========================================================"
echo "🚀 Govia Production Server Bootstrap"
echo "========================================================"

# 1. Memory Swapfile Setup (2GB swap if total swap < 2GB)
CURRENT_SWAP=$(free -m | awk '/Swap:/ {print $2}')
if [ "$CURRENT_SWAP" -lt 1500 ]; then
  echo "🧠 Creating 2GB Swapfile to prevent Out-Of-Memory spikes..."
  if [ ! -f /swapfile ]; then
    fallocate -l 2G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=2048
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    if ! grep -q "/swapfile" /etc/fstab; then
      echo '/swapfile none swap sw 0 0' >> /etc/fstab
    fi
    echo "✅ 2GB Swapfile successfully activated!"
  else
    swapon /swapfile || true
  fi
else
  echo "✅ Memory swap already present (${CURRENT_SWAP}MB)."
fi

# 2. Package Dependencies (Nginx, Certbot, UFW, Cron)
echo "📦 Checking system packages..."
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq nginx certbot python3-certbot-nginx ufw cron curl

# 3. Setup Govia Directories
mkdir -p /adnan/govia/scripts
mkdir -p /adnan/govia/backups/mongodb

# Copy backup script into production path
if [ -f /adnan/govia/scripts/server/backup-mongo.sh ]; then
  cp /adnan/govia/scripts/server/backup-mongo.sh /adnan/govia/scripts/backup-mongo.sh
  chmod +x /adnan/govia/scripts/backup-mongo.sh
fi

# 4. Schedule Automated Daily MongoDB Backup (02:00 AM UTC)
CRON_JOB="0 2 * * * /adnan/govia/scripts/backup-mongo.sh >> /adnan/govia/backups/mongodb/backup.log 2>&1"
if ! crontab -l 2>/dev/null | grep -Fq "backup-mongo.sh"; then
  echo "⏰ Registering daily MongoDB backup cron job..."
  (crontab -l 2>/dev/null || true; echo "$CRON_JOB") | crontab -
  echo "✅ Backup cron job scheduled at 02:00 AM UTC."
else
  echo "✅ Backup cron job is already scheduled."
fi

# 5. Setup Nginx Upstreams & Reverse Proxy
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

# Test and reload Nginx
nginx -t && systemctl reload nginx || systemctl restart nginx
echo "✅ Nginx reverse proxy active!"

# 6. Firewall Configuration
echo "🛡️ Configuring UFW firewall rules..."
ufw allow 22/tcp || true
ufw allow 80/tcp || true
ufw allow 443/tcp || true
ufw allow 9777/tcp || true
ufw allow 9778/tcp || true
ufw allow 8777/tcp || true
ufw allow 8778/tcp || true
ufw --force enable || true

echo "🎉 Server bootstrap successfully completed!"
