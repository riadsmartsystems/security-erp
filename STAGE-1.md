# STAGE-1: Чому зараз нічого не запускається
_Дата аудиту: 2026-06-18_
_Джерела: docker-compose.yml, Dockerfile.backend, scripts/start.sh, scripts/deploy.sh,_
_.github/workflows/ci.yml, services/security-api/Dockerfile + requirements.txt, .gitignore_

---

## Відповідь на головне питання

**Чому все вмерло — найімовірніша причина:**

Тека `./security_erp_app` є у `.gitignore` (рядок `security_erp_app/`), тобто вона
**ніколи не існувала в git-репо**. Після будь-якого `git clone`, `git pull` або
`docker system prune -v` вона відсутня на диску.
Без неї команда `pip install -e /home/frappe/frappe-bench/apps/security_erp_app`
в контейнері `erpnext-backend` одразу падає → backend входить у crashloop →
healthcheck `/api/method/ping` ніколи не проходить (start_period=120s, retries=10) →
весь downstream (`erpnext-frontend`, всі workers, scheduler) зависає у стані
`waiting for condition: service_healthy` і ніколи не стартує.
Паралельно конфлікт порту 8000 не дозволяє compose навіть підняти два контейнери
одночасно — перший, хто встиг зайняти порт, «вбиває» другий.

---

## Ранжований список причин (найкритичніші зверху)

---

### КРИТИЧНО-1 — Відсутня тека `./security_erp_app` (хибний volume mount)

**Файл:** `docker-compose.yml`, сервіси `erpnext-backend`, `erpnext-worker-default`,
`erpnext-worker-short`, `erpnext-scheduler`

```yaml
volumes:
  - ./security_erp_app:/home/frappe/frappe-bench/apps/security_erp_app
```

**Реальна тека в репо:** `erpnext/security_erp/`
**У `.gitignore`:** рядок `security_erp_app/` → тека ніколи не потрапляла в git

**Наслідок:** Docker монтує порожню директорію → команда в `command:` кожного
контейнера:
```sh
pip install -e /home/frappe/frappe-bench/apps/security_erp_app
```
падає з `ERROR: ... not a valid setuptools project` або `No such file or directory` →
`erpnext-backend` виходить з кодом 1 → crashloop → healthcheck ніколи не OK →
весь стек у стані `waiting`.

---

### КРИТИЧНО-2 — Конфлікт порту 8000

**Файл:** `docker-compose.yml`

```yaml
erpnext-backend:
  ports:
    - "8000:8000"   # ← тут
    
security-api:
  ports:
    - "8000:8000"   # ← і тут
```

**Наслідок:** `docker compose up -d` падає з помилкою:
```
Error response from daemon: driver failed programming external connectivity:
Bind for 0.0.0.0:8000 failed: port is already allocated
```
Один з двох контейнерів не стартує зовсім. Як правило — той, що йде другим
у порядку запуску compose.

---

### КРИТИЧНО-3 — `.env.example` відсутній у репо

**Файли:** `README.md` (`cp .env.example .env`), `scripts/start.sh` (рядок 11),
`.gitignore` (`.env` в ігнорі)

**У project knowledge `.env.example` відсутній.** Файл `scripts/start.sh` сам
попереджає:
```sh
cp .env.example .env 2>/dev/null || echo "No .env.example found, using existing .env"
```

**Наслідок:** Свіжий `docker compose up -d` без `.env` підставляє порожні рядки
для всіх `${VAR}`:
- `MYSQL_ROOT_PASSWORD=""` → MariaDB стартує без пароля або падає залежно від версії
- `REDIS_PASSWORD=""` → healthcheck `redis-cli -a "" ping` повертає `NOAUTH` і
  позначає Redis як unhealthy → erpnext-backend не стартує (depends_on redis healthy)
- `NATS_USER` / `NATS_PASSWORD` порожні → NATS відмовляє у з'єднанні telegram-service
- `INTEGRATION_DB_PASSWORD` порожній → PostgreSQL healthcheck `pg_isready` може
  пройти, але n8n не підключиться до БД
