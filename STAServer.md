# Govia - Hostinger VPS Server Deployment & Transition Manual (`STAServer.md`)

This document details the complete deployment architecture built for **Govia** and provides a step-by-step guide for deploying or migrating the entire application stack to a **Hostinger VPS** (or any cloud VPS provider) in the future.

---

## 📑 Table of Contents
1. [What Has Been Built & Configured](#1-what-has-been-built--configured)
2. [Hostinger VPS Architecture & Port Scheme](#2-hostinger-vps-architecture--port-scheme)
3. [Checklist of Future Changes for Hostinger Server](#3-checklist-of-future-changes-for-hostinger-server)
4. [Step-by-Step Hostinger Server Provisioning](#4-step-by-step-hostinger-server-provisioning)
5. [Domain DNS & Nginx Reverse Proxy Setup (with Free SSL)](#5-domain-dns--nginx-reverse-proxy-setup-with-free-ssl)
6. [GitHub Actions CI/CD Secrets Migration](#6-github-actions-cicd-secrets-migration)
7. [Database Migration / Restoration onto Hostinger](#7-database-migration--restoration-onto-hostinger)
8. [Maintenance, Health Checks & Rollback Commands](#8-maintenance-health-checks--rollback-commands)

---

## 1. What Has Been Built & Configured

The repository is structured as a **Turborepo Monorepo** with full Docker multi-stage containerization:

```
govia/
├── apps/
│   ├── api/                     # Express.js + Socket.IO + OpenAPI Swagger Backend
│   │   ├── Dockerfile           # Multi-stage production container (Node 20 Alpine, non-root user)
│   │   ├── src/                 # REST API routes, controllers, services, database models
│   │   └── package.json
│   └── admin/                   # Next.js 16 + React 19 + Tailwind CSS Admin Dashboard
│       ├── Dockerfile           # Multi-stage standalone SSR production container
│       ├── next.config.ts       # Configured with output: "standalone" & outputFileTracingRoot
│       └── package.json
├── packages/                    # Shared TypeScript configs, ESLint, UI, Types, Validators
├── .github/workflows/
│   ├── ci.yml                   # CI pipeline (lint, typecheck, build validation)
│   └── deploy.yml               # CD pipeline (Automated SSH deployment to VPS)
├── scripts/
│   ├── deploy.sh                # Single-command production build & deploy
│   ├── backup-mongo.sh          # Automated gzip database backup with 14-day retention
│   └── health-check.sh          # Real-time container, API & database health diagnostics
├── docker-compose.prod.yml      # Production multi-container orchestration
├── docker-compose.yml           # Local testing container orchestration
├── .dockerignore                # Optimized context filter for sub-second Docker builds
├── .env.example                 # Full template of production environment variables
└── DEPLOYMENT_GUIDE.md          # General deployment manual
```

---

## 2. Hostinger VPS Architecture & Port Scheme

On your Hostinger VPS, services run inside an isolated Docker bridge network:

```
                            ┌───────────────────────────────────────────────────────────┐
                            │                    Hostinger VPS Server                   │
                            │                                                           │
[ Mobile App / Flutter ] ──►│ ──► Host Port 9777 (or api.domain.com) ──► [ API Container:5000 ]
                            │                                                   │       │
                            │                                                   ▼       │
                            │                                           [ Mongo Container:27017 ]
                            │                                                   │       │
[ Browser / Admin ]      ──►│ ──► Host Port 8777 (or admin.domain.com)─► [ Admin Container:3000]
                            └───────────────────────────────────────────────────────────┘
```

| Service | Container Name | Host Port | Container Port | Exposure |
| :--- | :--- | :--- | :--- | :--- |
| **API & Socket.IO** | `adnan-govia-api` | `9777` (or `80/443` via Nginx) | `5000` | Public Internet |
| **Admin Dashboard** | `adnan-govia-admin` | `8777` (or `80/443` via Nginx) | `3000` | Public Internet |
| **MongoDB 7.0 Engine** | `adnan-govia-mongo` | *None* | `27017` | **Internal Network Only** |

> [!IMPORTANT]
> **MongoDB Security**: Port `27017` is **never exposed** to the public host or internet. It is accessible only by the API container through the internal Docker network `adnan_govia_network`.

---

## 3. Checklist of Future Changes for Hostinger Server

When you purchase your Hostinger VPS or transfer to a custom domain, you will only need to modify **three main areas**:

### 1. Environment Variables (`.env`)
Update the following variables to point to your Hostinger server IP or custom domain:

```env
# Change from old IP (172.252.13.197) to your Hostinger VPS IP or Domain:
# If using direct ports:
NEXT_PUBLIC_API_URL=http://<YOUR_HOSTINGER_IP>:9777/api/v1
NEXT_PUBLIC_SOCKET_URL=http://<YOUR_HOSTINGER_IP>:9777

# OR if using custom domains with Nginx & SSL (Recommended):
NEXT_PUBLIC_API_URL=https://api.yourdomain.com/api/v1
NEXT_PUBLIC_SOCKET_URL=https://api.yourdomain.com

# Update Production Secrets:
JWT_SECRET=<generate_new_64_character_random_string>
JWT_REFRESH_SECRET=<generate_new_64_character_random_string>
MONGO_INITDB_ROOT_PASSWORD=<strong_hostinger_database_password>

# Update SMTP / External APIs if required:
EMAIL_USER=<your_hostinger_or_gmail_smtp>
EMAIL_PASS=<your_smtp_app_password>
AI_API_KEY=<your_openrouter_api_key>
ZOOM_ACCOUNT_ID=<your_zoom_account_id>
ZOOM_CLIENT_ID=<your_zoom_client_id>
ZOOM_CLIENT_SECRET=<your_zoom_client_secret>
```

### 2. GitHub Actions Secrets
In your GitHub Repo (**Settings -> Secrets and variables -> Actions**), update:
- `VPS_SSH_HOST`: Set to your **Hostinger VPS IP**.
- `VPS_SSH_USER`: `root` or your custom Hostinger sudo user.
- `VPS_SSH_KEY` / `VPS_SSH_PASSWORD`: Hostinger SSH private key or root password.
- `VPS_DEPLOY_PATH`: `/var/www/govia` (or preferred path).
- `PROD_ENV_FILE`: Paste your updated production `.env` contents.

---

## 4. Step-by-Step Hostinger Server Provisioning

Follow these steps once you log into your fresh Hostinger VPS (Ubuntu 22.04 / 24.04 LTS recommended):

### Step 4.1: Connect to Hostinger VPS via SSH
```bash
ssh root@<YOUR_HOSTINGER_IP>
```

### Step 4.2: Update System & Install Docker + Docker Compose
Run the following commands on Hostinger:
```bash
# 1. Update system packages
sudo apt update && sudo apt upgrade -y
sudo apt install -y ca-certificates curl gnupg lsb-release git ufw

# 2. Add Docker's official GPG key & repository
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 3. Install Docker Engine and Compose Plugin
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 4. Enable Docker to start automatically on system boot
sudo systemctl enable docker
sudo systemctl start docker
```

### Step 4.3: Configure Hostinger Firewall / UFW
Allow necessary inbound ports:
```bash
sudo ufw allow 22/tcp      # SSH
sudo ufw allow 80/tcp      # HTTP (For Nginx / Certbot SSL)
sudo ufw allow 443/tcp     # HTTPS (For Nginx SSL)
sudo ufw allow 9777/tcp    # Govia API Port
sudo ufw allow 8777/tcp    # Govia Admin Dashboard Port
sudo ufw enable
```
*(Also check Hostinger's web panel "Security -> Firewall" and ensure ports 22, 80, 443, 9777, 8777 are enabled if Hostinger cloud firewall is turned on).*

### Step 4.4: Clone Repo & Prepare Directory
```bash
# Create deployment directory
mkdir -p /adnan/govia
cd /adnan/govia

# Clone your GitHub repository
git clone https://github.com/<your-username>/<your-repo>.git .

# Create production .env file
cp .env.example .env
nano .env   # Fill with your Hostinger IP / domain and passwords

# Make all deployment scripts executable
chmod +x scripts/*.sh
```

### Step 4.5: Run First Deployment
```bash
./scripts/deploy.sh
```

---

## 5. Domain DNS & Nginx Reverse Proxy Setup (with Free SSL)

To connect clean domains (e.g. `api.yourdomain.com` and `admin.yourdomain.com`) with automated Let's Encrypt SSL:

### Step 5.1: Add Hostinger DNS Records
In your Hostinger DNS Zone Management (or Cloudflare / Namecheap):

| Type | Name | Content / Target | TTL |
| :--- | :--- | :--- | :--- |
| `A` | `api` | `<YOUR_HOSTINGER_IP>` | Auto / 300 |
| `A` | `admin` | `<YOUR_HOSTINGER_IP>` | Auto / 300 |

### Step 5.2: Install Nginx & Certbot
```bash
sudo apt install -y nginx certbot python3-certbot-nginx
```

### Step 5.3: Create Nginx Configuration
Create `/etc/nginx/sites-available/govia.conf`:
```bash
sudo nano /etc/nginx/sites-available/govia.conf
```

Paste the following configuration:
```nginx
# ==============================================================================
# Govia Express API & Socket.IO Reverse Proxy
# ==============================================================================
server {
    listen 80;
    server_name api.yourdomain.com;

    client_max_body_size 50M;

    location / {
        proxy_pass http://127.0.0.1:9777;
        proxy_http_version 1.1;

        # WebSocket & Socket.IO real-time upgrade headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # Client info forwarding
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        proxy_read_timeout 86400s;
        proxy_send_timeout 86400s;
    }
}

# ==============================================================================
# Govia Next.js Admin Dashboard Reverse Proxy
# ==============================================================================
server {
    listen 80;
    server_name admin.yourdomain.com;

    client_max_body_size 20M;

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

Enable the configuration and test Nginx:
```bash
sudo ln -s /etc/nginx/sites-available/govia.conf /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
```

### Step 5.4: Install Free SSL via Let's Encrypt
```bash
sudo certbot --nginx -d api.yourdomain.com -d admin.yourdomain.com
```
*Certbot will automatically install HTTPS SSL certificates and configure auto-renewal.*

---

## 6. GitHub Actions CI/CD Secrets Migration

When moving to Hostinger, update your GitHub Repository Secrets (**Repository -> Settings -> Secrets and variables -> Actions**):

| Secret Name | Hostinger Value |
| :--- | :--- |
| `VPS_SSH_HOST` | Hostinger VPS Public IP |
| `VPS_SSH_USER` | `root` (or custom user) |
| `VPS_SSH_KEY` | Private SSH Key generated on Hostinger (`~/.ssh/id_rsa` or `~/.ssh/id_ed25519`) |
| `VPS_SSH_PASSWORD` | *(Leave empty if using SSH key, or enter Hostinger root password)* |
| `VPS_SSH_PORT` | `22` |
| `VPS_DEPLOY_PATH` | `/var/www/govia` |
| `PROD_ENV_FILE` | Full contents of your updated production `.env` |

Now, every time you push code to `main` via `git push origin main`, GitHub Actions will automatically connect to Hostinger, pull code, rebuild Docker containers, and verify health with zero manual intervention.

---

## 7. Database Migration / Restoration onto Hostinger

If you already have data on your old server and need to move it to Hostinger:

### 1. Create a backup on old server:
```bash
./scripts/backup-mongo.sh
# Creates file: ./backups/mongo/govia_backup_YYYYMMDD_HHMMSS.gz
```

### 2. Copy the backup file to Hostinger VPS:
```bash
scp ./backups/mongo/govia_backup_*.gz root@<HOSTINGER_IP>:/var/www/govia/backups/
```

### 3. Restore data into the Hostinger MongoDB container:
```bash
docker exec -i adnan-govia-mongo mongorestore \
  --username goviaAdmin \
  --password "<YOUR_NEW_MONGO_PASSWORD>" \
  --authenticationDatabase admin \
  --archive --gzip < /var/www/govia/backups/govia_backup_*.gz
```

---

## 8. Maintenance, Health Checks & Rollback Commands

### 🔍 System Health Check
Run the diagnostic script anytime on Hostinger to check if all services and databases are healthy:
```bash
./scripts/health-check.sh
```

### 📊 View Live Logs
```bash
# Stream Express API logs
docker compose -f docker-compose.prod.yml logs -f adnan-govia-api

# Stream Admin Dashboard logs
docker compose -f docker-compose.prod.yml logs -f adnan-govia-admin

# Stream MongoDB logs
docker compose -f docker-compose.prod.yml logs -f adnan-govia-mongo
```

### 💾 Create On-Demand Database Backup
```bash
./scripts/backup-mongo.sh
```

### 🔄 Restart All Services
```bash
docker compose -f docker-compose.prod.yml restart
```

### ⏪ Instant Rollback
If a faulty commit was deployed:
```bash
git checkout <previous-stable-commit-hash>
./scripts/deploy.sh
```

---

## 🚀 Quick Reference Summary

| Task | Command on Hostinger VPS |
| :--- | :--- |
| **Deploy / Update** | `cd /var/www/govia && ./scripts/deploy.sh` |
| **Health Check** | `cd /var/www/govia && ./scripts/health-check.sh` |
| **Backup DB** | `cd /var/www/govia && ./scripts/backup-mongo.sh` |
| **View API Logs** | `docker compose -f docker-compose.prod.yml logs -f adnan-govia-api` |
| **Restart Stack** | `docker compose -f docker-compose.prod.yml restart` |
