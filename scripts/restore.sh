#!/bin/bash
# Restore Script for Security ERP Platform
# Usage: ./restore.sh <backup_directory>
# WARNING: This will overwrite existing data!

set -euo pipefail

if [ -z "${MYSQL_ROOT_PASSWORD:-}" ]; then
    ENV_FILE="$(dirname "$0")/../.env"
    if [ -f "$ENV_FILE" ]; then set -a; . "$ENV_FILE"; set +a; fi
fi
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"

# Resolve container names (docker-compose adds project prefix)
MARIADB_CONTAINER=$(docker ps --format '{{.Names}}' | grep -m1 'mariadb' || echo "mariadb")

BACKUP_DIR=${1:-""}

if [ -z "$BACKUP_DIR" ]; then
    echo "Usage: ./restore.sh <backup_directory>"
    echo "Example: ./restore.sh /home/joker/RIAD CRM/backups/20260614_032354"
    exit 1
fi

if [ ! -d "$BACKUP_DIR" ]; then
    echo "Error: Directory $BACKUP_DIR does not exist"
    exit 1
fi

echo "=== Security ERP Restore ==="
echo "Source: $BACKUP_DIR"
echo ""
echo "⚠️  WARNING: This will overwrite existing data!"
read -p "Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
fi

# 1. Restore MariaDB
if [ -f "$BACKUP_DIR/mariadb_full.sql.gz" ]; then
    echo "[1/2] Restoring MariaDB from compressed backup..."
    gunzip -c "$BACKUP_DIR/mariadb_full.sql.gz" | docker exec -i "$MARIADB_CONTAINER" mysql -u root -p"${MARIADB_ROOT_PASSWORD}" 2>/dev/null
    echo "  OK"
elif [ -f "$BACKUP_DIR/mariadb_full.sql" ]; then
    echo "[1/2] Restoring MariaDB..."
    docker exec -i "$MARIADB_CONTAINER" mysql -u root -p"${MARIADB_ROOT_PASSWORD}" < "$BACKUP_DIR/mariadb_full.sql" 2>/dev/null
    echo "  OK"
else
    echo "[1/2] MariaDB backup not found, skipping"
fi

# 2. Restart services
echo "[2/2] Restarting services..."
docker restart "$MARIADB_CONTAINER" erpnext-backend 2>/dev/null
echo "  OK"

echo ""
echo "=== Restore Complete ==="
echo "Please verify services are running: docker ps"