- Усі `${DOMAIN}`, `${SITE_NAME}` порожні → Traefik-роутинг не спрацює

---

### КРИТИЧНО-4 — Неправильна назва пакету у `command:` всіх ERPNext-контейнерів

**Файл:** `docker-compose.yml`, сервіси `erpnext-backend`, `erpnext-worker-default`,
`erpnext-worker-short`, `erpnext-scheduler`

Команда (однакова у всіх чотирьох):
```sh
sed -i 's/erpnextsecurity_erp_app/erpnext/g' \
    /home/frappe/frappe-bench/sites/apps.txt
```

`sed` шукає злите слово `erpnextsecurity_erp_app` (без роздільника між `erpnext`
і `security_erp_app`) — такого рядка в `apps.txt` ніколи не буде. `sed` нічого
не замінює, але повертає 0 і скрипт продовжується.

Далі:
```sh
grep -qxF 'security_erp_app' .../apps.txt || \
    printf 'security_erp_app\n' >> .../apps.txt
bench worker --queue default   # після pip install -e security_erp_app
```

Реальна назва пакету — `security_erp` (за `erpnext/security_erp/setup.py`
і workspace JSON). Bench шукатиме `security_erp_app` → `App security_erp_app
is not installed` або `ModuleNotFoundError`.

**README** при цьому правильно інструктує:
```sh
bench --site erp.localhost install-app security_erp   # ← правильно
```

---

### СЕРЙОЗНО-5 — `ланцюг depends_on: service_healthy` блокує весь стек

**Файл:** `docker-compose.yml`

```
mariadb (healthy) ─┐
redis (healthy)    ├─▶ erpnext-backend (healthy) ─▶ erpnext-frontend
                   │                              ─▶ erpnext-worker-default
                   │                              ─▶ erpnext-worker-short
                   │                              ─▶ erpnext-scheduler
postgres (healthy) ─▶ n8n
nats (healthy) ────▶ telegram-service
```

Через проблеми №1 і №4 `erpnext-backend` ніколи не виходить у `healthy`.
З `restart: unless-stopped` він рестартує нескінченно.
Downstream (frontend, workers, scheduler) зависають у стані `Created`/`Waiting`
і не отримують жодного трафіку.

---

### СЕРЙОЗНО-6 — `Dockerfile.backend` не задіяний в compose

**Файли:** `Dockerfile.backend`, `docker-compose.yml` (сервіс `erpnext-backend`)

```yaml
# docker-compose.yml — erpnext-backend
image: frappe/erpnext:v15.111.0   # ← напряму образ, без build
```

`Dockerfile.backend` додає `gunicorn` і `gevent`:
```dockerfile
FROM frappe/erpnext:v15.111.0
RUN pip install gunicorn gevent
```

Але цей файл ніколи не збирається. Якщо `bench serve` потребує gevent-воркер —
він не отримує його і fallback до синхронного режиму або краш.

---

### СЕРЙОЗНО-7 — `configs/mariadb.cnf` — невідомо, чи існує файл

**Файл:** `docker-compose.yml`, сервіс `mariadb`

```yaml
volumes:
  - ./configs/mariadb.cnf:/etc/mysql/conf.d/custom.cnf:ro
```

Файл `configs/mariadb.cnf` відсутній у project knowledge. Якщо він відсутній на
диску — Docker автоматично створює **директорію** `./configs/mariadb.cnf/` замість
файлу. MariaDB намагається читати директорію як конфіг і стартує з помилкою або
ігнорує монтаж (залежно від версії). Healthcheck `healthcheck.sh --connect
--innodb_initialized` може не пройти.

---

### СЕРЙОЗНО-8 — `scripts/start.sh` викликає неіснуючий `scripts/init-minio.sh`

**Файл:** `scripts/start.sh`, рядок ~14

```sh
chmod +x scripts/init-minio.sh   # ← права встановлює, але не запускає
```

`init-minio.sh` не викликається (`./scripts/init-minio.sh` відсутній).
При `set -e` `chmod` на неіснуючий файл → `No such file or directory` → скрипт
падає до `docker compose up -d`. Стек взагалі не стартує через `start.sh`.

