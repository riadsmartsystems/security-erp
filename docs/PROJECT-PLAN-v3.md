# Security ERP Platform — Архітектура v4.0
_Оновлено: 2026-06-17 — після аудиту_

---

## Архітектура

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Android App  │────▶│ Security API │────▶│   ERPNext    │
│  (Flutter)   │     │   Gateway    │     │  MariaDB     │
└──────────────┘     │   :8000      │     │  25 DocTypes │
                     └──────────────┘     └──────────────┘
┌──────────────┐           │                    │
│   Browser    │◀──────────┘                    │
│ (ERPNext UI) │                               │
└──────────────┘                               │
┌──────────────┐     ┌──────────────┐          │
│ Telegram Bot │────▶│   Security   │◀─────────┘
│              │     │     API      │
└──────────────┘     └──────────────┘
┌──────────────┐
│     n8n      │◀─── PostgreSQL (тільки для n8n)
│  Workflows   │
└──────────────┘
```

### Контейнери (20)

| Сервіс | Порт | Призначення |
|--------|------|-------------|
| erpnext-backend | 8000 | Frappe API |
| erpnext-frontend | 8080 | Web UI |
| erpnext-scheduler | — | Фонові задачі |
| erpnext-worker-default | — | Queue worker |
| erpnext-worker-short | — | Short queue |
| erpnext-socketio | — | WebSocket |
| security-api | 8000 | API Gateway (JWT, RBAC, Proxy) |
| telegram-service | — | Telegram/Viber бот |
| n8n | 5678 | Automation workflows |
| postgres | 5432 | Тільки для n8n |
| mariadb | 3306 | БД (джерело правди) |
| redis | 6379 | Кеш/сесії/rate limiting |
| minio | 9000 | Файли |
| nats | 4222 | Шина подій |
| traefik | 80/443 | Reverse proxy |
| grafana | 3000 | Дашборд |
| prometheus | 9090 | Метрики |
| loki | 3100 | Логи |
| promtail | — | Log collector |
| cloudflared | — | Tunnel |

### Архітектурне рішення: Варіант A (Simple)
- Всі дані в MariaDB через ERPNext DocTypes
- PostgreSQL тільки для n8n (workflow persistence)
- Security API — тонкий proxy + JWT + RBAC
- FSM/CMDB/AI мікросервіси видалені (зайві, все в Frappe)

---

## DocTypes (25)

### FSM
Service Ticket, Visit, Visit Material, Visit Photo, SLA Event, Maintenance Plan, Warranty Case

### CMDB
Security Object, Object Building/Floor/Room, Equipment, Equipment Type, Equipment Relation, Vendor

### ERP
Contract, Contract Object, Estimate, Estimate Template/Item, Installation Act/Item, Material Reservation/Item

---

## API Gateway

### v2 Endpoints (doctypes.py — основні)
| Endpoint | Метод | Опис |
|----------|-------|------|
| `/api/v2/tickets` | CRUD | Service Ticket |
| `/api/v2/objects` | CRUD | Security Object |
| `/api/v2/equipment` | CRUD | Equipment |
| `/api/v2/customers` | CRUD | Customer |
| `/api/v2/leads` | CRUD | Lead |
| `/api/v2/stats` | GET | Агреговані метрики |
| `/api/v2/settings` | GET/PUT | Налаштування |
| `/api/v2/quotation` | POST | Створення пропозиції |
| `/api/v2/scenarios` | GET | Сценарії оцінки |
| `/api/v2/warranty/*` | GET/POST | Гарантійні картки |
| `/api/v2/pricing/*` | GET | Розрахунок цін |

### v1 Proxy Endpoints (proxy.py → Frappe)
| Endpoint | DocType |
|----------|---------|
| `/api/v1/tickets` | Service Ticket |
| `/api/v1/visits` | Visit |
| `/api/v1/objects` | Security Object |
| `/api/v1/equipment` | Equipment |
| `/api/v1/maintenance` | Maintenance Plan |
| `/api/v1/warranty` | Warranty Case |
| `/api/v1/vendors` | Vendor |

### Visit Action Endpoints (visits.py)
| Endpoint | Опис |
|----------|------|
| `POST /api/v1/visits/{id}/start` | GPS checkin |
| `POST /api/v1/visits/{id}/finish` | GPS checkout |
| `POST /api/v1/visits/{id}/materials` | Додати матеріал |
| `POST /api/v1/visits/{id}/photos` | Upload фото |

---

## Android App (Flutter)

### Екрани
1. **Login** — email + password → JWT token, FlutterSecureStorage
2. **Dashboard** — KPI з підписами, pull-to-refresh
3. **Tickets** — priority icons (warning/arrow_up/remove/arrow_down), створення
4. **Ticket Detail** — інформація, виїзди по ticket_id
5. **Visit Flow** — підтвердження перед start/finish, GPS, фото, матеріали
6. **Objects** — список об'єктів
7. **Equipment** — Material Icons статусів, серійні номери

### Функціонал
- JWT автентифікація (15 min access, 7d refresh)
- FlutterSecureStorage для паролів
- GPS tracking для виїздів
- Camera для фото з типами (before/after/problem/equipment)
- Dark theme (ThemeMode.system)
- Material 3 design

---

## Telegram Bot

### Команди
/start, /help, /mytickets, /newticket (5 кроків), /object, /sla, /kpi

### Callbacks
ticket_*, accept_*, vstart_*, vfinish_*, newvisit_*, photo_*, phototype_*, mat_*, addmat_*

---

## n8n Workflows (10)

| Workflow | Тип | Опис |
|----------|-----|------|
| wf-01-new-lead | Webhook | Новий lead → Telegram |
| wf-02-overdue-quotation | Scheduler | Прострочені пропозиції |
| wf-03-new-ticket | Webhook | Нова заявка → Telegram |
| wf-04-sla-breach | Webhook | Порушення SLA → Telegram |
| wf-05-emergency-ticket | Webhook | Критична заявка → Telegram |
| wf-06-maintenance-reminder | Scheduler | Нагадування ТО |
| wf-07-warranty-expiry | Scheduler | Закінчення гарантії |
| wf-08-low-stock | Webhook | Мало товарів на складі |
| wf-09-payment-received | Webhook | Отримано оплату |
| wf-10-daily-kpi | Scheduler | Щоденний KPI звіт (inactive) |

---

## Security

### Виконано
- [x] JWT (15 min access, 7d refresh)
- [x] RBAC (9 ролей)
- [x] Rate limiting (Redis, 1000 req/min)
- [x] CORS (specific origins)
- [x] 0 hardcoded credentials в коді
- [x] Bandit security scan (CI)
- [x] Connection pooling (50 max, 20 keepalive)

### Продакшн credentials
Всі в `.env` файлі (gitignored). Не в коді.

---

## Performance

| Метрика | До | Після | Budget |
|---------|-----|-------|--------|
| P95 latency | 2.94s | 181ms | <500ms ✅ |
| Error rate | 27.86% | 0.00% | <10% ✅ |
| Login success | 61% | 100% | 100% ✅ |

### Оптимізації
1. httpx connection pooling (50 max, 20 keepalive)
2. Rate limiting middleware
3. Response timing header
4. Proper client lifecycle (lifespan cleanup)

---

## CI/CD Pipeline

1. Flake8 linting
2. Black formatting (blocks build)
3. Python syntax verification (py_compile)
4. Unit tests (16 tests)
5. Docker image build

---

## Deployment

### Cloudflare CSS/JS Fix
```bash
bench set-config host_name https://erp.riad.fun
bench build --force
docker restart erpnext-frontend
```

### Data Migration
```bash
cd scripts/migration
export FRAPPE_HOST=localhost:80
export FRAPPE_PASSWORD=<password>
python migrate_all.py --waves 1,2,3,4
```

### Docker System Prune
```bash
docker system prune -a --volumes
docker compose up -d
```
