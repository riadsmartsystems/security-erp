#!/bin/bash
# Build ERPNext assets and sync to frontend container
# Usage: ./build-erpnext-assets.sh [--force]

set -e

FORCE_FLAG=""
if [ "$1" = "--force" ]; then
    FORCE_FLAG="--force"
fi

echo "=== Building ERPNext Assets ==="

echo "[1/3] Running bench build $FORCE_FLAG..."
docker exec erpnext-backend bench build $FORCE_FLAG 2>&1 | tail -5

echo "[2/3] Syncing assets to frontend..."
/home/joker/RIAD\ CRM/scripts/sync-erpnext-assets.sh

echo "[3/3] Restarting frontend container..."
docker restart erpnext-frontend > /dev/null 2>&1

echo ""
echo "=== Build Complete ==="
echo "Assets are now synced and frontend is restarted."
echo "Test at: https://erp.riad.fun"
