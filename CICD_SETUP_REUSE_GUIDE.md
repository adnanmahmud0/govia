# 🚀 Reusable Production CI/CD & Docker Deployment Guide

This guide provides a copy-paste template and step-by-step instructions to replicate the automated **GitHub Actions + GHCR (GitHub Container Registry) + Docker Compose** deployment workflow for any new project (such as `spotify_concept_backend`).

---

## 📑 Table of Contents
1. [Workflow Architecture](#1-workflow-architecture)
2. [Checklist for Your New Project](#2-checklist-for-your-new-project)
3. [The 4 Core Files to Copy](#3-the-4-core-files-to-copy)
   - [File 1: `.github/workflows/deploy.yml`](#file-1-githubworkflowsdeployyml)
   - [File 2: `docker-compose.prod.yml`](#file-2-docker-composeprodyml)
   - [File 3: `Dockerfile`](#file-3-dockerfile)
   - [File 4: `.dockerignore`](#file-4-dockerignore)
4. [GitHub Repository Secrets Setup](#4-github-repository-secrets-setup)
5. [Server Folder & Port Allocation Rule](#5-server-folder--port-allocation-rule)
6. [First Deployment & Verification](#6-first-deployment--verification)
7. [Troubleshooting Common Issues](#7-troubleshooting-common-issues)

---

## 1. Workflow Architecture

```
                                  [ GitHub Repository ]
                                            │
                                            ▼ (git push origin main)
                       ┌────────────────────────────────────────┐
                       │      GitHub Actions Runner (Ubuntu)    │
                       ├────────────────────────────────────────┤
                       │ 1. Checks out code                     │
                       │ 2. Builds multi-stage Docker image     │
                       │ 3. Pushes image to GHCR (ghcr.io)      │
                       │ 4. Generates production .env           │
                       │ 5. SSH / SCP into remote VPS           │
                       └───────────────────┬────────────────────┘
                                           │
                        (SSH connection via port 22)
                                           │
                                           ▼
                      ┌──────────────────────────────────────────┐
                      │            Remote VPS Server             │
                      ├──────────────────────────────────────────┤
                      │ 1. Folder: /adnan/<your-new-project>     │
                      │ 2. Copies .env & docker-compose.prod.yml │
                      │ 3. Logs in to ghcr.io                    │
                      │ 4. docker compose pull                   │
                      │ 5. docker compose up -d                  │
                      │ 6. Auto health-check & status log        │
                      └──────────────────────────────────────────┘
```

### Why this architecture is superior:
- **Zero Heavy Building on VPS**: Building TypeScript and Docker images happens on GitHub's free runners, so your VPS CPU and RAM never spike or freeze.
- **Instant Rollouts**: The server only downloads pre-built layers and starts the container in seconds.
- **Clean Isolation**: Each project lives in its own directory (e.g. `/adnan/govia`, `/adnan/spotify-backend`) with its own isolated Docker network and dedicated host ports.

---

## 2. Checklist for Your New Project

When applying this to another repository (e.g. `spotify_concept_backend`), ensure you:
- [ ] Create `.github/workflows/deploy.yml`
- [ ] Create `docker-compose.prod.yml`
- [ ] Create `Dockerfile` (or adapt existing one)
- [ ] Create `.dockerignore`
- [ ] Pick a **unique server directory** (e.g. `/adnan/spotify-backend`)
- [ ] Pick a **unique public host port** (e.g. `9888` — ensure it doesn't conflict with Govia's `9777` or `8777`)
- [ ] Add the required Secrets to GitHub repository (**Settings > Secrets and variables > Actions**)
- [ ] Enable **Read and write permissions** for `GITHUB_TOKEN` under **Settings > Actions > General > Workflow permissions**

---

## 3. The 4 Core Files to Copy

### File 1: `.github/workflows/deploy.yml`
Create this file at `.github/workflows/deploy.yml` in your new project.

> ✏️ **Edit these placeholders**:
> - Replace `spotify-backend` with your project name.
> - Replace `/adnan/spotify-backend` with your chosen server folder.
> - Replace port `9888` with your project's allocated port.
> - Customize the `.env` generation section with your project's variables.

```yaml
name: Build Docker Image & Deploy to Server

on:
  push:
    branches:
      - main
  workflow_dispatch:

concurrency:
  group: production-deployment
  cancel-in-progress: false

permissions:
  contents: read
  packages: write

jobs:
  # ============================================================================
  # Stage 1: Build Docker Image in GitHub and Push to GitHub Container Registry
  # ============================================================================
  build-and-push:
    name: Build & Push Docker Image
    runs-on: ubuntu-latest
    timeout-minutes: 20

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to GitHub Container Registry (GHCR)
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}

      - name: Build and push API Image
        uses: docker/build-push-action@v5
        with:
          context: .
          file: Dockerfile
          push: true
          tags: |
            ghcr.io/${{ github.repository_owner }}/spotify-backend:latest
            ghcr.io/${{ github.repository_owner }}/spotify-backend:${{ github.sha }}
          cache-from: type=gha
          cache-to: type=gha,mode=max

  # ============================================================================
  # Stage 2: Deploy to Remote Server via SSH
  # ============================================================================
  deploy:
    name: Deploy to Server
    needs: build-and-push
    runs-on: ubuntu-latest
    timeout-minutes: 15

    steps:
      - name: Checkout Code
        uses: actions/checkout@v4

      - name: Generate Production Configuration
        env:
          PORT: 5000
          DATABASE_URL: ${{ secrets.DATABASE_URL }}
          REDIS_URL: ${{ secrets.REDIS_URL }}
          JWT_SECRET: ${{ secrets.JWT_SECRET }}
        run: |
          mkdir -p deploy-payload

          cat << EOF > deploy-payload/.env
          NODE_ENV=production
          PORT=5000
          DATABASE_URL=${DATABASE_URL}
          REDIS_URL=${REDIS_URL}
          JWT_SECRET=${JWT_SECRET}
          EOF

          cp docker-compose.prod.yml deploy-payload/

      - name: Deploy to Server via SSH
        env:
          SERVER_HOST: ${{ secrets.SERVER_HOST || '172.252.13.197' }}
          SERVER_USER: ${{ secrets.SERVER_USER || 'root' }}
          SERVER_PASS: ${{ secrets.SERVER_PASSWORD }}
          SERVER_PORT: ${{ secrets.SERVER_SSH_PORT || '22' }}
          GH_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          GH_ACTOR: ${{ github.actor }}
          DEPLOY_PATH: "/adnan/spotify-backend"
          HOST_PORT: "9888"
        run: |
          set -e
          sudo apt-get update -qq && sudo apt-get install -y -qq sshpass

          TARGET_HOST="${SERVER_HOST}"
          TARGET_USER="${SERVER_USER}"
          TARGET_PORT="${SERVER_PORT}"
          export SSHPASS="$SERVER_PASS"

          if [ -z "$SSHPASS" ]; then
            echo "❌ ERROR: SERVER_PASSWORD secret is missing in GitHub repository secrets!"
            exit 1
          fi

          echo "🚀 Testing SSH connection to ${TARGET_USER}@${TARGET_HOST}:${TARGET_PORT}..."
          sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$TARGET_PORT" "${TARGET_USER}@${TARGET_HOST}" "echo '✅ SSH connection successful!'"

          # 1. Create target folder on VPS
          echo "📁 Creating remote folder ${DEPLOY_PATH}..."
          sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$TARGET_PORT" "${TARGET_USER}@${TARGET_HOST}" "
            mkdir -p ${DEPLOY_PATH}
            if ! command -v docker &>/dev/null; then
              echo '📦 Installing Docker...'
              curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
              sh /tmp/get-docker.sh
            fi
          "

          # 2. Upload .env and docker-compose.prod.yml
          echo "📤 Uploading deployment configs to ${DEPLOY_PATH}..."
          sshpass -e scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -P "$TARGET_PORT" deploy-payload/.env deploy-payload/docker-compose.prod.yml "${TARGET_USER}@${TARGET_HOST}:${DEPLOY_PATH}/"

          # 3. Pull latest image and launch containers
          echo "🐳 Launching containers..."
          sshpass -e ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$TARGET_PORT" "${TARGET_USER}@${TARGET_HOST}" "
            set -e
            cd ${DEPLOY_PATH}
            chmod 600 .env

            # Open firewall port if ufw is active
            if command -v ufw &>/dev/null; then
              ufw allow ${HOST_PORT}/tcp || true
              ufw reload || true
            fi

            echo '🔐 Authenticating with GitHub Container Registry...'
            echo \"$GH_TOKEN\" | docker login ghcr.io -u \"$GH_ACTOR\" --password-stdin

            echo '📥 Pulling latest Docker image...'
            docker compose -f docker-compose.prod.yml pull

            echo '🚀 Starting containers...'
            docker compose -f docker-compose.prod.yml up -d --remove-orphans
            docker image prune -f

            echo '⏳ Waiting for service to start...'
            sleep 10

            echo '📊 Container status:'
            docker compose -f docker-compose.prod.yml ps

            echo '📋 Container logs:'
            docker compose -f docker-compose.prod.yml logs --tail 25 || true
          "

          echo "🎉 Deployment successfully completed!"
          echo "👉 Accessible at: http://${TARGET_HOST}:${HOST_PORT}"
```

---

### File 2: `docker-compose.prod.yml`
Create this file at the root of your new project:

```yaml
name: spotify-backend-production

services:
  app:
    # ⚠️ Replace <github-username> and <image-name> with your values
    image: ghcr.io/adnanmahmud0/spotify-backend:latest
    container_name: adnan-spotify-api
    restart: always
    ports:
      # Host Port : Container Port
      - "9888:5000"
    env_file:
      - .env
    environment:
      - NODE_ENV=production
      - PORT=5000
    networks:
      - spotify_network

  # (Optional: Add Redis or DB container if needed locally inside the stack)
  # redis:
  #   image: redis:7-alpine
  #   container_name: adnan-spotify-redis
  #   restart: always
  #   networks:
  #     - spotify_network

networks:
  spotify_network:
    driver: bridge
```

---

### File 3: `Dockerfile`
A high-performance, multi-stage production Dockerfile for TypeScript / Node.js projects:

```dockerfile
# Stage 1: Install dependencies
FROM node:22-alpine AS deps
WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm ci

# Stage 2: Compile TypeScript to JavaScript
FROM node:22-alpine AS builder
WORKDIR /app

COPY package.json package-lock.json* ./
COPY --from=deps /app/node_modules ./node_modules
COPY tsconfig*.json ./
COPY src ./src

RUN npm run build

# Stage 3: Minimal production runtime
FROM node:22-alpine AS runner
WORKDIR /app

ENV NODE_ENV=production

COPY package.json package-lock.json* ./
RUN npm ci --omit=dev

COPY --from=builder /app/dist ./dist

EXPOSE 5000

# ⚠️ Verify that your compiled entry file matches (e.g. dist/index.js or dist/server.js)
CMD ["node", "dist/index.js"]
```

---

### File 4: `.dockerignore`
Place this `.dockerignore` at the root of your project to keep builds fast and prevent secret leaks:

```
node_modules
npm-debug.log*
yarn-debug.log*
.pnpm-debug.log*

dist
build
out
.turbo

.git
.gitignore
.github
.vscode
.idea

.env
.env*.local
!.env.example

uploads
logs
*.log
.DS_Store
```

---

## 4. GitHub Repository Secrets Setup

In your GitHub repository, go to:
**Settings ➔ Secrets and variables ➔ Actions ➔ New repository secret**

Add the following secrets:

| Secret Name | Value | Description |
| :--- | :--- | :--- |
| `SERVER_HOST` | `172.252.13.197` | Your VPS IP address |
| `SERVER_USER` | `root` | SSH user |
| `SERVER_PASSWORD`| `YourVPSPassword` | Root SSH password |
| `SERVER_SSH_PORT`| `22` | SSH Port (default: 22) |
| `DATABASE_URL` | `mongodb://...` or `postgres://...` | Production database connection string |
| `JWT_SECRET` | `your-secure-64-character-secret` | App secrets |
| *(Any other app secrets)* | *value* | Pass any `.env` secrets required by your backend |

### ⚠️ Critical GitHub Permissions Step:
GitHub Actions needs permission to write images to GitHub Container Registry (`ghcr.io`):
1. Go to your repo on GitHub ➔ **Settings** ➔ **Actions** ➔ **General**.
2. Scroll to **Workflow permissions**.
3. Select **Read and write permissions**.
4. Click **Save**.

---

## 5. Server Folder & Port Allocation Rule

To prevent conflicting with existing projects on the VPS, maintain a clean separation table:

| Project | Server Folder | Host Port(s) | Container Name | Docker Network |
| :--- | :--- | :--- | :--- | :--- |
| **Govia** | `/adnan/govia` | `9777` (API), `8777` (Admin) | `adnan-govia-api`, `adnan-govia-admin` | `govia_network` |
| **Spotify Backend** | `/adnan/spotify-backend` | `9888` | `adnan-spotify-api` | `spotify_network` |
| **Project 3** | `/adnan/project-3` | `9999` | `adnan-p3-api` | `p3_network` |

---

## 6. First Deployment & Verification

Once you commit and push to the `main` branch:

1. Go to your GitHub repository ➔ **Actions** tab.
2. Click on the active workflow **"Build Docker Image & Deploy to Server"**.
3. Inspect the logs for both **Build & Push Docker Image** and **Deploy to Server**.
4. When finished, log in to your server to verify:

```bash
ssh root@172.252.13.197

# 1. Navigate to project folder
cd /adnan/spotify-backend

# 2. Check running container
docker compose -f docker-compose.prod.yml ps

# 3. View live logs
docker compose -f docker-compose.prod.yml logs -f app

# 4. Test response locally
curl -I http://127.0.0.1:9888/
```

---

## 7. Troubleshooting Common Issues

### ❌ `403 Forbidden` / `unauthorized: unauthenticated` when pushing or pulling image:
- Make sure you enabled **Read and write permissions** in GitHub repository **Settings > Actions > General > Workflow permissions**.
- If pulling on server fails, ensure the GitHub Container Registry package visibility is set to **Public** or the server runs `docker login ghcr.io` with `$GH_TOKEN`.

### ❌ `port is already allocated`:
- Another container is already using that port.
- Change the host port in `docker-compose.prod.yml` (e.g. from `9777` to `9888`).

### ❌ `Cannot find module '/app/dist/index.js'`:
- Check your `package.json` build script.
- If your build generates `dist/server.js` or `dist/src/index.js`, update the last line of `Dockerfile` accordingly:
  ```dockerfile
  CMD ["node", "dist/server.js"]
  ```
