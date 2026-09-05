# Govia Production Deployment & CI/CD Guide

This guide provides step-by-step instructions for deploying the **Govia Monorepo** (Express API + Socket.IO, Next.js Admin Dashboard, and MongoDB) to your Ubuntu/Debian VPS (`172.252.13.197`) using Docker Compose and automated GitHub Actions CI/CD.

---

## 1. System Architecture & Port Isolation

To guarantee complete isolation on shared servers without port conflicts:

| Service | Container Name | Host Port | Internal Port | Access Scope |
| :--- | :--- | :--- | :--- | :--- |
| **Express API & Socket.IO** | `adnan-govia-api` | `9777` | `5000` | Public / Reverse Proxy |
| **Next.js Admin Dashboard** | `adnan-govia-admin` | `8777` | `3000` | Public / Reverse Proxy |
| **MongoDB 7.0 Engine** | `adnan-govia-mongo` | *None* | `27017` | **Internal Network Only** (`adnan_govia_network`) |

```
                              ┌────────────────────────────────────────────────────────┐
                              │                 Remote VPS (172.252.13.197)            │
                              │                                                        │
[ Client / App / Flutter ] ──►│ ──► Host Port 9777 ──► [ adnan-govia-api:5000 ]       │
                              │                                 │                      │
                              │                                 ▼ (Internal Network)   │
                              │                         [ adnan-govia-mongo:27017 ]    │
                              │                                                        │
[ Browser / Admin ]        ──►│ ──► Host Port 8777 ──► [ adnan-govia-admin:3000 ]     │
                              └────────────────────────────────────────────────────────┘
```

---

## 2. GitHub Actions Secrets Configuration

To enable one-click automated deployments on `git push origin main`, add the following secrets to your GitHub repository (**Settings -> Secrets and variables -> Actions -> New repository secret**):

| Secret Name | Description | Example / Recommended Value |
| :--- | :--- | :--- |
| `VPS_SSH_HOST` | VPS Public IPv4 Address | `172.252.13.197` |
| `VPS_SSH_USER` | SSH Username | `root` or `ubuntu` or `adnan` |
| `VPS_SSH_KEY` | Private SSH Key for authentication | `-----BEGIN OPENSSH PRIVATE KEY----- ...` |
| `VPS_SSH_PASSWORD` | SSH Password (if not using SSH Key) | `YourSecureVpsPassword` |
| `VPS_SSH_PORT` | SSH Port (default: 22) | `22` |
| `VPS_DEPLOY_PATH` | Monorepo Directory on VPS | `/adnan/govia` |
| `PROD_ENV_FILE` | Complete `.env` file contents | *(Paste contents formatted according to `.env.example`)* |

---

## 3. Remote VPS Initial Setup (One-Time)

Connect to your VPS:
```bash
ssh root@172.252.13.197
```

### 3.1 Install Docker & Docker Compose Plugin
```bash
# Update package repositories
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# Add Docker's official GPG key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up the repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker Engine and Compose
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Enable and start Docker service
sudo systemctl enable docker
sudo systemctl start docker
```

### 3.2 Configure UFW Firewall
Allow incoming traffic to the designated host ports:
```bash
sudo ufw allow 22/tcp     # SSH
sudo ufw allow 80/tcp     # HTTP (Nginx)
sudo ufw allow 443/tcp    # HTTPS (Nginx SSL)
sudo ufw allow 9777/tcp   # Govia Express API
sudo ufw allow 8777/tcp   # Govia Admin Dashboard
sudo ufw enable
```

---

## 4. Manual Deployment Workflow

If you prefer to deploy manually or test on the server:

```bash
# 1. Clone repository
git clone https://github.com/<your-org>/govia.git /var/www/govia
cd /var/www/govia

# 2. Copy and configure .env
cp .env.example .env
nano .env

# 3. Make scripts executable
chmod +x scripts/*.sh

# 4. Deploy production containers
./scripts/deploy.sh
```

---

## 5. Production Maintenance & Utilities

### 5.1 Real-Time Log Streaming
```bash
# Stream API logs
docker compose -f docker-compose.prod.yml logs -f adnan-govia-api

# Stream Admin Dashboard logs
docker compose -f docker-compose.prod.yml logs -f adnan-govia-admin

# Stream MongoDB logs
docker compose -f docker-compose.prod.yml logs -f adnan-govia-mongo
```

### 5.2 Automated Database Backups
Create an immediate snapshot backup of MongoDB:
```bash
./scripts/backup-mongo.sh
```
*Backups are saved to `./backups/mongo/` in compressed `.gz` format and retained for 14 days.*

To set up an automated daily midnight backup cron job:
```bash
crontab -e
# Add line:
0 0 * * * /var/www/govia/scripts/backup-mongo.sh >> /var/www/govia/backups/backup.log 2>&1
```

### 5.3 System Diagnostic & Health Verification
```bash
./scripts/health-check.sh
```

---

## 6. Nginx Reverse Proxy with Domain & SSL (Optional)

If you wish to route custom domains with SSL certificates:

```nginx
# /etc/nginx/sites-available/govia.conf

# Govia API & Socket.IO
server {
    server_name api.govia.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:9777;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# Govia Admin Dashboard
server {
    server_name admin.govia.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8777;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Enable SSL via Certbot:
```bash
sudo certbot --nginx -d api.govia.yourdomain.com -d admin.govia.yourdomain.com
```

---

## 7. Rollback Strategy

If an issue occurs after deploying a new release:
```bash
# 1. Rollback Git commit on server
cd /var/www/govia
git checkout <previous-stable-commit-hash>

# 2. Re-trigger deployment script
./scripts/deploy.sh
```
