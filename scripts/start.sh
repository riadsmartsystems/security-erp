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

# Create MinIO buckets
echo "Initializing MinIO buckets..."
chmod +x scripts/init-minio.sh

# Build custom images
echo "Building custom service images..."
docker compose build security-api telegram-service

# Start all services
echo "Starting all services..."
docker compose up -d

echo ""
echo "=== Services ==="
echo "ERPNext:        http://erp.localhost"
echo "API Gateway:    http://api.localhost"
echo "Traefik:        http://localhost:8080"
echo "MinIO Console:  http://localhost:9001"
echo "n8n:            http://localhost:5678"
echo "Grafana:        http://localhost:3000"
echo "Prometheus:     http://localhost:9090"
echo ""
echo "=== Health Checks ==="
sleep 10

for svc in security-api; do
    status=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health 2>/dev/null || echo "000")
    echo "$svc: $status"
done

# Check ERPNext
status=$(curl -s -o /dev/null -w "%{http_code}" -H "Host: erp.localhost" http://localhost:8000/api/method/ping 2>/dev/null || echo "000")
echo "erpnext-backend: $status"

echo ""
echo "=== Done ==="
