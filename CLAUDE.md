# CLAUDE.md

**ВАЖЛИВО: Завжди відповідати українською мовою. Користувач спілкується українською.**

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Project Is

Security ERP Platform — a self-hosted ERP for security system installation/service companies (CCTV, access control, alarms). Built on ERPNext v15 with a FastAPI gateway. Production domain: `riad.fun`.

## Running the Stack

```bash
# Start all services
docker compose up -d

# First-time ERPNext site initialization
docker compose exec erpnext-backend bench new-site erp.localhost \
  --mariadb-root-password <MYSQL_ROOT_PASSWORD> --admin-password <ADMIN_PASSWORD>
docker compose exec erpnext-backend bench --site erp.localhost install-app erpnext
docker compose exec erpnext-backend bench --site erp.localhost install-app security_erp
docker compose exec erpnext-backend bench --site erp.localhost set-config developer_mode 1

# Generate Frappe API key for security-api
docker compose exec erpnext-backend bench --site erp.localhost new-api-key --user Administrator
# → paste output into .env as FRAPPE_API_KEY / FRAPPE_API_SECRET

# Deploy to production (pull + rebuild images + migrate)
./scripts/deploy.sh [--skip-migrations] [--skip-assets]

# Backup (MariaDB dump + n8n + ERPNext site config, keeps 7 days)
./scripts/backup.sh
```

## CI/CD (GitHub Actions)

`.github/workflows/ci.yml` runs on push/PR to master:
1. **Lint**: `flake8 services/ --max-line-length=120` and `black --check services/`
2. **Syntax check**: `python -m py_compile` on key files
3. **Unit tests**: `python tests/security-api/test_models.py`
4. **Docker build**: builds `security-api` and `telegram-service` images

Run lint/format locally:
```bash
pip install flake8 black isort
flake8 services/ --max-line-length=120 --ignore=E501,W503
black services/
python tests/security-api/test_models.py
```

Load tests (requires k6 at `~/.local/bin/k6`):
```bash
./scripts/run_tests.sh quick   # 5 VUs, 30s against http://localhost:8000
./scripts/run_tests.sh full    # 10 VUs, 2min
./scripts/run_tests.sh health
```

## Architecture Overview

### Data flow

```
Mobile / Browser
    ↓
Traefik (reverse proxy, port 80)
    ↓
security-api (FastAPI, port 8000)  ←→  Redis (rate limiting, token blacklist)
    ↓  JWT verified, role checked
erpnext-backend (Frappe/Gunicorn, port 8000 internal)
    ↓
MariaDB  ←  single source of truth for ALL data
```

### Services in `docker-compose.yml`

| Container | Role |
|---|---|
| `erpnext-backend` | Frappe app server (custom `Dockerfile.backend` adds gunicorn/gevent/httpx/anthropic) |
| `erpnext-frontend` | nginx serving ERPNext UI + socket.io proxy |
| `erpnext-worker-default/short` | Background job workers |
| `erpnext-scheduler` | Cron scheduler for daily/hourly tasks |
| `erpnext-socketio` | Real-time events |
| `mariadb` | Database |
| `redis` | Cache, queues, rate-limit counters |
| `traefik` | Reverse proxy + Cloudflare SSL termination |
| `cloudflared` | Cloudflare tunnel (external access at riad.fun) |
| `security-api` | FastAPI gateway (JWT auth + RBAC + Frappe proxy) |

### Security API (`services/security-api/`)

