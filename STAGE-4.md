# STAGE-4: Мінімальний робочий зріз
_Дата: 2026-06-18_
_Спирається на: STAGE-1.md, STAGE-2.md, STAGE-3.md_

> **Мета цього етапу:** запустити один наскрізний потік у ERPNext без AI та без мобілки.
> AI-чернетка кошторису тимчасово замінюється ручним введенням позицій.

---

## 1. Що видалити зараз

### 1.1 Сервіси з docker-compose.yml — видалити блоки цілком

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

Після видалення сервісів прибрати також секцію `volumes:` (наприкінці файлу):

```
minio_data
prometheus_data
grafana_data
loki_data
n8n_data
nats_data
postgres_data
```

### 1.2 Теки — git rm -r

```bash
git rm -r services/fsm-service/
git rm -r services/cmdb-service/
git rm -r services/ai-service/
git rm -r services/telegram-service/
git rm -r configs/n8n/
git rm -r configs/prometheus/
git rm -r configs/grafana/
git rm -r configs/loki/
git rm -r configs/promtail/
```

### 1.3 Рядок у scripts/start.sh — видалити один рядок

```
# Видалити (або закоментувати) цей рядок (~14):
chmod +x scripts/init-minio.sh
```

При `set -e` цей `chmod` на неіснуючий файл валить весь скрипт до `docker compose up`.

### 1.4 Рядок у .gitignore — виправити

```
# Поточний рядок (хибний — ігнорує тільки security_erp_app/, не security_erp/):
security_erp_app/

# Замінити на:
# (видалити рядок security_erp_app/ — тека більше не потрібна)
```

---

## 2. Мінімальний набір сервісів нового docker-compose

Рівно **9 контейнерів** (ERPNext-стек + MariaDB + Redis + Traefik):

| Сервіс | Образ / Build | Призначення |
|---|---|---|
| `mariadb` | `mariadb:10.6` | Єдина БД |
| `redis` | `redis:7-alpine` | Кеш + черги ERPNext |
| `erpnext-backend` | `build: Dockerfile.backend` | Frappe API, бізнес-логіка |
| `erpnext-frontend` | `frappe/erpnext:v15.111.0` | Nginx + статика ERPNext |
| `erpnext-worker-default` | `frappe/erpnext:v15.111.0` | Черга задач (PDF, email) |
| `erpnext-worker-short` | `frappe/erpnext:v15.111.0` | Коротка черга (realtime) |
| `erpnext-scheduler` | `frappe/erpnext:v15.111.0` | Cron-задачі (SLA, warranty) |
| `erpnext-socketio` | `frappe/erpnext:v15.111.0` | WebSocket live-оновлення |
| `traefik` | `traefik:v2.10` | Reverse proxy |

> **MinIO не потрібен на Етапі 1.** Frappe має вбудований file manager (прикріплення файлів до DocType),
> якого достатньо для КП-PDF і Акту. MinIO — Етап 2+.
>
> **security-api і cloudflared** — DEFER, залишаються в репо, але не запускаються.

### Мінімальний docker-compose.yml

