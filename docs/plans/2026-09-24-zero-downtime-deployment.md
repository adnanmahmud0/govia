# Govia Zero-Manual-SSH Blue/Green CI/CD & Production Deployment Plan

> **Goal:** Transform Govia's deployment into a fully autonomous, zero-manual-SSH, Blue/Green zero-downtime CI/CD pipeline driven by a **single unified `.env` variable** (`PROD_ENV`), featuring automated server self-bootstrapping, healthcheck validation, daily MongoDB backups, and cloud-compiled Flutter release APKs.

---

## 🏗 High-Level Architecture & Unified Configuration

### 1. The 4-Section Root `.env` Architecture
All microservices, server connection parameters, mobile application endpoints, web admin portals, and database credentials originate from a single, unified root `.env` partitioned into four standard blocks:

```env
#-----------------server con start----------------
SERVER_HOST=172.252.13.197
SERVER_USER=root
SERVER_PASSWORD=your_server_password_here
SERVER_SSH_PORT=22
DOMAIN_NAME=
#-----------------server con end----------------


#-----------------app start----------------
API_BASE_URL=http://172.252.13.197:9777/api/v1
FLUTTER_API_BASE_URL=http://172.252.13.197:9777/api/v1
FLUTTER_SOCKET_URL=http://172.252.13.197:9777
LIVEKIT_URL=wss://your-project.livekit.cloud
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_api_secret
APP_ENV=production
#-----------------app end----------------


#-----------------frontend start----------------
NEXT_PUBLIC_BASE_URL=http://172.252.13.197:9777/api/v1
NEXT_PUBLIC_API_URL=http://172.252.13.197:9777/api/v1
NEXT_PUBLIC_SOCKET_URL=http://172.252.13.197:9777
HOST_ADMIN_PORT=8777
#-----------------frontend end----------------


#-----------------backend start----------------
NODE_ENV=production
PORT=5000
HOST_API_PORT=9777
IP_ADDRESS=0.0.0.0
PROJECT_NAME=Govia
ENABLE_API_DOCS=true

# Database (MongoDB)
MONGO_INITDB_ROOT_USERNAME=goviaAdmin
MONGO_INITDB_ROOT_PASSWORD=your_mongo_password
MONGO_INITDB_DATABASE=govia-db
DATABASE_URL=mongodb://goviaAdmin:your_mongo_password@adnan-govia-mongo:27017/govia-db?authSource=admin

# Security & Auth
BCRYPT_SALT_ROUNDS=10
JWT_SECRET=your_jwt_secret
JWT_EXPIRE_IN=1h
JWT_REFRESH_SECRET=your_jwt_refresh_secret
JWT_REFRESH_EXPIRE_IN=7d

# Super Admin Initial Credentials
SUPER_ADMIN_EMAIL=admin@govia.com
SUPER_ADMIN_PASSWORD=your_admin_password

# AI Integration (OpenRouter)
AI_PROVIDER_BASE_URL=https://openrouter.ai/api/v1
AI_API_KEY=your_openrouter_api_key
AI_MODEL_NAME=openrouter/free

# Email / SMTP (Gmail App Password)
EMAIL_FROM=adnan99mahmud@gmail.com
EMAIL_USER=adnan99mahmud@gmail.com
EMAIL_PORT=587
EMAIL_HOST=smtp.gmail.com
EMAIL_PASS=your_gmail_app_password

# AWS S3 Cloud Storage for Meeting Recordings (LiveKit Egress)
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
AWS_BUCKET=govia-meeting-recordings
AWS_REGION=us-east-1

S3_BUCKET=govia-meeting-recordings
S3_REGION=us-east-1
S3_ACCESS_KEY=your_aws_access_key_id
S3_SECRET_KEY=your_aws_secret_access_key
S3_ENDPOINT=
#-----------------backend end----------------
```

### 2. How the Unified Secret Works in CI/CD
Instead of managing 20 individual secrets in GitHub, you only configure **ONE secret** in GitHub Repository Secrets: `PROD_ENV`.