FastAPI app structured as:
- `app/core/config.py` — pydantic-settings (reads `.env`)
- `app/core/database.py` — async httpx client pool for Frappe; authenticates as Administrator via session cookie; exposes `frappe_get/post/put/delete`
- `app/core/redis.py` — async Redis client
- `app/auth/jwt.py` — JWT creation/decoding (HS256, 15-min access / 7-day refresh)
- `app/auth/permissions.py` — `Role` enum + `Permission` enum + `ROLE_PERMISSIONS` dict (source of truth for RBAC)
- `app/auth/dependencies.py` — `get_current_user()` FastAPI dep; checks token blacklist in Redis
- `app/routes/proxy.py` — legacy `/api/v1/*` catch-all that maps URL prefixes → Frappe DocTypes; carries `X-Deprecated: true` header
- `app/routes/auth.py` — `/api/v2/auth/*` (login/refresh/logout/me)
- Other routes (`visits`, `doctypes`, `mobile`, `signatures`, `banking`, `portal`, `public_api`) — `/api/v2/*` typed endpoints

**Role mapping**: `_map_frappe_role_from_names()` in `routes/auth.py:344` reads the `roles` array from `GET /api/resource/User/{id}`. Priority order: System Manager > Service Manager > Sales Manager > Projects Manager > HR Manager > Engineer/Технік > Директор > Бухгалтер > Склад > viewer. Ukrainian Frappe role names (Технік/Директор/Бухгалтер/Склад) are already handled — do not add duplicates.

### Custom Frappe App (`erpnext/security_erp/`)

Mounted into the ERPNext container as a volume at `/home/frappe/frappe-bench/apps/security_erp`.

Key extension points (all declared in `security_erp/hooks.py`):
- **`doc_events`** — hooks on standard Frappe DocTypes (Address, Lead, Customer, Quotation, Sales Order, Project, Service Ticket)
- **`scheduler_events`** — daily: warranty expiry + SLA compliance; hourly: SLA breach checks
- **`override_doctype_class`** — `Address` overridden with `CustomAddress`
- **`fixtures`** — exported with `bench export-fixtures`; includes Custom Fields, Role Profiles, Security Scenarios

Custom DocTypes live under `security_erp/security_erp/doctype/`:
- **FSM**: `service_ticket`, `visit`, `visit_material`, `visit_photo`, `maintenance_plan`, `warranty_case`, `sla_event`
- **CMDB**: `security_object`, `equipment`, `equipment_type`, `equipment_relation`, `vendor`, `object_building`, `object_floor`, `object_room`
- **Sales**: `contract`, `contract_object`, `estimate`, `estimate_item`, `estimate_template`, `installation_act`
- **Inventory**: `material_reservation`
- **AI**: `security_scenario`, `security_scenario_item`

### ERPNext Bench Commands (run inside `erpnext-backend` container)

```bash
docker compose exec erpnext-backend bench --site erp.localhost migrate
docker compose exec erpnext-backend bench --site erp.localhost clear-cache
docker compose exec erpnext-backend bench --site erp.localhost export-fixtures
docker compose exec erpnext-backend bench build --force   # rebuild JS/CSS assets
```

### Data Migration Scripts (`scripts/migration/`)

Wave-based CSV import via Frappe REST API:
- Wave 1: customers → Wave 2: objects → Wave 3: equipment → Wave 4: tickets

```bash
cd scripts/migration
python migrate_all.py                        # all waves, default CSVs
python migrate_all.py --waves 1,2            # specific waves
python migrate_all.py --input /path/to/csvs  # custom directory
```

## Environment Variables

See `.env.example`. Minimum required for local dev:
- `MYSQL_ROOT_PASSWORD`, `SITE_NAME` (default `erp.localhost`), `ADMIN_PASSWORD`

The `security-api` container reads its own `.env` for:
- `SECRET_KEY`, `FRAPPE_API_KEY`, `FRAPPE_API_SECRET`, `FRAPPE_PASSWORD`
- `REDIS_URL`, `ANTHROPIC_API_KEY` (for AI features)
- `FRAPPE_URL` defaults to `http://erpnext-backend:8000`

## API Versioning

- `/api/v1/*` — legacy proxy routes (deprecated, marked with `X-Deprecated: true` response header)
- `/api/v2/*` — current typed FastAPI routes

## Redis Key Namespaces (security-api)

Convention: namespace-prefixed keys prevent cross-feature collisions.

