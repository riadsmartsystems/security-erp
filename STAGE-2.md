# STAGE-2: Що зберегти, що видалити
_Дата аудиту: 2026-06-18_
_Джерела: docker-compose.yml (20 сервісів), services/ (5 тек), erpnext/security_erp/ (DocTypes + hooks + tasks),_
_STAGE-0.md, STAGE-1.md_

---

## 1. Перевірка дублювання: fsm-service / cmdb-service / ai-service → security_erp

### 1.1 services/fsm-service → ПОВНЕ дублювання

| Логіка в fsm-service | Де реалізовано в security_erp | Файли security_erp |
|---|---|---|
| `models/ticket.py` → клас `Ticket` (31 поле, SLA-дедлайни, статуси) | DocType `Service Ticket` (31 поле, ідентичний набір полів) | `doctype/service_ticket/service_ticket.json` |
| `models/ticket.py` → клас `Visit` (GPS чекін/чекаут, фото, матеріали) | DocType `Visit` (child table у Service Ticket) | `doctype/visit/visit.json` |
| `models/ticket.py` → клас `VisitPhoto` | DocType `Visit Photo` (child table) | `doctype/visit_photo/` |
| `models/ticket.py` → клас `VisitMaterial` | DocType `Visit Material` (child table) | `doctype/visit_material/visit_material.json` |
| `models/ticket.py` → клас `SLAEvent` | DocType `SLA Event` (child table у Service Ticket) | `doctype/sla_event/sla_event.json` |
| `models/ticket.py` → клас `MaintenancePlan` | DocType `Maintenance Plan` (у складі 25 DocTypes) | `doctype/maintenance_plan/` |
| `models/ticket.py` → клас `WarrantyCase` | DocType `Warranty Case` (7 полів, ідентичні статуси) | `doctype/warranty_case/warranty_case.json` |
| `services/sla_engine.py` → `check_sla_breaches()` + APScheduler (1 хв) | `tasks/hourly.py` → `check_sla_breaches()` (Frappe scheduler, щогодини) | `security_erp/tasks/hourly.py` |
| `services/sla_engine.py` → SLA-паузи, розрахунок порушень, NATS-сповіщення | `tasks/daily.py` → `check_sla_compliance()`, Frappe realtime замість NATS | `security_erp/tasks/daily.py` |
| `routes/checklists.py` → ChecklistTemplate | **Відсутнє** в поточних 25 DocTypes (є у планах, але JSON не знайдено) | — |
| PostgreSQL схема `fsm`, asyncpg, NATS-py | MariaDB через Frappe ORM — жодних окремих залежностей | `hooks.py`, `tasks/` |

**Висновок:** fsm-service є паралельною реалізацією тієї ж логіки в окремій БД (PostgreSQL).
`security_erp` покриває 8 з 9 сутностей та дублює SLA-рушій (буква-в-букву).
Різниця лише у частоті перевірки SLA (1 хв у fsm-service vs 1 год у security_erp) —
для Етапу 1 погодинна достатня.

---

### 1.2 services/cmdb-service → ЧАСТКОВЕ дублювання (ядро покрито, Phase 2+ — ні)

| Логіка в cmdb-service | Де реалізовано в security_erp | Покрито? |
|---|---|---|
| `models/equipment.py` → `SecurityObject` | DocType `Security Object` | ✅ |
| `models/equipment.py` → `Equipment` (serial_number, status lifecycle) | DocType `Equipment` (20 полів, ідентичний lifecycle) | ✅ |
| `models/equipment.py` → `EquipmentRelation` | DocType `Equipment Relation` | ✅ |
| `routes/objects.py` → CRUD об'єктів | Frappe REST API → Security Object | ✅ |
| Building/Floor/Room ієрархія | DocTypes `Object Building`, `Object Floor`, `Object Room` | ✅ |
| Equipment Type, Vendor | DocTypes `Equipment Type`, `Vendor` | ✅ |
| `models/equipment.py` → `PhotoDocumentation` (MinIO) | `Visit Photo` (частково), Frappe Attach | ⚠️ Частково |
| `models/equipment.py` → `ObjectTimeline` | **Відсутнє** як окремий DocType | ❌ |
| `models/equipment.py` → `ConfigBackup` / `ConfigBackupSchedule` | **Відсутнє** (Phase 2+ за архітектурою) | ❌ |
| `routes/backups.py` → резервні копії конфігурацій (Oxidized) | **Відсутнє** (Phase 2+) | ❌ |
| `routes/integrations.py` → MikroTik/UniFi API | **Відсутнє** (Phase 2+/3+) | ❌ |

**Висновок:** Ядро CMDB (об'єкти, обладнання, зв'язки, ієрархія) — повністю в security_erp.
ConfigBackup / ObjectTimeline / інтеграції — Phase 2+, поза поточним обсягом.
Для Етапу 1 cmdb-service не потрібен — security_erp покриває 100% необхідного.

