# Security ERP Platform — Повний План Проєкту v2.0
_Оновлено: 2026-06-15 на основі аналізу архітектури v3.0 та GitHub рішень_

---

## 1. Вступ

### 1.1 Мета
Спеціалізована ERP-платформа для компаній, що займаються монтажем та сервісним обслуговуванням систем безпеки (CCTV, СКУД, Сигналізація, Мережі).

### 1.2 Поточний стан
- ✅ Single-database архітектура (MariaDB через ERPNext DocTypes)
- ✅ 25 DocTypes створено та працює
- ✅ Security API Gateway з JWT/RBAC
- ✅ Telegram бот @riad_ss_bot
- ✅ n8n автоматизації (10 workflows)
- ✅ Моніторинг (Prometheus + Grafana + Loki)
- ✅ Cloudflare Tunnel на riad.fun
- ⚠️ Load testing показав проблеми (P95=2.94s)
- ❌ Data Migration не виконано

---

## 2. Архітектура

### 2.1 Single-Database Pattern

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│ Telegram Bot │────▶│ Security API │────▶│   ERPNext    │
│  @riad_ss_bot│     │   Gateway    │     │  (Frappe)    │
└──────────────┘     │   :8000      │     │  MariaDB     │
                     └──────────────┘     │  25 DocTypes │
