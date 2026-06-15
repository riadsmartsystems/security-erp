#!/bin/bash
# Sync ERPNext assets from backend to frontend container
# Run this after rebuilding assets: docker exec erpnext-backend bench build
# Usage: ./sync-erpnext-assets.sh

set -e

echo "Syncing ERPNext assets from backend to frontend..."

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "  Copying assets from backend..."
docker cp erpnext-backend:/home/frappe/frappe-bench/apps/frappe/frappe/public/dist/. "$TEMP_DIR/frappe/" 2>/dev/null || true
docker cp erpnext-backend:/home/frappe/frappe-bench/apps/erpnext/erpnext/public/dist/. "$TEMP_DIR/erpnext/" 2>/dev/null || true
docker cp erpnext-backend:/home/frappe/frappe-bench/apps/security_erp/security_erp/public/dist/. "$TEMP_DIR/security_erp/" 2>/dev/null || true

echo "  Copying assets to frontend..."
docker cp "$TEMP_DIR/frappe/." erpnext-frontend:/home/frappe/frappe-bench/apps/frappe/frappe/public/dist/ 2>/dev/null || true
docker cp "$TEMP_DIR/erpnext/." erpnext-frontend:/home/frappe/frappe-bench/apps/erpnext/erpnext/public/dist/ 2>/dev/null || true
docker cp "$TEMP_DIR/security_erp/." erpnext-frontend:/home/frappe/frappe-bench/apps/security_erp/security_erp/public/dist/ 2>/dev/null || true

echo "  Restarting frontend..."
docker restart erpnext-frontend > /dev/null 2>&1

echo "Done. Assets synced and frontend restarted."
