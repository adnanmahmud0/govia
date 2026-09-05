#!/usr/bin/env bash
# ==============================================================================
# Govia Automated MongoDB Backup Utility
# ==============================================================================
set -euo pipefail

BACKUP_DIR="${BACKUP_DIR:-./backups/mongo}"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/govia_backup_${TIMESTAMP}.gz"
RETENTION_DAYS=14

mkdir -p "$BACKUP_DIR"

if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs -d '\n' 2>/dev/null || grep -v '^#' .env | xargs)
fi

DB_USER="${MONGO_INITDB_ROOT_USERNAME:-goviaAdmin}"
DB_PASS="${MONGO_INITDB_ROOT_PASSWORD:-GoviaMongoSecurePass2026!}"
DB_NAME="${MONGO_INITDB_DATABASE:-govia-db}"
CONTAINER_NAME="adnan-govia-mongo"

echo "💾 Starting MongoDB backup for database '${DB_NAME}'..."

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
echo "✅ Backup successfully created at: ${BACKUP_FILE} (${FILE_SIZE})"

# Remove backups older than retention days
echo "🧹 Removing backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -type f -name "govia_backup_*.gz" -mtime +${RETENTION_DAYS} -exec rm -f {} \;
echo "🎉 Backup operation finished."
