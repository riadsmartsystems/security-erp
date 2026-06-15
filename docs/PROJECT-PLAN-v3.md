# Security ERP Platform — Спрощений План v3.0
_Оновлено: 2026-06-15 — без n8n та Telegram_

---

## Архітектура

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Android App  │────▶│ Security API │────▶│   ERPNext    │
│  (Flutter)   │     │   Gateway    │     │  MariaDB     │
└──────────────┘     │   :8000      │     │  25 DocTypes │
                     └──────────────┘     └──────────────┘
┌──────────────┐           │
│   Browser    │◀──────────┘
│ (ERPNext UI) │
└──────────────┘
```

### Контейнери (14)

| Сервіс | Порт | Призначення |
|--------|------|-------------|
| erpnext-backend | 8000 | Frappe API |
| erpnext-frontend | 8080 | Web UI |
| erpnext-scheduler | — | Фонові задачі |
| erpnext-worker-default | — | Queue worker |
| erpnext-worker-short | — | Short queue |
| erpnext-socketio | — | WebSocket |
| security-api | 8000 | API Gateway |
| mariadb | 3306 | БД |
| redis | 6379 | Кеш/сесії |
| minio | 9000 | Файли |
| nats | 4222 | Шина подій |
| traefik | 80/443 | Reverse proxy |
| grafana | 3000 | Дашборд |
| prometheus | 9090 | Метрики |
| loki | 3100 | Логи |
| promtail | — | Log collector |
| cloudflared | — | Tunnel |

### Що видалено
- ❌ n8n — складність, credential проблеми
- ❌ Telegram bot — окремий сервіс
- ❌ PostgreSQL — не потрібен без n8n

---

## DocTypes (25) — без змін

### FSM
Service Ticket, Visit, Visit Material, Visit Photo, SLA Event, Maintenance Plan, Warranty Case

### CMDB
Security Object, Object Building/Floor/Room, Equipment, Equipment Type, Equipment Relation, Vendor

### ERP
Contract, Contract Object, Estimate, Estimate Template/Item, Installation Act/Item, Material Reservation/Item

---

## API Gateway — без змін

| Endpoint | Метод | Опис |
|----------|-------|------|
| `/api/v1/auth/login` | POST | JWT логін |
| `/api/v1/tickets` | CRUD | Service Ticket |
| `/api/v1/visits` | CRUD | Visit |
| `/api/v1/objects` | CRUD | Security Object |
| `/api/v1/equipment` | CRUD | Equipment |
| `/api/v1/maintenance` | CRUD | Maintenance Plan |
| `/api/v1/warranty` | CRUD | Warranty Case |
| `/api/v1/vendors` | CRUD | Vendor |
| `/health` | GET | Healthcheck |

---

## Android App (Flutter)

### Екрани
1. **Login** — email + password → JWT token
2. **Dashboard** — KPI, активні заявки, виїзди
3. **Tickets** — список заявок, створення, фільтри
4. **Ticket Detail** — інформація, виїзди, фото, матеріали
5. **Visit** — старт/фініш з GPS, фото, матеріали
6. **Objects** — список об'єктів, обладнання
7. **Equipment** — список, деталі, гарантія
8. **Profile** — налаштування, вихід

### Функціонал
- JWT автентифікація
- Offline кешування (SQLite)
- GPS tracking для виїздів
- Camera для фото
- Push notifications (Firebase)
- QR сканер для обладнання

### Технології
- Flutter (Android + iOS)
- Dio для HTTP
- SQLite для offline
- Firebase для push notifications

---

## Нотифікації (замість n8n + Telegram)

### Варіант 1: ERPNext Scheduled Tasks
- Frappe scheduler_events для перевірки SLA
- Email нотифікації через Frappe
- Push notifications через Firebase

### Варіант 2: Simple Python Scripts
- Cron job щоходить перевіряє SLA
- HTTP запити до Firebase для push
- Email через SMTP

---

## Користувачі та RBAC — без змін

| Логін | Роль | Доступ |
|-------|------|--------|
| Administrator | System Manager | Повний |
| joker@riad.fun | Service Manager | FSM + CMDB |

---

## Cloudflare — без змін

| Субдомен | Сервіс |
|----------|--------|
| erp.riad.fun | ERPNext |
| api.riad.fun | Security API |
| grafana.riad.fun | Grafana |

---

## Backup — без змін

- MariaDB: daily 2AM, weekly Sun 3AM
- Скрипт: scripts/backup-mariadb.sh

---

## Load Testing — без змін

- k6 baseline: P95=2.94s (target <500ms)
- Потребує оптимізації

---

## Відкриті задачі

### Критичне
1. **Rate Limiting** — P95 latency оптимізація
2. **Data Migration** — CSV → ERPNext
3. **CORS** — Налаштування для production

### Android App
4. **Flutter проект** — Створити базовий додаток
5. **Login screen** — JWT автентифікація
6. **Dashboard** — KPI відображення
7. **Tickets list** — Список заявок
8. **Visit flow** — Старт/фініш з GPS
9. **Photo upload** — Камера + завантаження

### ERPNext
10. **UI кастомізація** — Український брендинг
11. **Cloudflare Access** — Увімкнути для production

---

## Креденшели — без змін

| Сервіс | Логін | Пароль |
|--------|-------|--------|
| ERPNext | Administrator | jokerLA23 |
| Security API | joker@riad.fun | jokerLA23 |
| Grafana | joker | jokerLA23 |
| MinIO | minioadmin | minio_secret |
| MariaDB | root | mariadb_root_secret |
| Redis | — | redis_secret |

---

## Директиви для AI

1. Всі дані в MariaDB через ERPNext DocTypes
2. Security API proxy до Frappe API
3. Немає n8n, немає Telegram
4. Android додаток використовує Security API
5. Нотифікації через ERPNext або Firebase
6. Відповіді українською
7. Працювати в `/home/joker/RIAD CRM/`