In the GitHub Actions runner:
```yaml
- name: Unpack Production Environment Configuration
  run: |
    echo "${{ secrets.PROD_ENV }}" > .env
    set -a
    source .env
    set +a
```
1. **Server Connection:** GitHub Actions extracts `SERVER_HOST`, `SERVER_USER`, `SERVER_PASSWORD`, and `SERVER_SSH_PORT` directly from the `server con` block to connect via SSH without manual prompt.
2. **Flutter App (`gsabino365`):** Automatically copies the environment variables into `gsabino365/.env` so `flutter build apk --release` bundles the exact server endpoints and LiveKit cloud keys.
3. **Admin Dashboard (`apps/admin`):** Passes `NEXT_PUBLIC_API_URL` and `NEXT_PUBLIC_SOCKET_URL` from the `frontend` block as Docker build arguments for client-side bundle compilation.
4. **Server Deployment (`/adnan/govia/.env`):** Uploads the `.env` securely with permissions `chmod 600`. Docker Compose loads `env_file: .env` across all containers (`adnan-govia-api`, `adnan-govia-admin`, and `adnan-govia-mongo`).

---

## 📋 What YOU Need to Do (User Checklist)

You only have **2 simple actions** to perform in GitHub:

### 1. Enable GitHub Actions Write Permissions (One-Time)
1. Open your repository: [https://github.com/adnanmahmud0/govia](https://github.com/adnanmahmud0/govia)
2. Go to **Settings** → **Actions** → **General**.
3. Under **Workflow permissions**, select **"Read and write permissions"**.
4. Check **"Allow GitHub Actions to create and approve pull requests"**.
5. Click **Save**.

### 2. Add the Single `PROD_ENV` Secret
1. Go to **Settings** → **Secrets and variables** → **Actions**.
2. Click the green button **"New repository secret"**.
3. Set **Name**: `PROD_ENV`
4. Set **Secret**: Copy and paste the entire contents of your root [`.env`](file:///c:/Users/Adnan/ZProject/adnan/govia/.env) file.
5. Click **Add secret**.

*(That's it! Any time you want to update any server password, database password, or API key in the future, you simply edit this one `PROD_ENV` secret in GitHub).*

### 3. (Optional) Custom Domain DNS
If you own a domain (e.g. `yourdomain.com`):
- Point `api.yourdomain.com` (A record) to `172.252.13.197`
- Point `admin.yourdomain.com` (A record) to `172.252.13.197`
- Add `DOMAIN_NAME=yourdomain.com` in your `.env` (under `server con`).
*(If you do not have a domain yet, the entire stack works immediately using the server IP `http://172.252.13.197:8777` and `http://172.252.13.197:9777`).*

---

## 🛠 Bite-Sized Implementation Tasks

### Task 1: API Healthcheck Route & Docker Healthcheck
**Problem:** The API container currently reports `unhealthy` on the production server because `require('http').get()` times out after 5 seconds without consuming the response stream. Blue/Green deployments require accurate health checks to validate new containers before switching traffic.

**Files:**
- Modify: `apps/api/src/app.ts`
- Modify: `docker-compose.prod.yml`
- Modify: `apps/api/Dockerfile`

**Steps:**
1. In `apps/api/src/app.ts`, add lightweight `/health` route returning `{ status: 'ok', uptime: process.uptime(), timestamp: new Date().toISOString() }`.
2. Update `docker-compose.prod.yml` API healthcheck to test `/health` with Node native `fetch()`:
   ```yaml
   healthcheck:
     test: ["CMD", "node", "-e", "fetch('http://127.0.0.1:5000/health').then(r=>{if(!r.ok)process.exit(1)}).catch(()=>process.exit(1))"]
     interval: 10s
     timeout: 5s
     retries: 5
     start_period: 15s
   ```
3. Update `docker-compose.prod.yml` to inject `env_file: .env` across all services.
4. Verify locally with `npm run typecheck` and `npm run lint`.

---

### Task 2: Server Self-Bootstrap & Automated Daily Backups
**Problem:** The server needs automated 2GB swap memory allocation to prevent OOM, Nginx reverse proxy configuration, and automated daily database backups with 7-day retention.

**Files:**
- Create: `scripts/server/bootstrap.sh`
- Create: `scripts/server/backup-mongo.sh`
- Create: `scripts/server/nginx-govia.conf`

**Steps:**
1. **Swapfile Setup (`scripts/server/bootstrap.sh`):**
   - Check if swap exists; if swap < 2GB, allocate 2GB swapfile at `/swapfile`, set `chmod 600`, run `mkswap` and `swapon`, persist in `/etc/fstab`.
   - Install `nginx` and `certbot` if missing.
   - Configure UFW firewall to allow ports 22, 80, 443, 8777, 8778, 9777, 9778.
2. **Automated MongoDB Backup Script (`scripts/server/backup-mongo.sh`):**
   - Target directory: `/adnan/govia/backups/mongodb`.
   - Dump database from container `adnan-govia-mongo` using `mongodump --gzip --archive=...`.
   - Prune backups older than 7 days (`find ... -mtime +7 -delete`).
   - Register cron job in `crontab` to run daily at 02:00 AM UTC (`0 2 * * *`).
3. **Nginx Reverse Proxy (`scripts/server/nginx-govia.conf`):**
   - Configure upstream `govia_api_upstream` and `govia_admin_upstream`.
   - Route HTTP traffic, WebSocket connections (`Upgrade` and `Connection` headers), client body size limit `50M`.

---

### Task 3: Zero-Downtime Blue/Green Deployment Engine
**Problem:** Prevent dropped calls and WebSocket disconnections by swapping active containers only after the new version is verified 100% healthy.

**Files:**
- Create: `docker-compose.bluegreen.yml`
- Create: `scripts/server/deploy-bluegreen.sh`

**Steps:**
1. **Port Topology:**
   - **Blue:** API `:9777`, Admin `:8777`
   - **Green:** API `:9778`, Admin `:8778`
2. **Deploy Engine (`scripts/server/deploy-bluegreen.sh`):**
   - Check currently active color.
   - Target standby color (e.g. if Blue is active, target Green).
   - Pull latest images from GHCR.
   - Spin up standby containers (`docker compose -f docker-compose.bluegreen.yml --profile <color> up -d`).
   - Run healthcheck polling loop: query container health status every 3 seconds up to 90 seconds.
   - If healthy: update Nginx upstream config to point to the new color and execute `nginx -s reload` (zero dropped connections).
   - Stop and remove the previous color's containers.
   - Prune unused Docker images (`docker image prune -f`).
   - If healthcheck fails: do NOT switch Nginx; stop the failing standby containers, report error, and exit 1 (instant zero-impact rollback).

---

### Task 4: Add Automated Flutter Release APK Build to CI/CD
**Problem:** Building Flutter APKs locally takes significant CPU and time. Automated building in GitHub Actions ensures every push generates a verified, downloadable APK for Android testing.

**Files:**
- Modify: `.github/workflows/deploy.yml`

**Steps:**
1. Add `build-flutter` job running on `ubuntu-latest`.
2. Extract the `app` block from `.env` to `gsabino365/.env`.
3. Configure Java 17 and Flutter stable via `subosito/flutter-action@v2`.
4. Run `flutter pub get` and `flutter build apk --release`.
5. Upload the resulting APK (`gsabino365/build/app/outputs/flutter-apk/app-release.apk`) using `actions/upload-artifact@v4` with a 30-day retention period.

---

### Task 5: 5-Stage GitHub Actions Workflow with Single `PROD_ENV` Secret
**Problem:** Consolidate the entire workflow into a unified, autonomous pipeline driven by the single `PROD_ENV` variable.

**Files:**
- Modify: `.github/workflows/deploy.yml`

**Pipeline Stages:**
1. **Stage 1 (`quality-gate`):** Monorepo linting (`npm run lint`) and TypeScript checks (`npm run typecheck`).
2. **Stage 2 (`parallel-builds`):**
   - `build-api`: Docker Buildx -> GHCR
   - `build-admin`: Reads frontend env from `PROD_ENV` -> Docker Buildx -> GHCR
   - `build-flutter`: Flutter Android release APK -> GitHub Artifacts
3. **Stage 3 (`bootstrap-server`):** SSH to server -> run idempotent bootstrap (swap, Nginx, crontab backup).
4. **Stage 4 (`deploy-bluegreen`):** Uploads `.env` to `/adnan/govia/.env` -> executes zero-downtime Blue/Green swap with automated health verification.
5. **Stage 5 (`ssl-setup`):** If `DOMAIN_NAME` is set in `.env`, verify DNS and run Certbot for HTTPS with auto-renewal.

---

### Task 6: End-to-End Verification & Rollout
**Steps:**
1. Test bootstrap and healthcheck against the server.
2. Commit and push all changes to `main`.
3. Monitor GitHub Actions workflow run live.
4. Verify:
   - Quality gate succeeds.
   - API and Admin images build and push to GHCR.
   - Flutter APK builds and appears in Actions Artifacts.
   - Server performs Blue/Green deployment without downtime.
   - API `/health` reports `healthy`.
   - Admin and API are live on `172.252.13.197`.
