# Security ERP Platform

Спеціалізована ERP-платформа для компаній з монтажу та сервісного обслуговування систем безпеки (CCTV, СКУД, Сигналізація, Мережі).

## Архітектура

**Єдина база даних (MariaDB)** — всі дані зберігаються в ERPNext.

- **ERPNext** — CRM, Sales, Finance, Inventory, Projects, FSM (Service Tickets, Visits, SLA), CMDB (Objects, Equipment, Topology)
- **Security API Gateway** — JWT автентифікація, RBAC, проксі до Frappe REST API
- **Telegram Service** — Бот для інженерів (створення заявок, виїзди, фото, матеріали)
- **n8n** — Автоматизації та нотифікації

## Швидкий старт

```bash
# 1. Клонувати репозиторій
git clone <repo-url>
cd "RIAD CRM"

# 2. Налаштувати змінні середовища
cp .env.example .env
# Редагуйте .env — паролі, токени, домени

# 3. Запустити
docker compose up -d

# 4. Ініціалізувати ERPNext (перший запуск)
docker compose exec erpnext-backend bench new-site erp.localhost --mariadb-root-password mariadb_root_secret --admin-password ChangeMeNow!
docker compose exec erpnext-backend bench --site erp.localhost install-app erpnext
docker compose exec erpnext-backend bench --site erp.localhost install-app security_erp
docker compose exec erpnext-backend bench --site erp.localhost set-config developer_mode 1

# 5. Створити API ключ для Security API
docker compose exec erpnext-backend bench --site erp.localhost new-api-key --user Administrator
# Додайте отримані key/secret в .env як FRAPPE_API_KEY / FRAPPE_API_SECRET
```

## Сервіси

| Сервіс | Порт | URL |
|--------|------|-----|
| ERPNext | 8080 | http://erp.localhost |
| Security API | 8000 | http://api.localhost |
| Telegram Service | — | (internal) |
| n8n | 5678 | http://localhost:5678 |
| MinIO Console | 9001 | http://localhost:9001 |
| Grafana | 3000 | http://localhost:3000 |
| Prometheus | 9090 | http://localhost:9090 |
| Traefik | 8080 | http://localhost:8080 |

## Структура проєкту

```
RIAD CRM/
├── docker-compose.yml
├── .env
├── services/
│   ├── security-api/          # API Gateway (thin proxy to Frappe)
│   └── telegram-service/      # Telegram Bot
├── erpnext/
│   └── security_erp/          # Frappe custom app (DocTypes, events, scheduled tasks)
├── configs/
│   ├── prometheus/            # Prometheus config
│   ├── grafana/               # Grafana provisioning
│   ├── loki/                  # Loki config
│   ├── promtail/              # Promtail config
│   ├── n8n/                   # n8n workflows
│   ├── traefik/               # Traefik config
│   └── cloudflared/           # Cloudflare tunnel
├── scripts/
│   ├── start.sh               # Startup script
│   ├── backup.sh              # Backup script
│   └── migration/             # Data migration scripts
├── tests/
│   └── load/                  # k6 load tests
└── docs/
```

## DocTypes (ERPNext)

### FSM (Field Service Management)
- **Service Ticket** — заявки з SLA, пріоритетами, статусами
- **Visit** — виїзди інженерів з GPS, фото, матеріалами
- **Maintenance Plan** — планове обслуговування
- **Warranty Case** — гарантійні випадки

### CMDB (Configuration Management)
- **Security Object** — об'єкти клієнтів (будівлі, адреси)
- **Equipment** — обладнання (камери, сервери, UPS)
- **Equipment Type** — типи обладнання
- **Vendor** — виробники
- **Object Building / Floor / Room** — ієрархія приміщень
- **Equipment Relation** — топологія з'єднань

## API

Всі API проксуються через Security API Gateway → Frappe REST API.

### Автентифікація
```
POST /api/v1/auth/login       — Логін (username + password)
POST /api/v1/auth/refresh     — Оновлення токену
POST /api/v1/auth/logout      — Вихід
GET  /api/v1/auth/me          — Профіль
```

### Tickets (FSM)
```
GET    /api/v1/tickets         — Список заявок
POST   /api/v1/tickets         — Створити заявку
GET    /api/v1/tickets/{id}    — Деталі заявки
POST   /api/v1/tickets/{id}/assign — Призначити інженера
POST   /api/v1/tickets/{id}/status — Змінити статус
POST   /api/v1/tickets/{id}/close  — Закрити заявку
```

### Visits (FSM)
```
GET    /api/v1/visits           — Список виїздів
POST   /api/v1/visits           — Створити виїзд
POST   /api/v1/visits/{id}/start  — GPS чекін
POST   /api/v1/visits/{id}/finish — GPS чекаут
POST   /api/v1/visits/{id}/materials — Додати матеріали
```

### Objects (CMDB)
```
GET    /api/v1/objects          — Список об'єктів
POST   /api/v1/objects          — Створити об'єкт
GET    /api/v1/objects/{id}     — Деталі об'єкта
GET    /api/v1/objects/{id}/equipment — Обладнання на об'єкті
GET    /api/v1/objects/{id}/timeline  — Сервісна історія
```

### Equipment (CMDB)
```
GET    /api/v1/equipment        — Список обладнання
POST   /api/v1/equipment        — Додати обладнання
POST   /api/v1/equipment/install — Встановити на об'єкт
GET    /api/v1/topology/{id}    — Топологія мережі
```

## Ролі (RBAC)

| Роль | CRM | Sales | Projects | FSM | CMDB | Finance |
|------|-----|-------|----------|-----|------|---------|
| Owner | Full | Full | Full | Full | Full | Full |
| Director | Read | Read | Full | Read | Read | Full |
| Sales Manager | Full | Full | Read | - | Read | Read |
| Project Manager | Read | Read | Full | Read | Full | Read |
| Service Manager | Read | - | Read | Full | Full | - |
| Engineer | - | - | Own | Own | Read | - |
| Warehouse | - | - | Read | - | Read | - |
| Accountant | Read | Read | Read | Read | - | Full |

## Моніторинг

- **Prometheus** — метрики CPU, RAM, API latency, error rate
- **Grafana** — дашборди Infrastructure, ERP Health, FSM KPI
- **Loki** — централізовані логи всіх контейнерів

## Фази розробки

- [x] Phase 1 MVP: Docker, ERPNext, FSM, CMDB, Telegram, Security API
- [x] Phase 1.5: Single-database architecture (all data in MariaDB via ERPNext)
- [ ] Phase 2: AI Search, Config Backup, Bank Integration
- [ ] Phase 3: AI Full, Predictive Maintenance, Monitoring Integration
- [ ] Phase 4: Android App, Customer Portal, BI