```yaml
version: "3.8"

x-erpnext-common: &erpnext-common
  image: frappe/erpnext:v15.111.0
  restart: unless-stopped
  volumes:
    - ./erpnext/security_erp:/home/frappe/frappe-bench/apps/security_erp
    - erpnext_sites:/home/frappe/frappe-bench/sites
  environment:
    - FRAPPE_SITE_NAME_HEADER=${SITE_NAME}

services:

  # ── Дані ─────────────────────────────────────────────

  mariadb:
    image: mariadb:10.6
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
    volumes:
      - mariadb_data:/var/lib/mysql
      - ./configs/mariadb.cnf:/etc/mysql/conf.d/custom.cnf:ro
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      start_period: 30s
      interval: 10s
      timeout: 5s
      retries: 10

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 3s
      retries: 5

  # ── ERPNext ──────────────────────────────────────────

  erpnext-backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    restart: unless-stopped
    volumes:
      - ./erpnext/security_erp:/home/frappe/frappe-bench/apps/security_erp
      - erpnext_sites:/home/frappe/frappe-bench/sites
    environment:
      - FRAPPE_SITE_NAME_HEADER=${SITE_NAME}
    depends_on:
      mariadb:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD-SHELL", "curl -sf http://localhost:8000/api/method/ping || exit 1"]
      start_period: 120s
      interval: 15s
      timeout: 5s
      retries: 10

  erpnext-frontend:
    <<: *erpnext-common
    command: nginx-entrypoint.sh
    depends_on:
      erpnext-backend:
        condition: service_healthy
    ports:
      - "8080:8080"

  erpnext-worker-default:
    <<: *erpnext-common
    command: bench worker --queue default
    depends_on:
      erpnext-backend:
        condition: service_healthy

  erpnext-worker-short:
    <<: *erpnext-common
    command: bench worker --queue short
    depends_on:
      erpnext-backend:
        condition: service_healthy

  erpnext-scheduler:
    <<: *erpnext-common
    command: bench schedule
    depends_on:
      erpnext-backend:
        condition: service_healthy

  erpnext-socketio:
    <<: *erpnext-common
    command: node /home/frappe/frappe-bench/apps/frappe/socketio.js
    depends_on:
      erpnext-backend:
        condition: service_healthy

  # ── Proxy ────────────────────────────────────────────

  traefik:
    image: traefik:v2.10
    restart: unless-stopped
    command:
      - "--providers.docker=true"
      - "--providers.docker.exposedbydefault=false"
      - "--providers.file.directory=/etc/traefik/dynamic"
      - "--entrypoints.web.address=:80"
    ports:
      - "80:80"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - ./configs/traefik:/etc/traefik/dynamic:ro

volumes:
  mariadb_data:
  redis_data:
  erpnext_sites:
```

---

## 3. Покроковий план «від чистого клону до робочого ERPNext»

### Крок 0. Початковий стан репо

```bash
git clone <repo-url> security-erp && cd security-erp
# Переконайтеся, що тека erpnext/security_erp/ існує:
ls erpnext/security_erp/security_erp/hooks.py   # має бути файл
```

Якщо `erpnext/security_erp/` відсутня — її потрібно повернути з git history
або отримати від розробника (вона реальний бізнес-код проєкту).

---

### Крок 1. Виправити P0-блокер у коді застосунку

**Файл `erpnext/security_erp/security_erp/permissions.py` — відсутній.**
`hooks.py` посилається на `security_erp.permissions.contract_has_permission` →
при відкритті будь-якого `Contract` ERPNext кидатиме `ImportError`.

Створити файл:

```bash
cat > erpnext/security_erp/security_erp/permissions.py << 'EOF'
import frappe


def contract_has_permission(doc, user=None, permission_type=None):
    """
    Custom permission check for Contract doctype.
    Returns True to allow access if user has standard 'read' permission on Contract.
    """
    if not user:
        user = frappe.session.user

    if frappe.has_permission("Contract", ptype=permission_type or "read", user=user):
        return True

    return False
EOF
```

---

### Крок 2. Створити configs/mariadb.cnf

Відсутній файл → Docker монтує директорію замість файлу → MariaDB не стартує
(STAGE-1, проблема №7).

```bash
mkdir -p configs
cat > configs/mariadb.cnf << 'EOF'
[mysqld]
character-set-server = utf8mb4
collation-server     = utf8mb4_unicode_ci
innodb_buffer_pool_size = 512M
innodb_log_file_size    = 128M
EOF
```

---

### Крок 3. Створити .env.example і .env

`.env.example` відсутній у репо (STAGE-1, проблема №3). Зберегти у версію
контролю `.env.example`; у `.gitignore` додати тільки `.env`.

```bash
cat > .env.example << 'EOF'
# ── MariaDB ──────────────────────────────────────────────────────────────────
# Пароль root-користувача MariaDB (використовується bench для створення БД)
MYSQL_ROOT_PASSWORD=changeme_root

# ── ERPNext Site ─────────────────────────────────────────────────────────────
# Ім'я сайту Frappe (доменне або erp.localhost для локальної розробки)
SITE_NAME=erp.localhost

# Пароль адміністратора ERPNext UI (логін: Administrator)
ADMIN_PASSWORD=changeme_admin

# ── Traefik / Domain ─────────────────────────────────────────────────────────
# Публічний домен (для Traefik-маршрутизації)
# Для локальної розробки залишити erp.localhost
DOMAIN=erp.localhost
EOF

# Скопіювати в реальний .env і одразу змінити паролі
cp .env.example .env
# Відредагувати .env — замінити changeme_* на реальні значення
```

