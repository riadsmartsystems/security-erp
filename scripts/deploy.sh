#!/bin/bash
# =============================================================================
# Security ERP — Go-Live Deployment Script
# =============================================================================
# Run on the production server after code updates.
# Usage: ./deploy.sh [--skip-migrations] [--skip-assets]
# =============================================================================

set -e

if [ ! -f .env ]; then
    echo "ERROR: .env not found. Copy .env.example and fill in values." >&2
    exit 1
fi

set -a; source .env; set +a
MARIADB_ROOT_PASSWORD="${MARIADB_ROOT_PASSWORD:-${MYSQL_ROOT_PASSWORD:-}}"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

SKIP_MIGRATIONS=false
SKIP_ASSETS=false

for arg in "$@"; do
    case $arg in
        --skip-migrations) SKIP_MIGRATIONS=true ;;
        --skip-assets) SKIP_ASSETS=true ;;
        --help)
            echo "Usage: $0 [--skip-migrations] [--skip-assets]"
            exit 0
            ;;
    esac
done

echo "============================================"
echo " Security ERP Deployment"
echo " $(date '+%Y-%m-%d %H:%M:%S')"
echo "============================================"
echo ""

# ---------------------------------------------------------------------------
# Step 1: Pull latest code
# ---------------------------------------------------------------------------
echo "[1/7] Pulling latest code..."
cd "$PROJECT_DIR"
git pull origin master 2>/dev/null || git pull origin main 2>/dev/null || echo "  (git pull skipped — not a git repo or no remote)"
echo ""

# ---------------------------------------------------------------------------
# Step 2: Rebuild Docker images
# ---------------------------------------------------------------------------
echo "[2/7] Rebuilding Docker images..."
docker compose build --no-cache erpnext-backend 2>&1 | tail -3
echo ""

# ---------------------------------------------------------------------------
# Step 3: Restart services
# ---------------------------------------------------------------------------
echo "[3/7] Restarting services..."
docker compose up -d 2>&1 | tail -5
echo ""

# ---------------------------------------------------------------------------
# Step 3.5: Run bench migrate
# ---------------------------------------------------------------------------
if [ "$SKIP_MIGRATIONS" = false ]; then
    echo "[3.5/7] Running bench migrate..."
    docker exec erpnext-backend bench --site erp.localhost migrate 2>&1 | tail -20
    echo ""
else
    echo "[3.5/7] Skipping bench migrate (--skip-migrations)"
fi

# ---------------------------------------------------------------------------
# Step 4: Wait for health
# ---------------------------------------------------------------------------
echo "[4/7] Waiting for services to be healthy..."
for i in $(seq 1 30); do
    if curl -sf -H "Host: erp.localhost" http://localhost/api/method/ping > /dev/null 2>&1; then
        echo "  ERPNext: OK"
        break
    fi
    sleep 2
done
echo ""

# ---------------------------------------------------------------------------
# Step 5: Fix ERPNext assets for Cloudflare
# ---------------------------------------------------------------------------
if [ "$SKIP_ASSETS" = false ]; then
    echo "[5/7] Fixing ERPNext assets for Cloudflare..."
    docker exec erpnext-backend bench set-config host_name https://erp.riad.fun 2>&1 | tail -1
    docker exec erpnext-backend bench build --force 2>&1 | tail -3
    "$SCRIPT_DIR/sync-erpnext-assets.sh" 2>/dev/null || echo "  (sync script not found — manual sync needed)"
    docker restart erpnext-frontend > /dev/null 2>&1
    echo "  Assets rebuilt and synced."
else
    echo "[5/7] Skipping asset rebuild (--skip-assets)"
fi
echo ""

# ---------------------------------------------------------------------------
# Step 6: Run migrations (optional)
# ---------------------------------------------------------------------------
if [ "$SKIP_MIGRATIONS" = false ]; then
    echo "[6/7] Data migration (if CSV files present)..."
    MIGRATION_DIR="$SCRIPT_DIR/migration"
    if [ -d "$MIGRATION_DIR" ]; then
        cd "$MIGRATION_DIR"
        for wave in 1 2 3 4; do
            CSV="sample_wave${wave}_*.csv"
            if ls $CSV 1>/dev/null 2>&1; then
                echo "  Running wave $wave..."
                python3 migrate_all.py --waves $wave 2>&1 | tail -2
            fi
        done
        cd "$SCRIPT_DIR"
    else
        echo "  (migration directory not found — skipping)"
    fi
else
    echo "[6/7] Skipping migrations (--skip-migrations)"
fi

# ---------------------------------------------------------------------------
# Step 7: Verify durability
echo "[7/7] Verifying durability..."
MARIADB_CONTAINER=$(docker ps --format '{{.Names}}' | grep -m1 'mariadb' || echo "mariadb")
REDIS_CONTAINER=$(docker ps --format '{{.Names}}' | grep -m1 'redis' || echo "redis")
docker exec "$MARIADB_CONTAINER" mysql -u root -p"${MARIADB_ROOT_PASSWORD}" -e "SHOW VARIABLES LIKE 'log_bin';" 2>/dev/null | grep -q "ON" && echo "  binlog: OK" || echo "  binlog: WARNING"
docker exec "$REDIS_CONTAINER" redis-cli CONFIG GET appendonly 2>/dev/null | grep -q "yes" && echo "  Redis AOF: OK" || echo "  Redis AOF: WARNING"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "============================================"
echo " Deployment Complete"
echo "============================================"
echo ""
echo " Services:"
echo "   ERPNext:    https://erp.riad.fun"
echo "   API:        https://api.riad.fun (DEFER — не запущено)"
echo ""
echo " Post-deploy tasks:"
echo "   1. Verify CSS/JS loads at https://erp.riad.fun"
echo "   2. Test login with FRAPPE_USERNAME/FRAPPE_PASSWORD"
echo "   3. Run: docker system prune (if disk > 60GB)"
echo ""
