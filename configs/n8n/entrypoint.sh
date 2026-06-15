#!/bin/sh
# n8n entrypoint: activate existing workflows, then start n8n
# This avoids duplicate imports on every restart
set -e

echo "Checking n8n workflows..."

# Check if workflows already exist in the database
EXISTING=$(n8n list:workflow 2>/dev/null | wc -l)

if [ "$EXISTING" -gt 1 ]; then
    echo "Found $((EXISTING - 1)) existing workflows. Skipping import."
else
    echo "No workflows found. Importing from /home/node/.n8n/import/workflows..."
    if [ -d "/home/node/.n8n/import/workflows" ] && [ "$(ls -A /home/node/.n8n/import/workflows/*.json 2>/dev/null)" ]; then
        n8n import:workflow --separate --input=/home/node/.n8n/import/workflows --activeState=fromJson 2>/dev/null || true
        echo "Workflows imported."
    fi
fi

echo "Starting n8n..."
exec n8n start
