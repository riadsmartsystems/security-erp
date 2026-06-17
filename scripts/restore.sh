#!/bin/bash
# Restore Script for Security ERP Platform
# Usage: ./restore.sh <backup_directory>
# WARNING: This will overwrite existing data!

set -euo pipefail

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
if [ -f "$BACKUP_DIR/mariadb_full.sql" ]; then
    echo "[1/4] Restoring MariaDB..."
    docker exec -i mariadb mysql -u root -p"${MARIADB_ROOT_PASSWORD}" < "$BACKUP_DIR/mariadb_full.sql" 2>/dev/null
    echo "  OK"
else
    echo "[1/4] MariaDB backup not found, skipping"
fi

# 2. Restore PostgreSQL
if [ -f "$BACKUP_DIR/postgres_security_erp.sql" ]; then
    echo "[2/4] Restoring PostgreSQL..."
    docker exec -i postgres psql -U postgres -d security_erp < "$BACKUP_DIR/postgres_security_erp.sql" 2>/dev/null
    echo "  OK"
else
    echo "[2/4] PostgreSQL backup not found, skipping"
fi

# 3. Restore n8n data
if [ -f "$BACKUP_DIR/n8n_data.tar.gz" ]; then
    echo "[3/4] Restoring n8n data..."
    docker cp "$BACKUP_DIR/n8n_data.tar.gz" n8n:/tmp/n8n_backup.tar.gz
    docker exec n8n tar xzf /tmp/n8n_backup.tar.gz -C / 2>/dev/null
    docker exec n8n rm /tmp/n8n_backup.tar.gz
    echo "  OK"
else
    echo "[3/4] n8n backup not found, skipping"
fi

# 4. Restart services
echo "[4/4] Restarting services..."
docker restart erpnext-backend mariadb postgres 2>/dev/null
echo "  OK"

echo ""
echo "=== Restore Complete ==="
echo "Please verify services are running: docker ps"
