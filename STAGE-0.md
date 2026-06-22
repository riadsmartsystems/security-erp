# STAGE-0: Аудит стану репозиторію
_Дата аудиту: 2026-06-18_
_Джерела: README.md, docker-compose.yml, Dockerfile.backend, android-app/README.md,_
_services/fsm-service/Dockerfile + requirements.txt, erpnext/security_erp/ (DocTypes JSON/PY),_
_docs/PROJECT-PLAN-v3.md, docs/go-live-checklist.md, Security_ERP_Platform_Architecture_v3.txt_

---

## 1. Таблиця компонентів

| НАЗВА | Де описаний | У docker-compose (так/ні) | KEEP / CUT / DEFER |
|---|---|---|---|
| **erpnext-frontend** | docker-compose.yml, README.md | Так | **KEEP** |
| **erpnext-backend** | docker-compose.yml, README.md | Так | **KEEP** |
| **erpnext-scheduler** | docker-compose.yml, docs/PROJECT-PLAN-v3.md | Так | **KEEP** |
| **erpnext-worker-default** | docker-compose.yml, docs/PROJECT-PLAN-v3.md | Так | **KEEP** |
| **erpnext-worker-short** | docker-compose.yml, docs/PROJECT-PLAN-v3.md | Так | **KEEP** |
| **erpnext-socketio** | docker-compose.yml | Так | **KEEP** |
| **mariadb** | docker-compose.yml, README.md | Так | **KEEP** |
| **redis** | docker-compose.yml | Так | **KEEP** (ERPNext потребує для кешу і черг) |
| **security_erp** (custom Frappe app) | erpnext/security_erp/ (25 DocTypes JSON+PY) | Ні (volume mount) | **KEEP** |
| **traefik** | docker-compose.yml, configs/traefik/ | Так | **KEEP** (reverse proxy для ERPNext) |
| **Dockerfile.backend** | Dockerfile.backend | Ні (не використовується compose) | **KEEP** (потребує підключення — див. протиріччя №4) |
| **security-api** | docker-compose.yml, services/security-api/ (FastAPI) | Так | **DEFER** (Етап 2: мобільний Flutter-клієнт) |
| **cloudflared** | docker-compose.yml, configs/cloudflared/config.yml | Так | **DEFER** (зовнішній доступ riad.fun) |
| **android-app** (Flutter) | android-app/README.md | Ні | **DEFER** (Етап 2 за умовою задачі) |
| **telegram-service** | docker-compose.yml, services/telegram-service/ | Так | **CUT** |
| **n8n** | docker-compose.yml, configs/n8n/ | Так | **CUT** |
| **postgres** | docker-compose.yml | Так | **CUT** (лише для n8n) |
| **nats** | docker-compose.yml | Так | **CUT** |
| **minio** | docker-compose.yml | Так | **CUT** |
| **prometheus** | docker-compose.yml, configs/prometheus/ | Так | **CUT** |
| **grafana** | docker-compose.yml, configs/grafana/ | Так | **CUT** |
| **loki** | docker-compose.yml, configs/loki/ | Так | **CUT** |
| **promtail** | docker-compose.yml, configs/promtail/ | Так | **CUT** |
| **services/fsm-service** | services/fsm-service/Dockerfile + requirements.txt | Ні | **CUT** |
| **services/cmdb-service** | Security_ERP_Platform_Architecture_v3.txt (тільки згадка) | Ні | **CUT** (власний код відсутній) |
| **services/ai-service** | Security_ERP_Platform_Architecture_v3.txt (тільки згадка) | Ні | **CUT** (власний код відсутній) |

Разом у docker-compose: **20 контейнерів**.
Після CUT: залишиться **7 контейнерів** (erpnext-frontend, erpnext-backend, erpnext-scheduler,
erpnext-worker-default, erpnext-worker-short, erpnext-socketio, mariadb, redis, traefik → 9).

---

## 2. Протиріччя

**П-1. «Єдина MariaDB» vs. реальний compose.**
README.md та docs/PROJECT-PLAN-v3.md декларують _"Single-Database Architecture (MariaDB — single source of truth)"_.
Однак docker-compose.yml запускає ще **PostgreSQL** (для n8n, `services: postgres:`) і **NATS** (`services: nats:`) —
два окремих сховища поза MariaDB. docs/go-live-checklist.md підтверджує: _"MariaDB healthy, NATS healthy, PostgreSQL лише для n8n"_.
Таким чином архітектура насправді має 3 data-store замість одного.

**П-2. Конфлікт порту 8000.**
І `erpnext-backend`, і `security-api` оголошують `ports: - "8000:8000"` у docker-compose.yml.
Два контейнери не можуть одночасно займати один хост-порт. Запуск `docker compose up -d` упаде з помилкою `bind: address already in use`.

