#!/bin/bash
# Backup Script — Daily backup for ERPNext and PostgreSQL
# Usage: ./backup.sh [--full]
# Location: /home/joker/RIAD CRM/scripts/backup.sh

set -euo pipefail

BACKUP_DIR="/home/joker/RIAD CRM/backups"
DATE=$(date +%Y%m%d_%H%M%S)
FULL_BACKUP=${1:-""}

mkdir -p "$BACKUP_DIR/$DATE"

echo "=== Security ERP Backup — $DATE ==="

# 1. MariaDB (ERPNext)
echo "[1/4] Backing up MariaDB (ERPNext)..."
docker exec mariadb mysqldump -u root -pmariadb_root_secret --all-databases --single-transaction > "$BACKUP_DIR/$DATE/mariadb_full.sql" 2>/dev/null
echo "  OK: mariadb_full.sql ($(du -h "$BACKUP_DIR/$DATE/mariadb_full.sql" | cut -f1))"

# 2. PostgreSQL (FSM, CMDB, AI, Integration, Audit)
echo "[2/4] Backing up PostgreSQL..."
docker exec postgres pg_dump -U postgres security_erp > "$BACKUP_DIR/$DATE/postgres_security_erp.sql" 2>/dev/null
echo "  OK: postgres_security_erp.sql ($(du -h "$BACKUP_DIR/$DATE/postgres_security_erp.sql" | cut -f1))"

# 3. n8n workflows
echo "[3/4] Backing up n8n data..."
docker exec n8n tar czf - /home/node/.n8n 2>/dev/null > "$BACKUP_DIR/$DATE/n8n_data.tar.gz" || echo "  WARNING: n8n backup failed"
echo "  OK: n8n_data.tar.gz"

# 4. ERPNext sites config
echo "[4/4] Backing up ERPNext config..."
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
