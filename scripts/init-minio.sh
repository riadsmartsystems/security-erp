#!/bin/sh
# Wait for MinIO to be ready, then create buckets
set -e

echo "Waiting for MinIO..."
sleep 5

mc alias set local http://minio:9000 ${MINIO_ROOT_USER} ${MINIO_ROOT_PASSWORD}

echo "Creating buckets..."
mc mb --ignore-existing local/contracts
mc mb --ignore-existing local/objects
mc mb --ignore-existing local/visits
mc mb --ignore-existing local/projects
mc mb --ignore-existing local/configs
mc mb --ignore-existing local/reports
mc mb --ignore-existing local/tmp

echo "Setting versioning..."
mc version enable local/contracts
mc version enable local/objects
mc version enable local/projects
mc version enable local/configs

echo "MinIO initialization complete."
