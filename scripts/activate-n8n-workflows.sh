#!/bin/bash
# Activate n8n workflows after startup
# This script should be run after n8n is fully started
# Usage: ./activate-n8n-workflows.sh

set -e

N8N_URL="http://localhost:5678"
N8N_USER="joker"
N8N_PASS="jokerLA23"

echo "Waiting for n8n to be ready..."
for i in $(seq 1 30); do
    if curl -s -o /dev/null -w "%{http_code}" "$N8N_URL" 2>/dev/null | grep -q "200"; then
        echo "n8n is ready."
        break
    fi
    sleep 2
done

echo "Activating n8n workflows..."

WORKFLOWS=$(docker exec n8n n8n list:workflow 2>/dev/null | tail -n +2)

if [ -z "$WORKFLOWS" ]; then
    echo "No workflows found"
    exit 0
fi

ACTIVATED=0
FAILED=0

while IFS='|' read -r id name; do
    id=$(echo "$id" | xargs)
    name=$(echo "$name" | xargs)
    
    if [ -z "$id" ]; then
        continue
    fi
    
    echo -n "  Activating: $name ($id)... "
    
    if docker exec n8n n8n publish:workflow --id="$id" 2>/dev/null; then
        echo "OK"
        ACTIVATED=$((ACTIVATED + 1))
    else
        echo "FAILED"
        FAILED=$((FAILED + 1))
    fi
done <<< "$WORKFLOWS"

echo ""
echo "Done: $ACTIVATED activated, $FAILED failed"
echo "Restart n8n to apply: docker restart n8n"
