#!/bin/bash
# Sync ERPNext assets from backend to frontend container
# Run after: docker exec erpnext-backend bench build
# Usage: ./sync-erpnext-assets.sh

set -e

echo "=== ERPNext Asset Sync ==="

TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "[1/4] Copying frappe assets from backend..."
docker cp erpnext-backend:/home/frappe/frappe-bench/apps/frappe/frappe/public/dist/. "$TEMP_DIR/frappe/" 2>/dev/null || echo "  Warning: frappe dist not found"

echo "[2/4] Copying erpnext assets from backend..."
docker cp erpnext-backend:/home/frappe/frappe-bench/apps/erpnext/erpnext/public/dist/. "$TEMP_DIR/erpnext/" 2>/dev/null || echo "  Warning: erpnext dist not found"

echo "[3/4] Copying security_erp assets from backend..."
docker cp erpnext-backend:/home/frappe/frappe-bench/apps/security_erp/security_erp/public/dist/. "$TEMP_DIR/security_erp/" 2>/dev/null || true

echo "[4/4] Copying assets to frontend..."
docker cp "$TEMP_DIR/frappe/." erpnext-frontend:/home/frappe/frappe-bench/apps/frappe/frappe/public/dist/ 2>/dev/null || echo "  Warning: failed to copy frappe assets"
docker cp "$TEMP_DIR/erpnext/." erpnext-frontend:/home/frappe/frappe-bench/apps/erpnext/erpnext/public/dist/ 2>/dev/null || echo "  Warning: failed to copy erpnext assets"
docker cp "$TEMP_DIR/security_erp/." erpnext-frontend:/home/frappe/frappe-bench/apps/security_erp/security_erp/public/dist/ 2>/dev/null || true

echo ""
echo "=== Asset Sync Complete ==="
echo "Note: If CSS/JS still shows 404, clear Cloudflare cache:"
echo "  curl -s -o /dev/null -w '%{http_code}' https://erp.riad.fun/assets/... -H 'Cache-Control: no-cache'"
