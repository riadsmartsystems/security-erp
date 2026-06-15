# Security ERP Platform — План Проєкту
_Оновлено: 2026-06-15_

---

## Архітектура

**Single-Database Pattern** — всі дані в MariaDB через ERPNext DocTypes.

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Telegram Bot │────▶│ Security API │────▶│   ERPNext    │
│  @riad_ss_bot│     │   Gateway    │     │  (Frappe)    │
└──────────────┘     │   :8000      │     │  MariaDB     │
                     └──────────────┘     │  25 DocTypes │
                            │             └──────────────┘
┌──────────────┐           │
│     n8n      │◀──────────┘
│   :5678      │     PostgreSQL (тільки n8n)
└──────────────┘
```

### Контейнери (19)

| Сервіс | Порт | Призначення |
|--------|------|-------------|
| erpnext-backend | 8000 | Frappe API + бізнес-логіка |
| erpnext-frontend | 8080 | Web UI (nginx) |
| erpnext-scheduler | — | Фонові задачі |
| erpnext-worker-default | — | Queue worker |
| erpnext-worker-short | — | Short queue worker |
| erpnext-socketio | — | WebSocket |
| security-api | 8000 | API Gateway (JWT + RBAC + Proxy) |
| telegram-service | — | Telegram бот |
| n8n | 5678 | Автоматизації |
| mariadb | 3306 | БД для ERPNext |
| postgres | 5432 | БД для n8n |
| redis | 6379 | Кеш/сесії |
| minio | 9000/9001 | Файлове сховище |
| nats | 4222 | Шина подій |
| traefik | 80/443 | Reverse proxy |
| grafana | 3000 | Моніторинг дашборд |
| prometheus | 9090 | Метрики |
| loki | 3100 | Логи |
| promtail | — | Log collector |
| cloudflared | — | Cloudflare Tunnel |

---

## DocTypes (25)

### FSM (Field Service Management)
| DocType | Поля | Автонумерація |
|---------|------|---------------|
| Service Ticket | 31 | TKT-.###### |
| Visit | 20 | — |
| Visit Material | 5 | — |
| Visit Photo | 5 | — |
| SLA Event | 4 | — |
| Maintenance Plan | 8 | — |
| Warranty Case | 10 | WRN-.###### |

### CMDB (Configuration Management)
| DocType | Поля | Автонумерація |
|---------|------|---------------|
| Security Object | 15 | OBJ-.###### |
| Object Building | 5 | — |
| Object Floor | 5 | — |
| Object Room | 5 | — |
| Equipment | 20 | CI-.###### |
| Equipment Type | 5 | — |
| Equipment Relation | 7 | — |
| Vendor | 8 | — |

### ERP (Sales/Finance)
| DocType | Поля | Автонумерація |
|---------|------|---------------|
| Contract | 20 | — |
| Contract Object | 5 | — |
| Estimate | 25 | — |
| Estimate Item | 6 | — |
| Estimate Template | 8 | — |
| Estimate Template Item | 5 | — |
| Installation Act | 17 | — |
| Installation Act Item | 8 | — |
| Material Reservation | 13 | — |
| Material Reservation Item | 6 | — |

---

## API Endpoints

### Security API Gateway (:8000)
| Endpoint | Метод | Опис |
|----------|-------|------|
| `/api/v1/auth/login` | POST | JWT логін |
| `/api/v1/auth/refresh` | POST | Оновлення токену |
| `/api/v1/auth/logout` | POST | Вихід |
| `/api/v1/auth/me` | GET | Профіль |
| `/api/v1/auth/users` | GET/POST | Управління користувачами |
| `/api/v1/tickets` | CRUD | → Frappe Service Ticket |
| `/api/v1/visits` | CRUD | → Frappe Visit |
| `/api/v1/objects` | CRUD | → Frappe Security Object |
| `/api/v1/equipment` | CRUD | → Frappe Equipment |
| `/api/v1/maintenance` | CRUD | → Frappe Maintenance Plan |
| `/api/v1/warranty` | CRUD | → Frappe Warranty Case |
| `/api/v1/vendors` | CRUD | → Frappe Vendor |
| `/api/v1/public/status` | GET | Публічний статус |
| `/health` | GET | Healthcheck |

---

## Користувачі та Ролі

| Логін | Пароль | Роль | Доступ |
|-------|--------|------|--------|
| Administrator | jokerLA23 | System Manager | Повний |
| joker@riad.fun | jokerLA23 | Service Manager | FSM + CMDB |

### RBAC (Frappе Roles)
| Роль Frappe | Маппінг Security API |
|-------------|---------------------|
| System Manager | owner |
| Service Manager | service_manager |
| Projects Manager | project_manager |
| Sales Manager | sales_manager |
| Engineer | engineer |
| Warehouse Manager | warehouse |

---

## Telegram Bot @riad_ss_bot

| Команда | Опис |
|---------|------|
| /start | Головне меню з кнопками |
| /help | Довідка |
| /mytickets | Список заявок з inline кнопками |
| /newticket | 5-кроковий діалог створення заявки |
| /object | Вибір об'єкта зі списку |
| /sla | Статус SLA |
| /kpi | KPI дашборд |
| /photo | Фотозвіт (before/after/problem/equipment) |
| /materials | Додавання матеріалів |

**Inline кнопки:** Деталі, Створити виїзд, Старт виїзду, Фото, Матеріали, Завершити

---

## n8n Workflows (10)

| # | Назва | Тип | Тригер |
|---|-------|-----|--------|
| 01 | Новий Lead | Webhook | POST /webhook/new-lead |
| 02 | Прострочена КП | Schedule | Щобудня 09:00 |
| 03 | Нова заявка | Webhook | POST /webhook/new-ticket |
| 04 | SLA Breach | Webhook | POST /webhook/sla-breach |
| 05 | Emergency | Webhook | POST /webhook/emergency-ticket |
| 06 | Планове ТО | Schedule | Щопонеділка 08:00 |
| 07 | Закінченнягарантії | Schedule | Щодня 10:00 |
| 08 | Мінімальний залишок | Webhook | POST /webhook/low-stock |
| 09 | Оплата | Webhook | POST /webhook/payment-received |
| 10 | Щоденний KPI | Schedule | Щодня 08:00 |

**Паттерн:** Webhook → Function (format message) → HTTP Request (Telegram API)

---

## Cloudflare

| Субдомен | Сервіс | Доступ |
|----------|--------|--------|
| erp.riad.fun | ERPNext | Cloudflare Access OTP |
| api.riad.fun | Security API | JWT required |
| n8n.riad.fun | n8n | Basic auth |
| grafana.riad.fun | Grafana | Grafana login |

**Access OTP:** riad.smart.systems@gmail.com, jokerla23@gmail.com

---

## Backup

| Що | Метод | Частота | Зберігання |
|----|-------|---------|------------|
| MariaDB | mysqldump + gzip | Daily 2AM, Weekly Sun 3AM | 30 днів |

Скрипт: `scripts/backup-mariadb.sh`

---

## Load Testing (k6)

| Метрика | Результат | Ціль | Статус |
|---------|-----------|------|--------|
| P95 Latency | 2.94s | <500ms | ❌ FAILED |
| Error Rate | 27.86% | <10% | ❌ FAILED |
| Login Success | 61% | >99% | ❌ FAILED |
| Iterations | 574 | — | ✅ |
| HTTP Requests | 1982 | — | ✅ |

---

## Відкриті задачі

### Критичне
1. **Rate Limiting** — P95 latency 2.94s, потрібно <500ms
2. **Data Migration** — CSV → ERPNext DocTypes (Customer, Object, Equipment, Ticket)
3. **CORS** — Занадто вільний (allow_origins=*)

### Середнє
4. **n8n Webhooks** — Ручна активація після restart контейнера
5. **ERPNext CSS** — Assets не завантажуються через Cloudflare tunnel
6. **Cloudflare Access** — Вимкнено для тестування, увімкнути перед Go-Live

### Низьке пріоритетне
7. **ERPNext UI кастомізація** — Українська компанія, брендинг
8. **Mobile App** — Phase 4
9. **AI Service** — Phase 2+
10. **Neo4j** — Phase 3 (якщо >2000 об'єктів)

---

## Креденшели

| Сервіс | Логін | Пароль |
|--------|-------|--------|
| ERPNext | Administrator | jokerLA23 |
| Security API | joker@riad.fun | jokerLA23 |
| n8n | jokerla23@gmail.com | jokerLA23 |
| Grafana | joker | jokerLA23 |
| MinIO Console | minioadmin | minio_secret |
| Telegram Bot | @riad_ss_bot | — |
| MariaDB | root | mariadb_root_secret |
| PostgreSQL | postgres | postgres_root_secret |
| Redis | — | redis_secret |

---

## Директиви для AI

1. Всі дані в MariaDB через ERPNext DocTypes
2. Security API proxy до Frappe API
3. n8n використовує HTTP Request nodes (не Telegram node)
4. Ніяких окремих PostgreSQL схем для бізнес-даних
5. Контейнери FSM/CMDB/AI видалені
6. Відповіді українською
7. Працювати в `/home/joker/RIAD CRM/`
