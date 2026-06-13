# Security ERP Platform

Спеціалізована ERP-платформа для компаній з монтажу та сервісного обслуговування систем безпеки (CCTV, СКУД, Сигналізація, Мережі).

## Архітектура

- **ERPNext** — CRM, Sales, Finance, Inventory, Projects
- **Security API Gateway** — JWT, RBAC, Circuit Breaker, Routing
- **FSM Service** — Tickets, Visits, SLA Engine, Warranty
- **CMDB Service** — Objects, Equipment, Topology, Digital Twin
- **Telegram Service** — Bot для інженерів
- **n8n** — Автоматизації та нотифікації

## Швидкий старт

```bash
# 1. Клонувати репозиторій
git clone <repo-url>
cd security-erp

# 2. Налаштувати змінні середовища
cp .env.example .env
# Редагуйте .env — паролі, токени, домени

# 3. Запустити
docker compose up -d

# 4. Ініціалізувати ERPNext (перший запуск)
docker compose exec erpnext-backend bench new-site erp.localhost --mariadb-root-password mariadb_root_secret --admin-password ChangeMeNow!
docker compose exec erpnext-backend bench --site erp.localhost install-app erpnext
docker compose exec erpnext-backend bench --site erp.localhost set-config developer_mode 1
```

## Сервіси

| Сервіс | Порт | URL |
|--------|------|-----|
| ERPNext | 8080 | http://erp.localhost |
| Security API | 8000 | http://api.localhost |
| FSM Service | 8001 | http://localhost:8001 |
| CMDB Service | 8002 | http://localhost:8002 |
| Telegram Service | 8003 | http://localhost:8003 |
| n8n | 5678 | http://localhost:5678 |
| MinIO Console | 9001 | http://localhost:9001 |
| Grafana | 3000 | http://localhost:3000 |
| Prometheus | 9090 | http://localhost:9090 |
| Traefik | 8080 | http://localhost:8080 |

## Структура проєкту

```
security-erp/
├── docker-compose.yml
├── .env
├── services/
│   ├── security-api/          # API Gateway
│   ├── fsm-service/           # Field Service Management
│   ├── cmdb-service/          # Configuration Management DB
│   └── telegram-service/      # Telegram Bot
├── configs/
│   ├── postgres/init/         # PostgreSQL initialization
│   ├── prometheus/            # Prometheus config
│   ├── grafana/               # Grafana provisioning
│   ├── loki/                  # Loki config
│   └── promtail/              # Promtail config
├── scripts/
│   ├── start.sh               # Startup script
│   └── init-minio.sh          # MinIO bucket initialization
├── tests/
└── docs/
```

## Бази даних

| БД | Призначення | Схеми |
|----|-------------|-------|
| MariaDB | ERPNext | erpnext |
| PostgreSQL | Мікросервіси | fsm, cmdb, ai, integration, audit |

## API

### Автентифікація
```
POST /api/v1/auth/login       — Логін (username + password)
POST /api/v1/auth/refresh     — Оновлення токену
POST /api/v1/auth/logout      — Вихід
GET  /api/v1/me               — Профіль
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

## Тест NATS-нотифікацій (Telegram/Viber)

Усе працює через Docker: `telegram-service` підписаний на `notifications.send` та `fsm.sla.breached`.

1) Додайте змінні в `.env`:

```env
VIBER_BOT_TOKEN=your_viber_bot_token
NOTIFICATION_TELEGRAM_CHAT_IDS=123456789
NOTIFICATION_VIBER_USER_IDS=VIBER_USER_ID
```

2) Запустіть швидкий end-to-end тест однією командою:

```bash
./scripts/test_notifications.sh
```

Або передайте IDs явно:

```bash
./scripts/test_notifications.sh --telegram-ids "123456789" --viber-ids "VIBER_USER_ID"
```

3) Ручний тест окремих подій з контейнера:

```bash
# 1) Кастомне повідомлення у Telegram + Viber
docker compose exec -T telegram-service python scripts/publish_notification.py \
  --subject notifications.send \
  --channels telegram viber \
  --message "Тестова розсилка з NATS" \
  --telegram-ids "123456789" \
  --viber-ids "VIBER_USER_ID"

# 2) Тест автоматичного SLA breach-алерту
docker compose exec -T telegram-service python scripts/publish_notification.py \
  --subject fsm.sla.breached \
  --ticket-number "TCK-2026-001" \
  --sla-type resolution \
  --priority critical
```

## Фази розробки

- [x] Phase 1 MVP: Docker, ERPNext, FSM, CMDB, Telegram, Security API
- [ ] Phase 2: AI Search, Config Backup, Bank Integration
- [ ] Phase 3: AI Full, Predictive Maintenance, Monitoring Integration
- [ ] Phase 4: Android App, Customer Portal, BI
