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

# GPG encryption (if available)
GPG_RECIPIENT="backup@riad.local"
GPG_KEYRING="/home/joker/RIAD CRM/configs/backup_public.gpg"

if command -v gpg &>/dev/null && [ -f "$GPG_KEYRING" ]; then
    echo "[$(date)] Encrypting backup with GPG..."
    GPG_HOMEDIR=$(mktemp -d)
    gpg --batch --yes --trust-model always --homedir "$GPG_HOMEDIR" --import "$GPG_KEYRING" 2>/dev/null

    if gpg --batch --yes --trust-model always --homedir "$GPG_HOMEDIR" --recipient "$GPG_RECIPIENT" --encrypt "$BACKUP_FILE" 2>/dev/null; then
        rm -f "$BACKUP_FILE"
        BACKUP_FILE="${BACKUP_FILE}.gpg"
        SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo "[$(date)] Encrypted: $BACKUP_FILE ($SIZE)"
    else
        echo "[$(date)] WARNING: GPG encryption failed, keeping unencrypted"
    fi
    rm -rf "$GPG_HOMEDIR"
else
    echo "[$(date)] WARNING: GPG not available or key not found, keeping unencrypted"
fi

# Cleanup old backups (matches both plain .sql.gz and GPG-encrypted .sql.gz.gpg)
echo "[$(date)] Cleaning backups older than ${RETENTION_DAYS} days..."
find "$BACKUP_DIR" -name "mariadb_*.sql.gz*" -mtime +${RETENTION_DAYS} -delete

echo "[$(date)] Done."
