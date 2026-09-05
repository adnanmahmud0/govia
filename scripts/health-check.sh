#!/usr/bin/env bash
# ==============================================================================
# Govia Production Health Diagnostic Script
# ==============================================================================
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}          🔍 GOVIA SYSTEM HEALTH DIAGNOSTIC           ${NC}"
echo -e "${CYAN}======================================================${NC}"

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs -d '\n' 2>/dev/null || grep -v '^#' .env | xargs)
fi

API_PORT="${HOST_API_PORT:-9777}"
ADMIN_PORT="${HOST_ADMIN_PORT:-8777}"

# 1. Check Docker Containers
echo -e "\n${YELLOW}1. Checking Docker Container States:${NC}"
for c in adnan-govia-mongo adnan-govia-api adnan-govia-admin; do
  STATUS=$(docker inspect --format='{{.State.Status}}' "$c" 2>/dev/null || echo "NOT_FOUND")
  if [ "$STATUS" == "running" ]; then
    HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$c" 2>/dev/null || echo "")
    echo -e "  - Container ${CYAN}$c${NC}: ${GREEN}RUNNING${NC} (Health: ${GREEN}${HEALTH}${NC})"
  else
    echo -e "  - Container ${CYAN}$c${NC}: ${RED}${STATUS}${NC}"
  fi
done

# 2. Check MongoDB Connectivity
echo -e "\n${YELLOW}2. Checking MongoDB Internal Connectivity:${NC}"
if docker exec adnan-govia-mongo mongosh --quiet --eval "db.adminCommand('ping').ok" 2>/dev/null | grep -q "1"; then
  echo -e "  - ${GREEN}MongoDB Database: OK (Responding to ping)${NC}"
else
  echo -e "  - ${RED}MongoDB Database: FAILED (Not responding)${NC}"
fi

# 3. Check Express API Endpoint
echo -e "\n${YELLOW}3. Checking Express API Service on Port ${API_PORT}:${NC}"
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${API_PORT}/" || echo "000")
if [ "$HTTP_CODE" -eq 200 ]; then
  echo -e "  - ${GREEN}API Root /: OK (HTTP ${HTTP_CODE})${NC}"
else
  echo -e "  - ${RED}API Root /: FAILED (HTTP ${HTTP_CODE})${NC}"
fi

DOCS_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${API_PORT}/api/v1/docs/" || echo "000")
if [ "$DOCS_CODE" -eq 200 ] || [ "$DOCS_CODE" -eq 301 ]; then
  echo -e "  - ${GREEN}Swagger Docs /api/v1/docs: OK (HTTP ${DOCS_CODE})${NC}"
else
  echo -e "  - ${YELLOW}Swagger Docs /api/v1/docs: (HTTP ${DOCS_CODE})${NC}"
fi

# 4. Check Admin Dashboard Endpoint
echo -e "\n${YELLOW}4. Checking Admin Dashboard on Port ${ADMIN_PORT}:${NC}"
ADMIN_CODE=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${ADMIN_PORT}/" || echo "000")
if [ "$ADMIN_CODE" -eq 200 ] || [ "$ADMIN_CODE" -eq 307 ] || [ "$ADMIN_CODE" -eq 308 ]; then
  echo -e "  - ${GREEN}Admin Dashboard: OK (HTTP ${ADMIN_CODE})${NC}"
else
  echo -e "  - ${YELLOW}Admin Dashboard: (HTTP ${ADMIN_CODE})${NC}"
fi

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}Diagnostic completed.${NC}"
