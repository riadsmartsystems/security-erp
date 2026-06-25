#!/bin/bash
# Security ERP - MariaDB Backup Script
# Usage: ./backup-mariadb.sh [daily|weekly|monthly]

BACKUP_TYPE=${1:-daily}
BACKUP_DIR="/home/joker/RIAD CRM/backups/automated"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="${BACKUP_DIR}/mariadb_${BACKUP_TYPE}_${TIMESTAMP}.sql.gz"
RETENTION_DAYS=30
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -m1 'mariadb' || echo "mariadb")

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
docker exec "$CONTAINER_NAME" mysqldump -uroot -p"${DB_PASSWORD}" --single-transaction --routines --triggers --databases _73c82ec6d255ebe3 2>/tmp/backup_stderr | gzip > "$BACKUP_FILE"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo "[$(date)] ERROR: mysqldump failed!"
    cat /tmp/backup_stderr 2>/dev/null
    rm -f "$BACKUP_FILE"
    exit 1
fi

if [ ! -s "$BACKUP_FILE" ]; then
    echo "[$(date)] ERROR: Backup file is empty!"
    exit 1
fi

FILE_SIZE=$(stat -c%s "$BACKUP_FILE" 2>/dev/null || stat -f%z "$BACKUP_FILE" 2>/dev/null)
if [ "$FILE_SIZE" -lt 10000 ]; then
    echo "[$(date)] WARNING: Backup suspiciously small ($FILE_SIZE bytes)"
fi

SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "[$(date)] Backup completed: $BACKUP_FILE ($SIZE)"

# Cleanup old backups
echo "[$(date)] Cleaning backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -name "mariadb_*.sql.gz" -mtime +${RETENTION_DAYS} -delete

echo "[$(date)] Done."