> **Важливо:** `.env` вже є в `.gitignore` — не комітити. `.env.example` — комітити обов'язково.

---

### Крок 4. Замінити docker-compose.yml

Повністю замінити поточний `docker-compose.yml` на версію з розділу 2.
(20 контейнерів → 9, виправлені шляхи та назви пакету.)

```bash
# Перед заміною — зберегти поточний стан
git add -A && git commit -m "chore: pre-stage4 state before cleanup"

# Далі замінити docker-compose.yml вручну або через editor
```

---

### Крок 5. Перевірити Dockerfile.backend

```bash
cat Dockerfile.backend
```

Має виглядати так (якщо відрізняється — привести до цього вигляду):

```dockerfile
FROM frappe/erpnext:v15.111.0

# Gunicorn + gevent для production-режиму bench serve
RUN pip install gunicorn gevent

# Кастомний застосунок встановлюється через volume mount + pip install -e
# (не pip install тут — щоб зміни в ./erpnext/security_erp/ підхоплювалися без rebuild)
```

> **Примітка:** `pip install -e` для security_erp запускати вручну після старту контейнера
> (Крок 7). У command: не писати — це заважало healthcheck у старому compose.

---

### Крок 6. Збудувати і запустити інфраструктуру

```bash
# Переконатися, що старих контейнерів немає
docker compose down -v 2>/dev/null || true

# Зібрати erpnext-backend з Dockerfile.backend
docker compose build erpnext-backend

# Підняти тільки БД і Redis — дочекатися healthy перед ініціалізацією сайту
docker compose up -d mariadb redis

# Зачекати ~30 секунд, перевірити стан
docker compose ps
# mariadb   →  healthy
# redis     →  healthy
```

---

### Крок 7. Ініціалізувати сайт ERPNext

```bash
# Підняти backend для виконання bench-команд
docker compose up -d erpnext-backend

# Зачекати поки backend перейде в healthy (~2 хв при першому старті)
docker compose ps erpnext-backend
# Статус має бути: healthy

# Увійти в контейнер
docker compose exec erpnext-backend bash

# Всередині контейнера:
cd /home/frappe/frappe-bench

# Встановити кастомний застосунок у режимі розробки
pip install -e apps/security_erp

# Переконатися, що застосунок бачить bench
bench --version
ls apps/security_erp/security_erp/hooks.py

# Створити новий сайт (підставити значення з .env)
bench new-site erp.localhost \
  --db-root-password changeme_root \
  --admin-password changeme_admin \
  --no-mariadb-socket

# Встановити застосунки
bench --site erp.localhost install-app erpnext
bench --site erp.localhost install-app security_erp

# Перевірити що всі DocTypes є
bench --site erp.localhost list-apps
# Вивід: frappe, erpnext, security_erp

# Вийти з контейнера
exit
```

---

### Крок 8. Підняти весь стек

```bash
docker compose up -d

# Перевірити стан усіх 9 контейнерів
docker compose ps

# Очікуваний стан через 2-3 хв:
# mariadb              healthy
# redis                healthy
# erpnext-backend      healthy
# erpnext-frontend     running
# erpnext-worker-default  running
# erpnext-worker-short    running
# erpnext-scheduler    running
# erpnext-socketio     running
# traefik              running
```

Відкрити браузер: `http://erp.localhost` (або `http://localhost:8080` якщо
Traefik не налаштований на 80-й порт локально).

Логін: `Administrator` / пароль з `ADMIN_PASSWORD`.

---

### Крок 9. Перевірити наскрізний потік вручну

Пройти кожен крок через ERPNext UI — без AI, без мобілки:

| # | Дія в UI | DocType / Меню | Перевірка |
|---|---|---|---|
| 1 | Створити клієнта | CRM → Customer | Поля: ім'я, телефон, адреса |
| 2 | Створити об'єкт безпеки | Security ERP → Security Object | Посилання на Customer |
| 3 | Створити кошторис вручну | Security ERP → Estimate | customer, items (без AI) |
| 4 | Додати сценарій вручну | Estimate → SecurityScenarioItem (child table) | Позиції комплекту |
| 5 | Згенерувати КП | Estimate → Create Quotation (кнопка з `create_quotation()`) | Quotation у ERPNext |
| 6 | Роздрукувати КП | Quotation → Print | PDF завантажується |
| 7 | Конвертувати в Sales Order | Quotation → Make → Sales Order | SO зі статусом Draft |
| 8 | Створити договір вручну | Security ERP → Contract | Посилання на SO / Customer |
| 9 | Виставити рахунок | Sales Order → Make → Sales Invoice | SI зі статусом Draft |
| 10 | Створити акт | Security ERP → Installation Act | items, customer_signature |
| 11 | Submit акт | Installation Act → Submit | on_submit → status Pending Approval |
| 12 | Перевірити серійні номери | Equipment list | Записи після submit акту (якщо хук реалізовано) |

---

### Крок 10. Закомітити чистий стан

```bash
git add -A
git commit -m "feat(stage4): minimal 9-container stack, fixed app path and name

- Replaced 20-container compose with 9-container minimal stack
- Fixed volume: ./erpnext/security_erp (was: ./security_erp_app)
- Fixed app name: security_erp (was: security_erp_app)
- Connected Dockerfile.backend via build: instead of image:
- Added configs/mariadb.cnf (was missing, caused MariaDB to mount dir)
- Added .env.example (was missing)
- Created permissions.py (ImportError blocker for Contract)
- Removed: telegram-service, n8n, postgres, nats, minio, prometheus,
           grafana, loki, promtail and their volumes
- Removed: services/fsm-service, cmdb-service, ai-service, telegram-service
- Removed: configs/n8n, prometheus, grafana, loki, promtail
- Fixed scripts/start.sh: removed chmod on missing init-minio.sh"
```

---

## 4. Залишкові P0-блокери для Кроку 9 (потік не пройде без них)

Це доробки у `erpnext/security_erp/`, які потрібні щоб потік пройшов
**повністю** (деякі кроки без них — лише вручну через UI):

| # | Блокер | Файл | Що зробити |
|---|---|---|---|
| B-1 | `permissions.py` відсутній → `ImportError` при відкритті Contract | `erpnext/security_erp/security_erp/permissions.py` | **Вирішено у Кроці 1 вище** |
| B-2 | `apply_scenario()` відсутній → Security Scenario не додає items до Estimate | `erpnext/security_erp/security_erp/doctype/estimate/estimate.py` | Додати `@frappe.whitelist()` метод `apply_scenario(self, scenario_name)` |
| B-3 | `on_submit(InstallationAct)` не реєструє Equipment із serial_number | `erpnext/security_erp/security_erp/doctype/installation_act/installation_act.py` | Додати `on_submit(self)` → loop по `self.items` → create/update Equipment |
| B-4 | Print Format для Quotation (КП) відсутній | `erpnext/security_erp/security_erp/print_format/security_kp/security_kp.html` | Створити Jinja2-шаблон; зареєструвати у fixtures |
| B-5 | Поле `tz_text` (Технічне завдання) відсутнє в Estimate | `erpnext/security_erp/security_erp/doctype/estimate/estimate.json` | Додати Long Text поле; до AI-реалізації заповнюється вручну |

> **B-1 вирішено в Кроці 1.**
> **B-2, B-3** критичні для автоматизації, але Кроки 4 і 12 потоку можна пройти
> вручну через UI (ввести items і serial_number руками).
> **B-4, B-5** — важливо, але не блокують весь потік повністю.

---

## 5. Що НЕ чіпати в цьому етапі

| Що | Де | Причина |
|---|---|---|
| `services/security-api/` | тека | DEFER — потрібен для Flutter Етап 2 |
| `android-app/` | тека | DEFER — Етап 2 |
| `configs/cloudflared/` | тека | DEFER — разом із cloudflared-сервісом |
| AI-логіка в estimate | відсутня | Замінена ручним введенням, реалізувати в Етапі 5 |
| `Warranty Letter` DocType | відсутній | P1, не блокер потоку; реалізувати після Б-2..Б-4 |
