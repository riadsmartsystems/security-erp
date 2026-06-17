#!/bin/bash
# Security ERP Platform — End-to-End Test Script
# Usage: ./test_e2e.sh

BASE_URL="http://localhost:8000"
PASS=0
FAIL=0

echo "=== Security ERP E2E Tests ==="
echo ""

check() {
    local desc=$1
    local url=$2
    local expected=$3

    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null)
    if [ "$status" = "$expected" ]; then
        echo "  ✅ $desc → $status"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $desc → $status (expected $expected)"
        FAIL=$((FAIL + 1))
    fi
}

check_auth() {
    local desc=$1
    local url=$2
    local expected=$3

    status=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" -H "Authorization: Bearer $TOKEN" 2>/dev/null)
    if [ "$status" = "$expected" ]; then
        echo "  ✅ $desc → $status"
        PASS=$((PASS + 1))
    else
        echo "  ❌ $desc → $status (expected $expected)"
        FAIL=$((FAIL + 1))
    fi
}

echo "1. Health Checks"
check "Security API" "http://localhost:8000/health" "200"
check "n8n" "http://localhost:5678/healthz" "200"

echo ""
echo "2. Authentication"
TOKEN=$(curl -s -X POST "$BASE_URL/api/v1/auth/login" -H "Content-Type: application/json" --max-time 10 -d "{\"username\":\"${TEST_USER:-Administrator}\",\"password\":\"${TEST_PASS:-}}\" 2>/dev/null | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))" 2>/dev/null)

if [ -n "$TOKEN" ]; then
    echo "  ✅ Login successful"
    PASS=$((PASS + 1))
else
    echo "  ❌ Login failed"
    FAIL=$((FAIL + 1))
fi

echo ""
echo "3. Auth Endpoints"
check_auth "Auth /me" "$BASE_URL/api/v1/auth/me" "200"

echo ""
echo "4. FSM Endpoints"
check_auth "Tickets" "$BASE_URL/api/v1/tickets" "200"
check_auth "Visits" "$BASE_URL/api/v1/visits" "200"
check_auth "Maintenance" "$BASE_URL/api/v1/maintenance" "200"
check_auth "Warranty" "$BASE_URL/api/v1/warranty" "200"

echo ""
echo "5. CMDB Endpoints"
check_auth "Objects" "$BASE_URL/api/v1/objects" "200"
check_auth "Equipment" "$BASE_URL/api/v1/equipment" "200"
check_auth "Vendors" "$BASE_URL/api/v1/vendors" "200"
check_auth "Equipment Types" "$BASE_URL/api/v1/equipment-types" "200"

echo ""
echo "6. Portal & Mobile"
check_auth "Portal Dashboard" "$BASE_URL/api/v1/portal/dashboard?customer_id=test" "200"
check_auth "Mobile Dashboard" "$BASE_URL/api/v1/mobile/dashboard?engineer_id=test" "200"

echo ""
echo "7. Public API"
check "Public Status" "$BASE_URL/api/v1/public/status" "200"

echo ""
echo "8. RBAC (no auth)"
check "No Auth → 403" "$BASE_URL/api/v1/tickets" "403"

echo ""
echo "=== Results ==="
TOTAL=$((PASS + FAIL))
echo "Total: $TOTAL | Passed: $PASS | Failed: $FAIL"

if [ $FAIL -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ $FAIL tests failed"
    exit 1
fi
