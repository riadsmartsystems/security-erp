# Go-Live Checklist — Security ERP Platform
_Оновлено: 2026-06-17_

## Infrastructure
- [x] Docker Compose налаштовано (10 контейнерів)
- [x] Cloudflare Tunnel підключено (riad.fun)
- [x] TLS 1.3 для всіх публічних ендпоінтів
- [x] MariaDB healthy, Redis healthy
- [x] Traefik reverse proxy

## Security
- [x] JWT автентифікація (15 min access, 7d refresh)
- [x] RBAC налаштовано (9 ролей)
- [x] Frappe API key authentication
- [x] Cloudflare Access OTP для зовнішнього доступу
- [x] Rate limiting (Redis, 1000 req/min per IP)
- [x] CORS налаштовано (specific origins, not wildcard)
- [x] Жодних hardcoded credentials в коді
- [x] Telegram bot token в env vars
- [x] Frappe password в env vars
- [x] Bandit security scan (CI)

## Single Database Architecture
- [x] Всі дані в MariaDB через ERPNext DocTypes
- [x] 25 DocTypes в модулі Security ERP
- [x] Security API → Frappe API proxy
- [x] FSM/CMDB/AI мікросервіси ВИДАЛЕНІ (зайві, все в Frappe)

## ERPNext
- [x] security_erp додаток встановлено (v1.0.0)
- [x] 25 DocTypes з правами доступу
- [x] Ukrainian language configured
- [x] Workspace з 11 shortcuts для Security ERP DocTypes
- [x] CSS/JS assets (SLA colors, priority colors, utility functions)
- [x] Ticket events registered (realtime + n8n webhooks)
- [x] SLA tasks enabled (daily + hourly)
- [ ] CSS/JS assets завантажуються через Cloudflare (потрібен bench set-config на сервері)

## API Gateway
- [x] Security API Gateway (:8000) — JWT, RBAC, Proxy → Frappe
- [x] 36+ routes (auth, tickets, objects, equipment, visits, etc.)
- [x] Frappe API proxy для всіх DocType операцій
- [x] Visit action routes (start/finish/materials/photos) для v1 і v2
- [x] Stats endpoint з агрегацією

## Android App
- [x] SSL verification enabled (badCertificateCallback removed)
- [x] Passwords stored in FlutterSecureStorage
- [x] Materials list loads on screen open
- [x] Priority badges (icons, not row numbers)
- [x] Drawer removed (NavigationBar only)
- [x] Visit confirmation dialogs
- [x] Null-check for assigned engineer
- [x] Dark theme support
- [x] Frappe field names corrected

## Data Migration
- [x] migrate_customers.py — CSV → ERPNext (готовий)
- [x] migrate_objects.py — CSV → Security Object (готовий)
- [x] migrate_equipment.py — CSV → Equipment (готовий)
- [x] migrate_tickets.py — CSV → Service Ticket (готовий)
- [x] Sample CSV files (4 хвилі)
- [ ] Запуск міграцій на сервері (потребує Frappe credentials)

## Backup
- [x] backup-mariadb.sh — daily 2AM, weekly Sun 3AM
- [x] Auto-cleanup old backups (>30 days)

## CI/CD
- [x] Flake8 linting
- [x] Black formatting check (blocks build)
- [x] Python syntax verification (py_compile)
- [x] Unit tests (16 tests)
- [x] Docker image build (security-api)

## Load Testing
- [x] k6 load tests: P95=181ms (target <500ms) — PASSED
- [x] Error rate: 0.00% (target <10%) — PASSED
- [x] Connection pooling optimization (50 max, 20 keepalive)

## Service URLs
| Service | URL | Credentials |
|---------|-----|-------------|
| ERPNext | https://erp.riad.fun | see .env |
| Security API | https://api.riad.fun (DEFER) | see .env |

## Known Issues
- [ ] ERPNext CSS/JS asset loading через Cloudflare (потрібен `bench set-config host_name https://erp.riad.fun` + `bench build --force`)
- [ ] 70GB disk — потрібен periodic docker system prune
