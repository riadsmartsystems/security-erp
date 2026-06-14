#!/bin/bash
# Load Test Runner for Security ERP
# Usage: ./run_tests.sh [quick|full|health]
# Requires: k6 (https://k6.io)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEST_DIR="$SCRIPT_DIR/tests/load"
RESULTS_DIR="$SCRIPT_DIR/tests/load/results"

mkdir -p "$RESULTS_DIR"

K6="$HOME/.local/bin/k6"
if [ ! -f "$K6" ]; then
    echo "k6 not found. Install: curl -sL https://github.com/grafana/k6/releases/download/v0.49.0/k6-v0.49.0-linux-amd64.tar.gz | tar xz"
    exit 1
fi

BASE_URL="${BASE_URL:-http://localhost:8000}"
TEST_TYPE="${1:-quick}"

echo "=== Security ERP Load Tests ==="
echo "Target: $BASE_URL"
echo "Test: $TEST_TYPE"
echo ""

case "$TEST_TYPE" in
    quick)
        echo "Running quick health check test (5 VUs, 30s)..."
        $K6 run "$TEST_DIR/quick_test.js"
        ;;
    health)
        echo "Running health check test..."
        $K6 run "$TEST_DIR/health_check.js"
        ;;
    full)
        echo "Running full API test (10 VUs, 2min)..."
        $K6 run "$TEST_DIR/api_gateway.js"
        ;;
    *)
        echo "Unknown test: $TEST_TYPE"
        echo "Usage: ./run_tests.sh [quick|health|full]"
        exit 1
        ;;
esac

echo ""
echo "=== Test Complete ==="
