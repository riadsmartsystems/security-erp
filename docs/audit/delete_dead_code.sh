#!/bin/bash
# Fix 2.1: Delete dead code files
# Run from repo root. Verify first, then delete.

set -e

echo "=== Verifying no imports exist before deletion ==="

FILES=(
  "ai_service"
  "admin_service"
  "media_service"
  "scenario_service"
)

for f in "${FILES[@]}"; do
  COUNT=$(grep -r "from app.services.${f}\|import ${f}" services/security-api/ 2>/dev/null | wc -l)
  if [ "$COUNT" -gt 0 ]; then
    echo "❌ ABORT: ${f} IS imported somewhere:"
    grep -r "from app.services.${f}\|import ${f}" services/security-api/
    exit 1
  else
    echo "✅ ${f}: 0 imports found — safe to delete"
  fi
done

COUNT=$(grep -r "from app.schemas.admin\|schemas.admin" services/security-api/ 2>/dev/null | wc -l)
if [ "$COUNT" -gt 0 ]; then
  echo "❌ ABORT: schemas/admin.py IS imported somewhere:"
  grep -r "from app.schemas.admin" services/security-api/
  exit 1
else
  echo "✅ schemas/admin: 0 imports found — safe to delete"
fi

echo ""
echo "=== Deleting dead code files ==="

rm -v services/security-api/app/services/ai_service.py
rm -v services/security-api/app/services/admin_service.py
rm -v services/security-api/app/services/media_service.py
rm -v services/security-api/app/services/scenario_service.py
rm -v services/security-api/app/schemas/admin.py

echo ""
echo "=== Verifying main.py still compiles ==="
python -m py_compile services/security-api/app/main.py && echo "✅ main.py OK"

echo ""
echo "=== Done. Update fix_progress.md [2.1] ==="