┌──────────────┐           │             └──────────────┘
│     n8n      │◀──────────┘
│   :5678      │     PostgreSQL (тільки n8n)
└──────────────┘
```

### 2.2 Контейнери (19)

| Сервіс | Порт | Призначення |
|--------|------|-------------|
| erpnext-backend | 8000 | Frappe API |
| erpnext-frontend | 8080 | Web UI |
| erpnext-scheduler | — | Фонові задачі |
| erpnext-worker-default | — | Queue worker |
| erpnext-worker-short | — | Short queue |
| erpnext-socketio | — | WebSocket |
| security-api | 8000 | API Gateway |
| telegram-service | — | Telegram бот |
| n8n | 5678 | Автоматизації |
| mariadb | 3306 | БД ERPNext |
| postgres | 5432 | БД n8n |
| redis | 6379 | Кеш/сесії |
| minio | 9000 | Файли |
| nats | 4222 | Шина подій |
| traefik | 80/443 | Reverse proxy |
| grafana | 3000 | Дашборд |
| prometheus | 9090 | Метрики |
| loki | 3100 | Логи |
| promtail | — | Log collector |
| cloudflared | — | Tunnel |

---

## 3. Доменна модель (25 DocTypes)

### 3.1 FSM (Field Service Management)

| DocType | Поля | Нумерація | Опис |
|---------|------|-----------|------|
| Service Ticket | 31 | TKT-.###### | Сервісна заявка |
| Visit | 20 | — | Виїзд інженера |
| Visit Material | 5 | — | Використані матеріали |
| Visit Photo | 5 | — | Фотозвіт |
| SLA Event | 4 | — | Події SLA |
| Maintenance Plan | 8 | — | План ТО |
| Warranty Case | 10 | WRN-.###### | Гарантійний випадок |

### 3.2 CMDB (Configuration Management)

| DocType | Поля | Нумерація | Опис |
|---------|------|-----------|------|
| Security Object | 15 | OBJ-.###### | Об'єкт безпеки |
| Object Building | 5 | — | Будівля |
| Object Floor | 5 | — | Поверх |
| Object Room | 5 | — | Кімната |
| Equipment | 20 | CI-.###### | Обладнання |
| Equipment Type | 5 | — | Тип обладнання |
| Equipment Relation | 7 | — | Зв'язки обладнання |
| Vendor | 8 | — | Постачальник |

### 3.3 ERP (Sales/Finance)

| DocType | Поля | Нумерація | Опис |
|---------|------|-----------|------|
| Contract | 20 | — | Договір |
| Contract Object | 5 | — | Об'єкт договору |
| Estimate | 25 | — | Кошторис |
| Estimate Item | 6 | — | Позиція кошторису |
| Estimate Template | 8 | — | Шаблон кошторису |
| Estimate Template Item | 5 | — | Позиція шаблону |
| Installation Act | 17 | — | Акт монтажу |
| Installation Act Item | 8 | — | Позиція акту |
| Material Reservation | 13 | — | Резервування |
| Material Reservation Item | 6 | — | Позиція резервування |

---

## 4. API Gateway (28+ endpoints)

### 4.1 Auth
| Endpoint | Метод | Опис |
|----------|-------|------|
| `/api/v1/auth/login` | POST | JWT логін |
| `/api/v1/auth/refresh` | POST | Оновлення токену |
| `/api/v1/auth/logout` | POST | Вихід |
| `/api/v1/auth/me` | GET | Профіль |
| `/api/v1/auth/users` | GET/POST | Управління користувачами |

### 4.2 Business (proxy → Frappe)
| Endpoint | Метод | DocType |
|----------|-------|---------|
| `/api/v1/tickets` | CRUD | Service Ticket |
| `/api/v1/visits` | CRUD | Visit |
| `/api/v1/objects` | CRUD | Security Object |
| `/api/v1/equipment` | CRUD | Equipment |
| `/api/v1/maintenance` | CRUD | Maintenance Plan |
| `/api/v1/warranty` | CRUD | Warranty Case |
| `/api/v1/vendors` | CRUD | Vendor |

### 4.3 Public
| Endpoint | Метод | Опис |
|----------|-------|------|
| `/api/v1/public/status` | GET | Статус системи |
| `/health` | GET | Healthcheck |

---

## 5. Користувачі та RBAC

### 5.1 Облікові записи
| Логін | Пароль | Роль | Доступ |
|-------|--------|------|--------|
| Administrator | jokerLA23 | System Manager | Повний |
| joker@riad.fun | jokerLA23 | Service Manager | FSM + CMDB |

### 5.2 Маппінг ролей
| Frappe Role | Security API Role | Доступ |
|-------------|-------------------|--------|
| System Manager | owner | Все |
| Service Manager | service_manager | FSM + CMDB |
| Projects Manager | project_manager | Projects + CMDB |
| Sales Manager | sales_manager | CRM + Sales |
| Engineer | engineer | FSM (own) |
| Warehouse Manager | warehouse | Inventory |
| Accounts Manager | accountant | Finance |

---

## 6. Telegram Bot @riad_ss_bot

### 6.1 Команди
| Команда | Опис | Тип |
|---------|------|-----|
| /start | Головне меню | Reply keyboard |
| /help | Довідка | — |
| /mytickets | Список заявок | Inline buttons |
| /newticket | Створення заявки | 5-кроковий діалог |
| /object | Вибір об'єкта | Inline buttons |
| /sla | Статус SLA | — |
| /kpi | KPI дашборд | — |
| /photo | Фотозвіт | Вибір типу |
| /materials | Матеріали | Inline або ручний |

### 6.2 Inline кнопки
- Деталі заявки → повна інформація
- Створити виїзд → Visit creation
- Старт виїзду → GPS checkin
- Фото → before/after/problem/equipment
- Матеріали → з каталогу або ручний ввід
- Завершити виїзд → GPS checkout

---

## 7. n8n Workflows (10)

| # | Назва | Тип | Тригер | Дія |
|---|-------|-----|--------|-----|
| 01 | Новий Lead | Webhook | POST /webhook/new-lead | Telegram |
| 02 | Прострочена КП | Schedule | Щобудня 09:00 | Telegram |
| 03 | Нова заявка | Webhook | POST /webhook/new-ticket | Telegram |
| 04 | SLA Breach | Webhook | POST /webhook/sla-breach | Telegram |
| 05 | Emergency | Webhook | POST /webhook/emergency-ticket | Telegram |
| 06 | Планове ТО | Schedule | Щопонеділка 08:00 | Telegram |
| 07 | Закінченнягарантії | Schedule | Щодня 10:00 | Telegram |
| 08 | Мінімальний залишок | Webhook | POST /webhook/low-stock | Telegram |
| 09 | Оплата | Webhook | POST /webhook/payment-received | Telegram |
| 10 | Щоденний KPI | Schedule | Щодня 08:00 | Telegram |

**Паттерн:** Webhook/Schedule → Function (format) → HTTP Request (Telegram API)

---

## 8. Cloudflare

| Субдомен | Сервіс | Доступ |
|----------|--------|--------|
| erp.riad.fun | ERPNext | Access OTP |
| api.riad.fun | Security API | JWT |
| n8n.riad.fun | n8n | Basic auth |
| grafana.riad.fun | Grafana | Grafana login |

---

## 9. Backup

| Що | Метод | Частота | Зберігання |
|----|-------|---------|------------|
| MariaDB | mysqldump + gzip | Daily 2AM | 30 днів |
| MariaDB | mysqldump + gzip | Weekly Sun 3AM | 30 днів |

Скрипт: `scripts/backup-mariadb.sh`

---

## 10. Load Testing (k6)

| Метрика | Результат | Ціль | Статус |
|---------|-----------|------|--------|
| P95 Latency | 2.94s | <500ms | ❌ |
| Error Rate | 27.86% | <10% | ❌ |
| Login Success | 61% | >99% | ❌ |
| Iterations | 574 | — | ✅ |

---

## 11. Рекомендації з GitHub

### 11.1 Beveren FSM (github.com/Beveren-Software-Inc/Field_Service_Management)
Готовий open-source FSM для ERPNext:
- Service Request → Service Order → Appointments → Execution → Invoice
- React 19 + TypeScript + Tailwind CSS
- Technician Scheduling & Dispatch
- Spare Parts tracking

**Рекомендація:** Встановити Beveren FSM замість кастомних FSM DocTypes.

### 11.2 Frappe CRM (github.com/frappe/crm)
Офіційний CRM додаток від Frappe:
- Lead, Opportunity, Quotation Pipeline
- Email integration
- Custom fields

### 11.3 awesome-frappe (github.com/gavindsouza/awesome-frappe)
Колекція Frappe додатків:
- Expenses, Helpdesk, Insights
- Builder, Print Designer
- LMS, Gameplan, Wiki

---

## 12. Відкриті задачі

### Критичне
1. **Data Migration** — CSV → ERPNext DocTypes
2. **Rate Limiting** — P95 latency оптимізація
3. **CORS** — Налаштування для production

### Середнє
4. **n8n Webhooks** — Автоматична активація
5. **ERPNext CSS** — Assets через Cloudflare
6. **Cloudflare Access** — Увімкнути для production

### Низьке пріоритетне
7. **Beveren FSM** — Встановити готовий FSM додаток
8. **ERPNext UI** — Український брендинг
9. **Mobile App** — Phase 4
10. **AI Service** — Phase 2+

---

## 13. Креденшели

| Сервіс | Логін | Пароль |
|--------|-------|--------|
| ERPNext | Administrator | jokerLA23 |
| Security API | joker@riad.fun | jokerLA23 |
| n8n | jokerla23@gmail.com | jokerLA23 |
| Grafana | joker | jokerLA23 |
| MinIO | minioadmin | minio_secret |
| Telegram | @riad_ss_bot | — |
| MariaDB | root | mariadb_root_secret |
| PostgreSQL | postgres | postgres_root_secret |
| Redis | — | redis_secret |

---

## 14. Директиви для AI

1. Всі дані в MariaDB через ERPNext DocTypes
2. Security API proxy до Frappe API
3. n8n використовує HTTP Request nodes
4. Ніяких окремих PostgreSQL схем для бізнес-даних
5. Контейнери FSM/CMDB/AI видалені
6. Відповіді українською
7. Працювати в `/home/joker/RIAD CRM/`
8. Не створювати дублікати DocTypes
9. Перевіряти існуючі таблиці перед створенням
10. Використовувати `bench migrate` для змін схеми
