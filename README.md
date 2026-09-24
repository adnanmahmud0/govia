# 🛡️ Govia Monorepo

> **Production-grade multi-platform system featuring Next.js 15 Admin Portal, Node.js/Express Backend, and Flutter Mobile Application with zero-downtime Blue/Green CI/CD deployment.**

---

## 📁 Repository Structure

```text
govia/
├── .github/
│   └── workflows/
│       └── deploy.yml              # 🚀 5-Stage Zero-Downtime Blue/Green CI/CD Pipeline
├── apps/
│   ├── admin/                      # 🖥️ Next.js 15 Standalone Admin Portal (Host Port: 8777)
│   │   ├── public/                 # Static assets & dashboard icons
│   │   ├── src/                    # App Router & Dashboard views
│   │   ├── Dockerfile              # Multi-stage standalone production container
│   │   ├── next.config.ts          # Standalone bundle config
│   │   └── package.json            # @repo/admin
│   │
│   ├── backend/                    # ⚙️ Express & Socket.IO Real-Time API (Host Port: 9777)
│   │   ├── ai-data/                # Legal knowledge base & RAG documents
│   │   ├── src/                    # Controllers, services, models, middlewares
│   │   ├── uploads/                # User media & document storage
│   │   ├── winston/                # Automated rotating daily log files
│   │   ├── Dockerfile              # Multi-stage Node 20 production container
│   │   └── package.json            # @repo/backend
│   │
│   └── mobile/                     # 📱 Flutter Cross-Platform Mobile App (iOS & Android)
│       ├── android/                # Native Android Gradle configuration
│       ├── ios/                    # Native iOS Xcode workspace & Podfile
│       ├── assets/                 # Brand assets, vectors, and bundled fonts
│       ├── lib/                    # GetX modular architecture & in-app video player
│       │   ├── config/             # Routes, constants, API base URLs
│       │   ├── core/               # Widgets, services (LiveKit, FCM, Dio), helpers
│       │   └── module/             # Feature domain views & controllers
│       │       ├── citizen/        # Citizen dashboard, vault, SOS, booking
│       │       ├── attorney/       # Attorney portal & consultation hub
│       │       ├── doctor/         # Medical provider workflows
│       │       ├── police/         # Law enforcement directory & verification
│       │       └── shared/         # Authentication, chat, video calling, settings
│       ├── pubspec.yaml            # Flutter dependencies & assets registry
│       └── .env                    # Mobile client runtime environment
│
├── packages/                       # 📦 Shared Monorepo Tooling
│   ├── eslint-config/              # Shared ESLint configuration
│   ├── tsconfig/                   # Shared TypeScript compiler options
│   ├── types/                      # Universal TypeScript domain interfaces
│   ├── ui/                         # Shared UI tokens & primitive components
│   └── validators/                 # Shared Zod validation schemas
│
├── scripts/                        # 🛠️ Server & Deployment Utilities
│   └── server/
│       ├── bootstrap.sh            # Idempotent VPS bootstrap (2GB swap, Nginx, UFW, Cron)
│       ├── backup-mongo.sh         # Daily automated MongoDB backups (7-day retention)
│       ├── deploy-bluegreen.sh     # Zero-downtime container swapping engine
│       └── nginx-govia.conf        # Production Nginx reverse proxy configuration
│
├── docker-compose.prod.yml         # Standard production multi-container manifest
├── docker-compose.bluegreen.yml    # Blue/Green dual-profile deployment manifest
├── .env.example                    # 4-section environment configuration template
├── .env                            # Active environment configuration (git-ignored)
├── package.json                    # Monorepo root workspace manifest
└── turbo.json                      # Turborepo task pipeline (build, lint, typecheck)
```

---

## 🌐 Workspaces at a Glance

| Component | Technology | Internal Port | Host Port / Route | Description |
| :--- | :--- | :--- | :--- | :--- |
| **`apps/admin`** | Next.js 15, Tailwind, Lucide | `3000` | `:8777` (or `/`) | Web Admin & Telemetry Dashboard |
| **`apps/backend`** | Express, Node 20, Socket.IO, Mongoose | `5000` | `:9777` (or `/api`) | RESTful API, WebSockets & LiveKit Egress |
| **`apps/mobile`** | Flutter 3.x, GetX, Dio, Chewie | Client | iOS & Android APK | Cross-platform mobile client |
| **`MongoDB`** | Mongo 7.0 (Official Docker Image) | `27017` | Isolated bridge | Database (never exposed publicly) |
| **`Nginx`** | Nginx Reverse Proxy | `80 / 443` | Host Reverse Proxy | Zero-downtime Blue/Green traffic switcher |

---

## 🚀 Quick Start (Local Development)

### 1. Install Dependencies
```bash
npm install
```

### 2. Configure Environment
Copy `.env.example` to `.env` and fill in your local or remote database keys:
```bash
cp .env.example .env
```

### 3. Run Development Servers
```bash
# Run both Backend & Admin concurrently:
npm run dev

# Or run individually:
npm run dev:backend   # Starts Express API at http://localhost:5000
npm run dev:admin     # Starts Next.js Admin at http://localhost:3000
```

### 4. Run Mobile App
```bash
cd apps/mobile
flutter pub get
flutter run
```

---

## 🛡️ Quality Assurance & Checks

```bash
npm run lint         # Runs ESLint across all monorepo packages
npm run typecheck    # Validates TypeScript compilation across all workspaces
npm run build        # Compiles all packages for production
```

---

## 🚢 Production Deployment

Govia uses a **Zero-Manual-SSH Blue/Green CI/CD Pipeline** running in GitHub Actions:
- **Single Secret (`PROD_ENV`):** All configurations across backend, frontend, server connection, and mobile app originate from one unified secret.
- **Zero Downtime:** Standby containers boot and pass rigorous health checks before Nginx smoothly switches upstream traffic without dropping active calls or WebSocket streams.
- **Automated Backups:** Daily MongoDB database backups are compressed and retained for 7 days via automated server cron.
- **Cloud-Built APKs:** Every push automatically compiles a fresh Android release APK attached as a downloadable GitHub Actions artifact.
