# CHANGELOG — Виправлення Security ERP

## [2026-06-18] Повне відновлення проекту за STAGE-5

### Блок А — Запуск системи

- [x] A-1: Видалено `chmod +x scripts/init-minio.sh` з `scripts/start.sh`
- [x] A-2: Видалено `security_erp_app/` з `.gitignore`
- [x] A-3: Оновлено `configs/mariadb.cnf` — додано InnoDB параметри
- [x] A-4: Створено `.env.example`, оновлено `.env`, збережено `.env.backup`
- [x] A-5: Замінено `docker-compose.yml` — 20→9 сервісів
- [x] A-6: Виправлено `Dockerfile.backend` — прибрано USER root/frappe, додано anthropic
- [x] A-7: Виправлено `permissions.py` — правильна сигнатура з frappe.has_permission()

### Блок Б — Бізнес-логіка

- [x] B-1: Додано поле `tz_text` (Long Text) в `estimate.json`
- [x] B-2: Додано поле `lead` (Link→Lead) в `estimate.json`
- [x] B-3: Додано `apply_template()` в `estimate.py`
- [x] B-4: Додано `apply_scenario()` в `estimate.py`
- [x] B-5: Розширено `on_submit()` в `installation_act.py` — реєстрація Equipment
- [x] B-6: Виправлено `contract.py` (autoname), додано поле `quotation` в `contract.json`
- [x] B-7: Створено Print Format "Security KP" для КП
- [x] B-8: Створено Print Format "Installation Act" для Акту
- [x] B-9: Створено DocType "Warranty Letter" з JSON, Python, Print Format
- [x] B-10: Створено `estimate_utils.py` — AI-чернетка кошторису (Anthropic API)

### Блок В — Прибирання

- [x] C-1: Видалено мертві теки: fsm-service, cmdb-service, ai-service, telegram-service, n8n, prometheus, grafana, loki, promtail
- [x] C-2: Додано перевірку `.env` в `scripts/deploy.sh`
- [x] C-3: Додано lint `security_erp/` у `.github/workflows/ci.yml`

### Верифікація

- [x] docker compose config — 9 сервісів, без помилок
- [x] Python syntax — усі файли security_erp проходять ast.parse()
- [x] JSON syntax — усі файли security_erp проходять json.loads()
- [x] docker compose up -d — усі 9 контейнерів healthy
- [x] Frontend доступний на http://localhost:8080 (200 OK, Login page)
- [x] Backend ping: `{"message":"pong"}` (200 OK)

### Додаткові виправлення під час запуску

- [x] Виправлено healthcheck erpnext-backend: додано `-H 'Host: erp.localhost'`
- [x] Додано `BACKEND: erpnext-backend:8000` та `SOCKETIO_PORT: 9000` до erpnext-frontend
- [x] Додано команду `pip install -e` для erpnext-backend (virtualenv)
- [x] Додано `httpx` до Dockerfile.backend
- [x] Оновлено `common_site_config.json` з Redis URL

### Примітки

- `.env.backup` містить попередні налаштування (TUNNEL_SECRET, Telegram токени, API ключі)
- Для відновлення cloudflared: скопіювати TUNNEL_SECRET з .env.backup в .env, додати сервіс в compose
- A-8 (ініціалізація сайту bench new-site) — ручна операція після docker compose up
