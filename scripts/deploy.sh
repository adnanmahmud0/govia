#!/usr/bin/env bash
# ==============================================================================
# Govia One-Command Production Deployment Script
# ==============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}           🚀 GOVIA PRODUCTION DEPLOYMENT              ${NC}"
echo -e "${CYAN}======================================================${NC}"

# 1. Check if .env file exists
if [ ! -f .env ]; then
  echo -e "${RED}❌ Error: .env file not found!${NC}"
  if [ -f .env.example ]; then
    echo -e "${YELLOW}👉 Copying from .env.example... Please edit .env with real credentials.${NC}"
    cp .env.example .env
  else
    exit 1
  fi
fi

# 2. Source environment variables
export $(grep -v '^#' .env | xargs -d '\n' 2>/dev/null || grep -v '^#' .env | xargs)

# 3. Pull / Build Docker images
echo -e "${YELLOW}🐳 Building and starting production containers...${NC}"
docker compose -f docker-compose.prod.yml up -d --build --remove-orphans

# 4. Wait for services to stabilize
echo -e "${YELLOW}⏳ Waiting 15 seconds for MongoDB and API initialization...${NC}"
sleep 15

# 5. Display status
echo -e "${GREEN}📊 Container Status:${NC}"
docker compose -f docker-compose.prod.yml ps

# 6. Check endpoints
API_PORT="${HOST_API_PORT:-9777}"
ADMIN_PORT="${HOST_ADMIN_PORT:-8777}"

echo -e "\n${CYAN}🔍 Verifying API Health...${NC}"
if curl -s -f "http://127.0.0.1:${API_PORT}/" > /dev/null; then
  echo -e "${GREEN}✅ API is UP and running at http://localhost:${API_PORT}${NC}"
  echo -e "${GREEN}📖 Swagger UI: http://localhost:${API_PORT}/api/v1/docs${NC}"
else
  echo -e "${RED}⚠️ API healthcheck failed! Check logs: docker compose -f docker-compose.prod.yml logs adnan-govia-api${NC}"
fi

echo -e "\n${CYAN}🔍 Verifying Admin Dashboard...${NC}"
if curl -s -f "http://127.0.0.1:${ADMIN_PORT}/" > /dev/null; then
  echo -e "${GREEN}✅ Admin Dashboard is UP and running at http://localhost:${ADMIN_PORT}${NC}"
else
  echo -e "${YELLOW}ℹ️ Admin dashboard is starting up on http://localhost:${ADMIN_PORT}${NC}"
fi

# 7. Clean up unused images
echo -e "\n${YELLOW}🧹 Cleaning up dangling build images...${NC}"
docker image prune -f

echo -e "\n${GREEN}======================================================${NC}"
echo -e "${GREEN}     🎉 Deployment completed successfully!           ${NC}"
echo -e "${GREEN}======================================================${NC}"
