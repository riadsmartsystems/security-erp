#!/bin/bash
# Backup Script — Daily backup for Security ERP (single MariaDB database)
# Usage: ./backup.sh [--full]
# Location: /home/joker/RIAD CRM/scripts/backup.sh

set -euo pipefail

BACKUP_DIR="/home/joker/RIAD CRM/backups"
DATE=$(date +%Y%m%d_%H%M%S)
FULL_BACKUP=${1:-""}

mkdir -p "$BACKUP_DIR/$DATE"

echo "=== Security ERP Backup — $DATE ==="

# 1. MariaDB (single database for everything)
echo "[1/3] Backing up MariaDB..."
docker exec mariadb mysqldump -u root -p"${MARIADB_ROOT_PASSWORD}" --all-databases --single-transaction > "$BACKUP_DIR/$DATE/mariadb_full.sql" 2>/dev/null
echo "  OK: mariadb_full.sql ($(du -h "$BACKUP_DIR/$DATE/mariadb_full.sql" | cut -f1))"

# 2. n8n workflows
echo "[2/3] Backing up n8n data..."
docker exec n8n tar czf - /home/node/.n8n 2>/dev/null > "$BACKUP_DIR/$DATE/n8n_data.tar.gz" || echo "  WARNING: n8n backup failed"
echo "  OK: n8n_data.tar.gz"

# 3. ERPNext sites config
echo "[3/3] Backing up ERPNext config..."
docker exec erpnext-backend tar czf - /home/frappe/frappe-bench/sites/erp.localhost/site_config.json 2>/dev/null > "$BACKUP_DIR/$DATE/erpnext_site_config.tar.gz" || echo "  WARNING: config backup failed"
echo "  OK: erpnext_site_config.tar.gz"

# Cleanup old backups (keep 7 days)
echo ""
echo "Cleaning backups older than 7 days..."
find "$BACKUP_DIR" -maxdepth 1 -type d -mtime +7 -exec rm -rf {} \; 2>/dev/null || true

echo ""
echo "=== Backup Complete ==="
echo "Location: $BACKUP_DIR/$DATE/"
ls -lh "$BACKUP_DIR/$DATE/"