---

### 1.3 services/ai-service → НЕ РЕАЛІЗОВАНО (тільки requirements.txt)

У project knowledge знайдено лише `services/ai-service/requirements.txt`
(`fastapi, asyncpg, numpy, httpx, prometheus-client`). Файли `app/main.py`,
моделі, роути — **відсутні**. Сервіс не містить жодного бізнес-коду.
В `erpnext/security_erp/` AI-логіки також немає — генерація чернетки кошторису
(AI-estimate з ТЗ) є пріоритетом Етапу 1 (за умовою задачі), але реалізована ще не в жодному місці.

**Висновок:** ai-service — порожня заглушка. Дублювання відсутнє. CUT зараз,
реалізовувати в security_erp через Frappe Python hook + Anthropic API.

---

## 2. Класифікація сервісів docker-compose.yml

| Сервіс | Рішення | Обґрунтування |
|---|---|---|
| `erpnext-frontend` | **KEEP** | Веб-UI ERPNext — єдиний інтерфейс для офісу на Етапі 1 |
| `erpnext-backend` | **KEEP** | Frappe API + бізнес-логіка, джерело правди |
| `erpnext-scheduler` | **KEEP** | Запускає SLA-задачі з `hooks.py` (hourly/daily) |
| `erpnext-worker-default` | **KEEP** | Черга задач Frappe (PDF, email, фонові операції) |
| `erpnext-worker-short` | **KEEP** | Коротка черга (realtime-оновлення, sockets) |
| `erpnext-socketio` | **KEEP** | WebSocket для live-оновлень у Frappe UI |
| `mariadb` | **KEEP** | Єдина БД, стандарт ERPNext |
| `redis` | **KEEP** | Кеш і черги ERPNext (обов'язкова залежність) |
| `traefik` | **KEEP** | Reverse proxy; потрібен для Traefik-маршрутизації ERPNext |
| `security-api` | **DEFER** | Потрібен лише для Flutter (Етап 2); конфлікт порту 8000 з backend |
| `cloudflared` | **DEFER** | Зовнішній доступ riad.fun — корисно, але не блокує Етап 1 |
| `telegram-service` | **CUT** | Явно виключений за умовою задачі |
| `n8n` | **CUT** | Явно виключений за умовою задачі |
| `postgres` | **CUT** | Існує виключно для n8n; після CUT n8n — не потрібен |
| `nats` | **CUT** | Шина подій лише для telegram-service і fsm-service (обидва CUT) |
| `minio` | **CUT** | Файлове сховище для Phase 2+; Frappe має вбудований file manager |
| `prometheus` | **CUT** | Явно виключений за умовою задачі |
| `grafana` | **CUT** | Явно виключений за умовою задачі |
| `loki` | **CUT** | Явно виключений за умовою задачі |
| `promtail` | **CUT** | Явно виключений за умовою задачі |

**Підсумок compose:** KEEP — 9, DEFER — 2, CUT — 9. Цільовий мінімальний стек: 9 контейнерів.

---

## 3. Класифікація тек services/

| Тека | Рішення | Обґрунтування |
|---|---|---|
| `services/fsm-service/` | **CUT** | Повністю продубльовано в `erpnext/security_erp/` (Service Ticket, Visit, SLA tasks) — окрема PostgreSQL-БД і NATS не потрібні |
| `services/cmdb-service/` | **CUT** | Ядро (Security Object, Equipment, Equipment Relation) повністю в security_erp; Phase 2+ функції (ConfigBackup, integrations) поза обсягом |
| `services/ai-service/` | **CUT** | Порожня заглушка без коду; AI буде реалізовано всередині security_erp як Frappe hook |
| `services/security-api/` | **DEFER** | JWT-проксі потрібен для Flutter (Етап 2); поки не запускати — конфлікт порту 8000 |
| `services/telegram-service/` | **CUT** | Явно виключений за умовою задачі |

---

## 4. Класифікація тек configs/

| Тека / файл | Рішення | Обґрунтування |
|---|---|---|
| `configs/traefik/` | **KEEP** | `dynamic.yml` потрібен для Traefik-маршрутизації ERPNext |
| `configs/cloudflared/` | **DEFER** | Потрібен лише разом з `cloudflared`-сервісом (Defer) |
| `configs/mariadb.cnf` | **KEEP** (створити) | Відсутній → Docker монтує директорію → MariaDB не стартує (STAGE-1, проблема №7) |
| `configs/n8n/` | **CUT** | Разом з n8n |
| `configs/prometheus/` | **CUT** | Разом з prometheus |
| `configs/grafana/` | **CUT** | Разом з grafana |
| `configs/loki/` | **CUT** | Разом з loki |
| `configs/promtail/` | **CUT** | Разом з promtail |

---

## 5. Фінальна зведена таблиця KEEP / CUT / DEFER

### KEEP — залишити і виправити (9 контейнерів + код)

| Що | Де |
|---|---|
| `erpnext-frontend` | `docker-compose.yml` |
| `erpnext-backend` | `docker-compose.yml` |
| `erpnext-scheduler` | `docker-compose.yml` |
| `erpnext-worker-default` | `docker-compose.yml` |
| `erpnext-worker-short` | `docker-compose.yml` |
| `erpnext-socketio` | `docker-compose.yml` |
| `mariadb` | `docker-compose.yml` |
| `redis` | `docker-compose.yml` |
| `traefik` | `docker-compose.yml` |
| Кастомний Frappe-додаток | `erpnext/security_erp/` (25 DocTypes, hooks, tasks) |
| `Dockerfile.backend` | `Dockerfile.backend` (підключити через `build:` замість `image:`) |
| `configs/traefik/` | `configs/traefik/dynamic.yml` |
| `configs/mariadb.cnf` | Потрібно **створити** (пустий або мінімальний `[mysqld]`) |
| `android-app/` | Не чіпати (Етап 2) |

### DEFER — зберегти в репо, не запускати зараз (Етап 2)

| Що | Де | Коли |
|---|---|---|
| `security-api` (сервіс) | `docker-compose.yml` | Коли Flutter-додаток готовий |
| `services/security-api/` | `services/security-api/` | Разом із сервісом |
| `cloudflared` (сервіс) | `docker-compose.yml` | Коли потрібен публічний домен |
| `configs/cloudflared/` | `configs/cloudflared/` | Разом із cloudflared |

### CUT — видалити з docker-compose.yml і репо

| Що | Де |
|---|---|
| `telegram-service` (сервіс) | `docker-compose.yml` |
| `n8n` (сервіс) | `docker-compose.yml` |
| `postgres` (сервіс) | `docker-compose.yml` |
| `nats` (сервіс) | `docker-compose.yml` |
| `minio` (сервіс) | `docker-compose.yml` |
| `prometheus` (сервіс) | `docker-compose.yml` |
| `grafana` (сервіс) | `docker-compose.yml` |
| `loki` (сервіс) | `docker-compose.yml` |
| `promtail` (сервіс) | `docker-compose.yml` |
| `services/fsm-service/` | Тека (логіка в security_erp) |
| `services/cmdb-service/` | Тека (ядро в security_erp, решта Phase 2+) |
| `services/ai-service/` | Тека (порожня заглушка) |
| `services/telegram-service/` | Тека |
| `configs/n8n/` | Тека |
| `configs/prometheus/` | Тека |
| `configs/grafana/` | Тека |
| `configs/loki/` | Тека |
| `configs/promtail/` | Тека |
| Named volumes: `minio_data`, `prometheus_data`, `grafana_data`, `loki_data`, `n8n_data`, `nats_data`, `postgres_data` | `docker-compose.yml`, секція `volumes:` |

---

## 6. Видалити негайно — конкретні команди

> ⚠️ Нічого не видалено — тільки рекомендації. Перед видаленням зробити `git commit` поточного стану.

### 6.1 Сервіси з docker-compose.yml (видалити блоки цілком)

```
telegram-service
n8n
postgres
nats
minio
prometheus
grafana
loki
promtail
```

Також видалити з секції `volumes:`:
```
minio_data
prometheus_data
grafana_data
loki_data
n8n_data
nats_data
postgres_data
```

### 6.2 Теки — видалити з репозиторію

```
services/fsm-service/       # логіка повністю в erpnext/security_erp/
services/cmdb-service/      # ядро в erpnext/security_erp/, решта Phase 2+
services/ai-service/        # порожня заглушка без коду
services/telegram-service/  # поза обсягом за умовою задачі
configs/n8n/
configs/prometheus/
configs/grafana/
configs/loki/
configs/promtail/
```

### 6.3 Скрипти — виправити або видалити рядок

```
scripts/start.sh, рядок ~14: chmod +x scripts/init-minio.sh
```
→ Видалити цей рядок (`init-minio.sh` не існує, `set -e` валить весь скрипт).

---

## 7. Що НЕ видаляти (поширена помилка)

- `erpnext/security_erp/` — єдиний реальний бізнес-код, **не чіпати**
- `services/security-api/` — потрібен для Flutter (Defer, не Cut)
- `android-app/` — Етап 2, не чіпати
- `configs/traefik/` — потрібен для ERPNext
- `configs/cloudflared/` — Defer разом із сервісом
- `Dockerfile.backend` — потрібно **підключити** в compose (`build:` замість `image:`), не видаляти
