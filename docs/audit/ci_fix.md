# Fix for .github/workflows/ci.yml
#
# PROBLEM: 67 tests fail with ModuleNotFoundError on host.
# Tests need: fastapi, pydantic, httpx, python-jose[cryptography], redis, pydantic_settings
# CI sets PYTHONPATH but never pip-installs these packages.
# Result: CI only syntax-checks, never tests business logic.
#
# SOLUTION: Add requirements-test.txt + install step in CI.
#
# ─────────────────────────────────────────────────────────────
# FILE 1: requirements-test.txt (root of repo)
# ─────────────────────────────────────────────────────────────

# requirements-test.txt
fastapi>=0.111.0
pydantic>=2.0
pydantic-settings>=2.0
httpx>=0.27.0
python-jose[cryptography]>=3.3.0
redis>=5.0.0
pytest>=8.0.0
pytest-asyncio>=0.23.0

# ─────────────────────────────────────────────────────────────
# FILE 2: .github/workflows/ci.yml — DIFF
# ─────────────────────────────────────────────────────────────
# Find the existing "Run tests" or "Lint" step and ADD BEFORE IT:

# --- BEFORE ---
#      - name: Run tests
#        env:
#          PYTHONPATH: services/security-api:erpnext/security_erp
#        run: |
#          python tests/security-api/test_models.py

# --- AFTER ---
#      - name: Install test dependencies
#        run: pip install -r requirements-test.txt
#
#      - name: Run tests
#        env:
#          PYTHONPATH: services/security-api:erpnext/security_erp
#        run: |
#          python -m pytest tests/security-api/test_models.py -v
#          python -m pytest tests/s1/ -v
#          python -m pytest tests/ai/ -v
#          python -m pytest tests/a4/ -v
#          python -m pytest tests/s4/ -v
#          python -m pytest tests/a3/ -v
#          python tests/vault_isolation/check_vault_isolation.py
#          python tests/ai_isolation/check_ai_isolation.py
#          python tests/vault/test_act_pure.py

# ─────────────────────────────────────────────────────────────
# IMPORTANT NOTES:
# ─────────────────────────────────────────────────────────────
# 1. tests/ai/test_a1_circuit_breaker.py needs redis running → add:
#    services:
#      redis:
#        image: redis:7
#        ports: ["6379:6379"]
#
# 2. tests that need Frappe DB (frappe.get_doc etc.) → these require
#    full Frappe stack — cannot run on bare CI. Keep them Docker-only.
#    Mark them with pytest.mark.requires_frappe and skip in CI:
#    pytest -m "not requires_frappe"
#
# 3. Existing graceful skip in test_models.py (15 skip / 1 pass) will
#    become 15 PASS / 0 skip after this fix.