| Prefix | Purpose | Example |
|--------|---------|---------|
| `rl:login:{ip}` | Login rate limit (sliding window) | max=5/900s |
| `rl:refresh:{user_id}` | Refresh rate limit | max=30/900s |
| `rt:bl:{jti}` | Refresh token blacklist (reuse-detection) | TTL = remaining JWT exp |
| `rt:sess:{user_id}:{device_id}` | Active device session JSON | TTL = refresh token TTL |
| `rt:devices:{user_id}` | Set of active device_ids for a user | no TTL (managed by revoke) |
| `frappe:sid:{user_id}` | Cached Frappe SID per user | TTL = 6h (`frappe_session_ttl`) |
| `act:tok:{token}` | Vault Access Transfer Act delivery token | TTL = 86400s |
| `vault:mfa:{token}` | Vault MFA step-up session | TTL = 300s (`vault_mfa_ttl`) |

Rate limit config lives in `app/core/config.py` (`rate_limit_login_max`, `rate_limit_login_window`, etc.).

## CI Gate Pattern (infra-dependent features)

When a feature requires Redis/DB to integration-test, use a **grep gate** in CI instead of a live-Redis test:

```yaml
- name: R4 CI gate — check_rate_limit wired on login and refresh
  run: |
    python -c "
    content = open('services/security-api/app/routes/auth.py').read()
    assert 'rl:login:' in content, 'login rate-limit key missing'
    assert 'rl:refresh:' in content, 'refresh rate-limit key missing'
    print('R4 gate OK')
    "
```

Unit test the logic (mock `check_rate_limit` at call site) + grep gate = sufficient CI evidence. Real integration tests → staging/E9.

## Test Environment Notes

- `requirements-test.txt` must include ALL packages that `app/main.py` imports at module level (not just test-specific deps). When a test's `tearDown` does `from app.main import app`, any missing package causes ERROR in tearDown even if the test itself passed.
- Current omission fixed: `prometheus-client>=0.20.0` was in `services/security-api/requirements.txt` but not in `requirements-test.txt`. Now synced.
- Redis pipeline mock pattern: use `MagicMock()` for sync-queued commands (`zadd`, `zremrangebyscore`, `zcard`, `expire`) and `AsyncMock()` only for `execute()`. Using `AsyncMock` for queued commands causes `RuntimeWarning: coroutine never awaited`.

## Кодування — правила якості (незмінні)

**Ці правила створені після аналізу системних збоїв (S4 болванка). Порушення = переробка.**

1. **Один файл за раз.** Написати → перевірити що реалістичний (компілюється, логіка вірна) → наступний. Не починати 2+ файли одночасно без перевірки першого.

2. **Тести ПЕРШИМИ (TDD).** Написати тест який перевіряє реальну поведінку (не моки всього) → побачити що падає → написати код що зеленить. Тест без реальних даних = нічого не тестує.

3. **Прочитати ВСІ пов'язані сервіси повністю** перед кодуванням нового ендпоінту. Не початки — повністю. Зрозуміти як існуючий код обробляє помилки Frappe, які патерни використовує.

4. **Перевірка реальності.** Код має враховувати реальну структуру відповіді Frappe REST API (`{"data": [...]}`, `{"message": {...}}`). Не придумувати структуру — перевіряти по існуючому коду (`sync_service.py`, `estimate_service.py`).

5. **Не генерувати болванку.** Якщо не впевнений у деталях (обов'язкові поля DocType, структура відповіді, side effects) — написати "потребує уточнення" замість вигаданого коду.

6. **Викликати skills перед стартом складних задач:** `test-driven-development`, `verification-before-completion`, `requesting-code-review`.

7. **DoD = "працює", не "зроблено".** Файл існує ≠ завдання виконане. Тест написаний ≠ тест зелений. DoD-пункт закритий лише коли є доказ (тест pass, компіляція OK, реальний виклик).