**П-3. Хибний шлях монтажу кастомного додатку.**
Контейнери `erpnext-backend`, `erpnext-worker-default`, `erpnext-worker-short`, `erpnext-scheduler`
монтують `./security_erp_app:/home/frappe/frappe-bench/apps/security_erp_app`.
Реальна тека в репо — `erpnext/security_erp/`. Тека `./security_erp_app` відсутня → монтаж порожній →
додаток не інсталюється → ERPNext стартує без кастомних DocTypes.

**П-4. Dockerfile.backend не задіяний у compose.**
Файл `Dockerfile.backend` (`FROM frappe/erpnext:v15.111.0` + `pip install gunicorn gevent`) існує.
Але `erpnext-backend` у docker-compose.yml використовує директиву `image: frappe/erpnext:v15.111.0` напряму,
без `build: { dockerfile: Dockerfile.backend }`. Файл ніколи не будується і не використовується.

**П-5. «Мікросервіси видалені» — але код залишився.**
docs/PROJECT-PLAN-v3.md та docs/go-live-checklist.md стверджують:
_"FSM/CMDB/AI мікросервіси ВИДАЛЕНІ (зайві, все в Frappe)"_.
Проте `services/fsm-service/Dockerfile` і `services/fsm-service/requirements.txt` (FastAPI + SQLAlchemy + asyncpg + nats-py)
фізично присутні в репо. Для `cmdb-service` і `ai-service` власний код у project knowledge відсутній,
але папки згадуються в архітектурних документах.

**П-6. Таблиця сервісів у README неповна.**
README.md перелічує 8 сервісів (ERPNext, Security API, Telegram, n8n, MinIO, Grafana, Prometheus, Traefik).
docker-compose.yml містить **20** контейнерів. Loki, Promtail, NATS, PostgreSQL, cloudflared, erpnext-socketio,
worker-контейнери у README не згадані.

**П-7. Назва пакету: `security_erp` vs `security_erp_app`.**
Команди запуску workers у docker-compose містять:
`sed -i 's/erpnextsecurity_erp_app/erpnext/g' ... && grep -qxF 'security_erp_app' ...`.
Реальна назва пакету (за структурою `erpnext/security_erp/setup.py` і workspace JSON) — `security_erp`.
Неузгодженість у назві призводить до того, що `bench install-app security_erp_app` шукатиме неіснуючий пакет.

**П-8. go-live-checklist.md vs реальність.**
Чекліст (docs/go-live-checklist.md, датований 2026-06-17) фіксує переважну більшість пунктів як ✅:
_"MariaDB healthy, NATS healthy, security_erp встановлено, 25 DocTypes працює"_.
За умовою задачі репо **не запускається**. Чекліст відображає бажаний (або колись існуючий) стан,
а не поточний — і є недостовірним джерелом для оцінки готовності.

**П-9. android-app/pubspec.yaml — відсутній у project knowledge.**
README.md задачі вимагав прочитати `android-app/pubspec.yaml`.
Файл не потрапив у project knowledge; доступний лише `android-app/README.md`
з переліком залежностей (http, flutter_secure_storage, geolocator, image_picker, permission_handler, intl).
Фактичний вміст `pubspec.yaml` — **відсутній**.

---

## 3. Стек, який реально є

Репо побудоване на **ERPNext v15.111.0 (Frappe / Python 3.12)** з **MariaDB 10.6** як основною БД
та **Redis 7** для кешу і черг задач. Єдиний реально написаний бізнес-код —
кастомний Frappe-додаток **`security_erp`** (`erpnext/security_erp/`) з 25 DocTypes у JSON/Python,
що покривають домени FSM (Service Ticket, Visit, Warranty Case), CMDB (Security Object, Equipment)
та ERP (Estimate, EstimateTemplate, SecurityScenario, Contract, InstallationAct).
Поверх Frappe живе **`security-api`** — тонкий **FastAPI (Python)** проксі з JWT/RBAC
і ~36 ендпоінтами, що пробрасовують запити до Frappe REST API.
**`telegram-service`** — Python-бот (aiogram або python-telegram-bot), залежить від security-api і NATS.
Уся решта — стокові Docker-образи без кастомного коду:
NATS (шина подій), MinIO (файли), n8n (автоматизації) + PostgreSQL (persistence для n8n),
Prometheus + Grafana + Loki + Promtail (моніторинг), Traefik (reverse proxy), Cloudflare Tunnel.
**Flutter-додаток** (`android-app/`) має структуру екранів (login, dashboard, tickets, visits, objects, equipment)
і підключається до security-api — фактичний стан збірки невідомий (`pubspec.yaml` відсутній).
Мікросервіси `services/fsm-service` мають Dockerfile і requirements.txt, але **не підключені до compose**
і ніколи не запускалися в поточній конфігурації.
