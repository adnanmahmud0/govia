# ==============================================================================
# Direct Local to Server Push Script (PowerShell for Windows)
# ==============================================================================
param (
    [string]$ServerHost = "172.252.13.197",
    [string]$ServerUser = "root",
    [string]$RemoteDir = "/adnan/govia"
)

$ErrorActionPreference = "Stop"

Write-Host "======================================================" -ForegroundColor Cyan
Write-Host "🚀 GOVIA: Direct Local-to-Server Code Push" -ForegroundColor Cyan
Write-Host "Target: $ServerUser@$ServerHost:$RemoteDir" -ForegroundColor Cyan
Write-Host "======================================================" -ForegroundColor Cyan

# 1. Create a clean deployment bundle tar.gz (excluding node_modules, .git, .next, dist)
$tempArchive = "$env:TEMP\govia_deploy.tar.gz"
if (Test-Path $tempArchive) { Remove-Item $tempArchive -Force }

Write-Host "`n📦 Packing repository files (excluding heavy cache/modules)..." -ForegroundColor Yellow

# Use tar to archive only source files
tar -czf $tempArchive `
    --exclude="node_modules" `
    --exclude="**/node_modules" `
    --exclude=".next" `
    --exclude="**/.next" `
    --exclude=".turbo" `
    --exclude="**/.turbo" `
    --exclude="dist" `
    --exclude="apps/api/dist" `
    --exclude=".git" `
    --exclude="gsabino365" `
    --exclude="Govia-admin-dashboard" `
    --exclude="fullstack-turborepo-starter-kit" `
    --exclude="doc" `
    --exclude="postman" `
    --exclude="uploads" `
    --exclude="*.log" `
    apps packages scripts package.json package-lock.json turbo.json docker-compose.prod.yml docker-compose.yml .dockerignore .env.example

Write-Host "✅ Bundle packaged successfully ($((Get-Item $tempArchive).Length / 1MB | Out-String | ForEach-Object { $_.Trim() }) MB)" -ForegroundColor Green

# 2. Ensure remote directory exists
Write-Host "`n📁 Ensuring remote directory exists at $RemoteDir..." -ForegroundColor Yellow
ssh "$ServerUser@$ServerHost" "mkdir -p $RemoteDir/scripts $RemoteDir/uploads $RemoteDir/backups"

# 3. SCP upload the bundle archive
Write-Host "`n📤 Uploading bundle directly to server..." -ForegroundColor Yellow
scp $tempArchive "${ServerUser}@${ServerHost}:${RemoteDir}/govia_deploy.tar.gz"

# 4. Extract and Deploy on the Server
Write-Host "`n🐳 Extracting and launching Docker on the server..." -ForegroundColor Yellow
ssh "$ServerUser@$ServerHost" @"
cd $RemoteDir
tar -xzf govia_deploy.tar.gz
rm -f govia_deploy.tar.gz
chmod +x scripts/*.sh

# Ensure .env exists
if [ ! -f .env ]; then
  cp .env.example .env
fi

# Run Docker Compose
docker compose -f docker-compose.prod.yml up -d --build --remove-orphans
sleep 10
docker compose -f docker-compose.prod.yml ps
"@

# Clean local temp archive
Remove-Item $tempArchive -Force -ErrorAction SilentlyContinue

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "🎉 Direct Deployment Finished on $ServerHost!" -ForegroundColor Green
Write-Host "API Endpoint:   http://${ServerHost}:9777/api/v1/docs" -ForegroundColor Green
Write-Host "Admin Endpoint: http://${ServerHost}:8777" -ForegroundColor Green
Write-Host "======================================================" -ForegroundColor Green