---

### СЕРЕДНЬО-9 — `security-api` вимагає `anthropic==0.30.0` без зовнішнього LLM

**Файл:** `services/security-api/requirements.txt`

```
anthropic==0.30.0
```

`services/security-api/app/services/ai_service.py` є в CI як обов'язковий файл
для syntax-check. Якщо `AI_SERVICE_KEY` або `LLM_URL` порожні (бо немає `.env`) —
`ai_service` може падати при імпорті або при першому запиті → security-api
нездоровий.

---

### СЕРЕДНЬО-10 — NATS healthcheck ненадійний в `nats:2-alpine`

**Файл:** `docker-compose.yml`, сервіс `nats`

```yaml
healthcheck:
  test: ["CMD-SHELL", "wget -q --spider http://localhost:8222/healthz || exit 1"]
```

Образ `nats:2-alpine` (починаючи з ~v2.10) не містить `wget` у дефолтній
збірці. `wget: not found` → healthcheck завжди `Exit 1` → `nats` назавжди
в стані `unhealthy` → `telegram-service` (depends_on nats healthy) не стартує.

---

### НИЗЬКО-11 — `scripts/deploy.sh` не перевіряє `.env`

**Файл:** `scripts/deploy.sh`, кроки 1-3

`deploy.sh` виконує `git pull` → `docker compose build` → `docker compose up -d`
без жодної перевірки наявності `.env`. Якщо `.env` відсутній — compose стартує
з порожніми змінними (проблема №3) без жодного попередження.

---

### НИЗЬКО-12 — `.github/workflows/ci.yml` не тестує ERPNext-частину

**Файл:** `.github/workflows/ci.yml`

CI перевіряє лише `services/security-api` і `services/telegram-service`.
Кастомний Frappe-застосунок `erpnext/security_erp/` не lint-ується, не
тестується, не перевіряється навіть на синтаксис. Помилки в DocType JSON або
Python hooks не виявляються до реального запуску.

---

## Зведена таблиця причин

| # | Severity | Суть | Файл(и) |
|---|----------|------|---------|
| 1 | 🔴 КРИТИЧНО | `./security_erp_app` відсутня (gitignore + хибний шлях) | `docker-compose.yml`, `.gitignore` |
| 2 | 🔴 КРИТИЧНО | Конфлікт порту 8000 між erpnext-backend і security-api | `docker-compose.yml` |
| 3 | 🔴 КРИТИЧНО | `.env.example` відсутній → compose стартує з порожніми змінними | `.gitignore`, `README.md`, `scripts/start.sh` |
| 4 | 🔴 КРИТИЧНО | Назва пакету `security_erp_app` vs `security_erp` у всіх command: | `docker-compose.yml` |
| 5 | 🟠 СЕРЙОЗНО | Ланцюг `depends_on: service_healthy` блокує весь стек | `docker-compose.yml` |
| 6 | 🟠 СЕРЙОЗНО | `Dockerfile.backend` не задіяний (image замість build) | `docker-compose.yml`, `Dockerfile.backend` |
| 7 | 🟠 СЕРЙОЗНО | `configs/mariadb.cnf` відсутній → Docker монтує директорію | `docker-compose.yml` |
| 8 | 🟠 СЕРЙОЗНО | `scripts/start.sh` падає на `chmod` неіснуючого `init-minio.sh` | `scripts/start.sh` |
| 9 | 🟡 СЕРЕДНЬО | `anthropic==0.30.0` без LLM-ендпоінта в стеці | `services/security-api/requirements.txt` |
| 10 | 🟡 СЕРЕДНЬО | NATS healthcheck `wget` відсутній в nats:2-alpine | `docker-compose.yml` |
| 11 | 🟢 НИЗЬКО | `deploy.sh` не перевіряє наявність `.env` | `scripts/deploy.sh` |
| 12 | 🟢 НИЗЬКО | CI не перевіряє `erpnext/security_erp/` | `.github/workflows/ci.yml` |
