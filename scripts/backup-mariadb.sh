#!/bin/bash
# Security ERP - MariaDB Backup Script
# Usage: ./backup-mariadb.sh [daily|weekly|monthly]

BACKUP_TYPE=${1:-daily}
BACKUP_DIR="/home/joker/RIAD CRM/backups/automated"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/mariadb_${BACKUP_TYPE}_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=30
CONTAINER_NAME="${MARIADB_CONTAINER:-riadcrm-mariadb-1}"

# Load .env if MYSQL_ROOT_PASSWORD is not set (e.g. when run from cron)
if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
    ENV_FILE="/home/joker/RIAD CRM/.env"
    if [ -f "$ENV_FILE" ]; then
        set -a
        . "$ENV_FILE"
        set +a
    fi
fi

DB_PASSWORD="${MYSQL_ROOT_PASSWORD:-}"

echo "[$(date)] Starting ${BACKUP_TYPE} backup..."
docker exec "$CONTAINER_NAME" mysqldump -uroot -p"${DB_PASSWORD}" --single-transaction --routines --triggers --databases _73c82ec6d255ebe3 | gzip > "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
    echo "[$(date)] Backup completed: $BACKUP_FILE ($SIZE)"
else
    echo "[$(date)] ERROR: Backup failed!"
    exit 1
fi

# Cleanup old backups
echo "[$(date)] Cleaning backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -name "mariadb_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "[$(date)] Done."
