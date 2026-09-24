#!/usr/bin/env bash
# ==============================================================================
# Govia Automated Daily MongoDB Backup Utility
# ==============================================================================
set -euo pipefail

BACKUP_DIR="/adnan/govia/backups/mongodb"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/govia_backup_${TIMESTAMP}.gz"
RETENTION_DAYS=7

mkdir -p "$BACKUP_DIR"

if [ -f /adnan/govia/.env ]; then
  # Safely source .env without breaking on special characters
  set -a
  source /adnan/govia/.env 2>/dev/null || true
  set +a
fi

DB_USER="${MONGO_INITDB_ROOT_USERNAME:-goviaAdmin}"
DB_PASS="${MONGO_INITDB_ROOT_PASSWORD:-GoviaMongoSecurePass2026!}"
DB_NAME="${MONGO_INITDB_DATABASE:-govia-db}"
CONTAINER_NAME="adnan-govia-mongo"

echo "💾 [$(date)] Starting MongoDB backup for database '${DB_NAME}'..."

if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
  echo "❌ Error: Container '${CONTAINER_NAME}' is not running."
  exit 1
fi

docker exec "$CONTAINER_NAME" mongodump \
  --username "$DB_USER" \
  --password "$DB_PASS" \
  --authenticationDatabase admin \
  --db "$DB_NAME" \
  --archive --gzip > "$BACKUP_FILE"

FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "✅ Backup successfully created: ${BACKUP_FILE} (${FILE_SIZE})"

# Remove backups older than retention days
echo "🧹 Pruning backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -type f -name "govia_backup_*.gz" -mtime +${RETENTION_DAYS} -delete || true

echo "🎉 [$(date)] MongoDB backup finished successfully."
