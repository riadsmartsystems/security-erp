#!/bin/bash
# Security ERP Platform - Startup Script
set -e

echo "=== Security ERP Platform ==="
echo "Initializing..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "ERROR: Docker is not installed"
    exit 1
fi

# Create .env from example if not exists
if [ ! -f .env ]; then
    echo "Creating .env from defaults..."
    cp .env.example .env 2>/dev/null || echo "No .env.example found, using existing .env"
fi

# Build custom images
echo "Building custom service images..."
docker compose build erpnext-backend

# Start all services
echo "Starting all services..."
docker compose up -d

echo ""
echo "=== Services ==="
echo "ERPNext:     http://erp.localhost"
echo "Traefik:     http://localhost:8080"
echo ""
echo "=== Health Checks ==="
sleep 10

# Check ERPNext backend
status=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: erp.localhost" http://localhost:8000/api/method/ping 2>/dev/null || echo "000")
echo "erpnext-backend: $status"

echo ""
echo "=== Done ==="
