# STAGE-5: Backlog виправлень
_Дата: 2026-06-18_
_Спирається на: STAGE-1.md, STAGE-2.md, STAGE-3.md, STAGE-4.md_

> Виконувати **строго зверху вниз**. Кожна задача ≤ 1–2 год. Жодних задач про
> Telegram / n8n / моніторинг / мобілку.

---

## БЛОК А — Повернути систему до запуску

---

### A-1 · Прибрати рядок `chmod` в `scripts/start.sh`

**Файл:** `scripts/start.sh`, рядок ~14

**Що зробити:** Видалити або закоментувати рядок:
```sh
chmod +x scripts/init-minio.sh
```
(`init-minio.sh` не існує; при `set -e` цей рядок валить весь скрипт до
`docker compose up`, тому стек взагалі не стартує через `start.sh`.)

**Готово коли:** `bash scripts/start.sh` не падає на цьому рядку
(або рядок видалений і скрипт доходить до `docker compose up`).

---

### A-2 · Виправити `.gitignore` — прибрати `security_erp_app/`

**Файл:** `.gitignore`

**Що зробити:** Знайти і видалити рядок:
```
security_erp_app/
```
Реальна тека застосунку — `erpnext/security_erp/`, вона не повинна
ігноруватися.

**Готово коли:** `git status` показує `erpnext/security_erp/` як
відстежувану теку; `git ls-files erpnext/security_erp/hooks.py` повертає шлях.

---

### A-3 · Створити `configs/mariadb.cnf`

**Файл:** `configs/mariadb.cnf` (відсутній — STAGE-1, проблема №7)

**Що зробити:** Створити файл із мінімальним вмістом:
```ini
[mysqld]
character-set-server  = utf8mb4
collation-server      = utf8mb4_unicode_ci
innodb_buffer_pool_size = 512M
innodb_log_file_size    = 128M
```

**Готово коли:** `ls -la configs/mariadb.cnf` показує **файл** (не директорію);
`docker compose up mariadb` піднімає MariaDB без помилок монтажу.

---

### A-4 · Створити `.env.example` і локальний `.env`

**Файли:** `.env.example` (новий, комітити), `.env` (з `.gitignore`, не комітити)

**Що зробити:** Створити `.env.example`:
```dotenv
# MariaDB
MYSQL_ROOT_PASSWORD=changeme_root

# ERPNext Site
SITE_NAME=erp.localhost
ADMIN_PASSWORD=changeme_admin

# Traefik / Domain
DOMAIN=erp.localhost
```
Потім: `cp .env.example .env` і замінити `changeme_*` на реальні значення.

**Готово коли:** `cat .env.example` виводить усі 4 змінні;
`docker compose config` не містить порожніх `${VAR}`.

---

### A-5 · Замінити `docker-compose.yml` на мінімальний 9-контейнерний стек

**Файл:** `docker-compose.yml`

**Що зробити:** Повністю замінити поточний файл (20 сервісів) на
мінімальний стек з STAGE-4, розділ 2. Ключові виправлення, які мають бути
в новому файлі:

| Що виправляємо | Старе значення | Нове значення |
|---|---|---|
| Volume-шлях | `./security_erp_app:/…/security_erp_app` | `./erpnext/security_erp:/…/security_erp` |
| erpnext-backend | `image: frappe/erpnext:v15.111.0` | `build: {context: ., dockerfile: Dockerfile.backend}` |
| Redis healthcheck | `redis-cli -a "" ping` (зі старим паролем) | `redis-cli ping` (без пароля) |
| Конфлікт порту 8000 | і erpnext-backend, і security-api на 8000 | erpnext-backend без ports:; frontend на 8080 |
| Назва пакету в command: | `security_erp_app` | `security_erp` |
| CUT-сервіси | telegram, n8n, postgres, nats, minio, prometheus, grafana, loki, promtail | **відсутні** |
| CUT-volumes | minio_data, prometheus_data, grafana_data, loki_data, n8n_data, nats_data, postgres_data | **відсутні** |

**Готово коли:** `docker compose config --services` виводить рівно 9 рядків:
`mariadb redis erpnext-backend erpnext-frontend erpnext-worker-default
erpnext-worker-short erpnext-scheduler erpnext-socketio traefik`.

---

### A-6 · Перевірити і виправити `Dockerfile.backend`

**Файл:** `Dockerfile.backend`

**Що зробити:** Переконатися, що файл містить лише:
```dockerfile
FROM frappe/erpnext:v15.111.0
RUN pip install gunicorn gevent
```
Жодного `pip install -e security_erp_app` всередині Dockerfile — це буде
виконуватися вручну після старту контейнера (Крок A-8).

**Готово коли:** `docker compose build erpnext-backend` завершується без
помилок; `docker images | grep erpnext-backend` показує новий образ.

---

### A-7 · Створити `permissions.py` — усунути `ImportError` на Contract

**Файл:** `erpnext/security_erp/security_erp/permissions.py` (відсутній —
STAGE-3, STAGE-4 B-1)

**Що зробити:** Створити файл:
```python
import frappe


def contract_has_permission(doc, user=None, permission_type=None):
    """Custom permission check for Contract doctype."""
    if not user:
        user = frappe.session.user
    return frappe.has_permission(
        "Contract", ptype=permission_type or "read", user=user
    )
```

**Готово коли:** `python -c "from security_erp.permissions import contract_has_permission; print('OK')"` всередині bench-контейнера виводить `OK`; відкриття будь-якого Contract в UI не кидає `ImportError`.

---

### A-8 · Ініціалізувати сайт ERPNext (разова ручна операція)

**Контекст:** виконується **після** A-1…A-7 і успішного
`docker compose up -d mariadb redis erpnext-backend`.

**Що зробити:**
```bash
docker compose exec erpnext-backend bash
cd /home/frappe/frappe-bench
pip install -e apps/security_erp
bench new-site erp.localhost \
  --db-root-password <MYSQL_ROOT_PASSWORD з .env> \
  --admin-password  <ADMIN_PASSWORD з .env> \
  --no-mariadb-socket
bench --site erp.localhost install-app erpnext
bench --site erp.localhost install-app security_erp
exit
docker compose up -d   # підняти решту 6 сервісів
```

**Готово коли:** `http://erp.localhost` (або `http://localhost:8080`) відкриває
ERPNext UI; `bench --site erp.localhost list-apps` виводить
`frappe erpnext security_erp`.

---

## БЛОК Б — Наскрізний потік

---

### B-1 · Додати поле `tz_text` (Технічне завдання) до `Estimate`

**Файл:** `erpnext/security_erp/security_erp/doctype/estimate/estimate.json`

**Що зробити:** У масив `fields` додати новий об'єкт (після поля
`security_type` або `object_type`):
```json
{
  "fieldname": "tz_text",
  "fieldtype": "Long Text",
  "label": "Технічне завдання",
  "in_list_view": 0
}
```

**Готово коли:** Форма `Estimate` в ERPNext UI показує поле
«Технічне завдання»; поле зберігається і читається без помилок.

---

### B-2 · Додати поле `lead` (Link → Lead) до `Estimate`

**Файл:** `erpnext/security_erp/security_erp/doctype/estimate/estimate.json`

**Що зробити:** Додати поле:
```json
{
  "fieldname": "lead",
  "fieldtype": "Link",
  "label": "Ліד",
  "options": "Lead"
}
```

**Готово коли:** Форма `Estimate` показує поле «Ліід» з пошуком по `Lead`;
фільтрація `Estimate` по `lead` дає коректний список.

---

### B-3 · Реалізувати `apply_template()` в `estimate.py`

**Файл:** `erpnext/security_erp/security_erp/doctype/estimate/estimate.py`

**Що зробити:** Додати `@frappe.whitelist()` метод:
```python
@frappe.whitelist()
def apply_template(self, template_name):
    tmpl = frappe.get_doc("Estimate Template", template_name)
    for ti in tmpl.items:
        self.append("items", {
            "item_code":   ti.item_code,
            "item_name":   ti.item_name,
            "qty":         ti.qty,
            "rate":        ti.rate,
        })
    self.calculate_totals()
```
Зареєструвати кнопку в `estimate.js` (або Frappe Custom Script) для виклику
з UI.

**Готово коли:** На формі `Estimate` кнопка «Застосувати шаблон» вибирає
`Estimate Template` і копіює items до кошторису; поля заповнюються без
`AttributeError`.

---

### B-4 · Реалізувати `apply_scenario()` в `estimate.py`

**Файл:** `erpnext/security_erp/security_erp/doctype/estimate/estimate.py`

**Що зробити:** Додати `@frappe.whitelist()` метод:
```python
@frappe.whitelist()
def apply_scenario(self, scenario_name):
    scenario = frappe.get_doc("Security Scenario", scenario_name)
    for si in scenario.items:
        self.append("items", {
            "item_code": si.item_code,
            "item_name": si.item_name,
            "qty":       si.qty,
            "rate":      si.rate,
        })
    self.calculate_totals()
```
Зареєструвати кнопку у `estimate.js`.

**Готово коли:** На формі `Estimate` кнопка «Додати сценарій» вибирає
`Security Scenario` і додає його позиції до кошторису; `calculate_totals()`
перераховує суму.

---

### B-5 · Реалізувати `on_submit()` в `installation_act.py` — реєстрація Equipment

**Файл:** `erpnext/security_erp/security_erp/doctype/installation_act/installation_act.py`

**Що зробити:** Додати або розширити метод `on_submit`:
```python
def on_submit(self):
    self.status = "Pending Approval"
    for item in self.items:
        if not item.serial_number:
            continue
        if frappe.db.exists("Equipment", {"serial_number": item.serial_number}):
            eq = frappe.get_doc("Equipment", {"serial_number": item.serial_number})
        else:
            eq = frappe.new_doc("Equipment")
            eq.serial_number = item.serial_number
        eq.item_code  = item.item_code
        eq.status     = "Installed"
        eq.installation_act = self.name
        eq.security_object  = self.security_object
        eq.save(ignore_permissions=True)
    self.save(ignore_permissions=True)
```

**Готово коли:** Після `Submit` акту у списку `Equipment` з'являються нові
записи з `serial_number` і `status = Installed`; повторний `Submit` не
дублює записи.

---

### B-6 · Виправити `contract.py` — усунути порожній `pass` і додати зв'язок з Quotation

**Файл:** `erpnext/security_erp/security_erp/doctype/contract/contract.py`

**Що зробити:**

1. Додати поле `quotation` (Link→Quotation) до
   `erpnext/security_erp/security_erp/doctype/contract/contract.json`.
2. У `contract.py` замінити `pass` на мінімальний `validate`:
```python
def validate(self):
    if not self.contract_number:
        self.contract_number = frappe.model.naming.make_autoname("CNT-.YYYY.-.####")
```

**Готово коли:** Форма `Contract` відкривається без помилок;
поле `quotation` відображається і зберігається; `contract_number`
автоматично присвоюється при збереженні.

---

### B-7 · Створити Print Format для Quotation (КП)

**Файл:** `erpnext/security_erp/security_erp/print_format/security_kp/security_kp.html`
(тека `print_format/` відсутня — створити)

**Що зробити:** Мінімальний Jinja2-шаблон:
```html
<div>
  <h2>Комерційна пропозиція № {{ doc.name }}</h2>
  <p>Клієнт: {{ doc.customer_name }}</p>
  <p>Дата: {{ doc.transaction_date }}</p>
  <table border="1" width="100%">
    <tr><th>Назва</th><th>К-сть</th><th>Ціна</th><th>Сума</th></tr>
    {% for item in doc.items %}
    <tr>
      <td>{{ item.item_name }}</td>
      <td>{{ item.qty }}</td>
      <td>{{ item.rate }}</td>
      <td>{{ item.amount }}</td>
    </tr>
    {% endfor %}
  </table>
  <p><strong>Разом: {{ doc.grand_total }} грн</strong></p>
</div>
```
Зареєструвати через `bench --site erp.localhost migrate` або додати JSON
`print_format/security_kp/security_kp.json` до `fixtures` у `hooks.py`.

**Готово коли:** На формі `Quotation` в меню «Print» доступний формат
«Security KP»; PDF завантажується і містить таблицю позицій та суму.

---

### B-8 · Створити Print Format для Installation Act (Акт виконаних робіт)

**Файл:** `erpnext/security_erp/security_erp/print_format/installation_act/installation_act.html`

**Що зробити:** Мінімальний Jinja2-шаблон:
```html
<div>
  <h2>Акт виконаних робіт № {{ doc.act_number }}</h2>
  <p>Клієнт: {{ doc.customer }}</p>
  <p>Дата: {{ doc.act_date }}</p>
  <table border="1" width="100%">
    <tr><th>Обладнання</th><th>С/н</th><th>К-сть</th></tr>
    {% for item in doc.items %}
    <tr>
      <td>{{ item.item_name }}</td>
      <td>{{ item.serial_number }}</td>
      <td>{{ item.qty }}</td>
    </tr>
    {% endfor %}
  </table>
  <p>Підпис клієнта: ____________________</p>
  <p>Гарантія: 12 місяців з дати підписання акту.</p>
</div>
```

**Готово коли:** На формі `Installation Act` доступний Print Format
«Installation Act»; PDF містить таблицю з серійними номерами і рядок
підпису клієнта.

---

### B-9 · Створити DocType `Warranty Letter` (Гарантійний лист)

**Файли для створення:**
- `erpnext/security_erp/security_erp/doctype/warranty_letter/warranty_letter.json`
- `erpnext/security_erp/security_erp/doctype/warranty_letter/warranty_letter.py`
- `erpnext/security_erp/security_erp/print_format/warranty_letter/warranty_letter.html`

**Що зробити:** Мінімальний DocType із полями:
```
letter_number   — Data (autoname)
installation_act — Link → Installation Act
customer        — Link → Customer (fetch_from: installation_act.customer)
issue_date      — Date
warranty_months — Int (default 12)
expiry_date     — Date (calculated in validate)
status          — Select: Draft / Issued
```
`warranty_letter.py::validate()` → `self.expiry_date = add_months(self.issue_date, self.warranty_months)`.
Print Format — лист із реквізитами компанії, переліком обладнання (child table
або текстове поле), датою закінчення гарантії.

**Готово коли:** DocType `Warranty Letter` з'являється у меню Security ERP;
можна створити лист, прив'язати до `Installation Act`, зберегти і роздрукувати PDF.

---

### B-10 · Реалізувати AI-чернетку кошторису (Anthropic API)

**Файли:**
- Новий: `erpnext/security_erp/security_erp/estimate_utils.py`
- Змінити: `Dockerfile.backend` — додати `RUN pip install anthropic>=0.25`
- Змінити: `erpnext/security_erp/security_erp/doctype/estimate/estimate.js` —
  кнопка «Згенерувати AI-чернетку»

**Що зробити в `estimate_utils.py`:**
```python
import frappe
import anthropic


@frappe.whitelist()
def generate_ai_estimate(doc_name):
    doc = frappe.get_doc("Estimate", doc_name)
    tz  = doc.get("tz_text") or ""
    if not tz:
        frappe.throw("Заповніть поле «Технічне завдання» перед генерацією.")

    api_key = frappe.conf.get("anthropic_api_key") or frappe.db.get_single_value(
        "Security ERP Settings", "anthropic_api_key"
    )
    client  = anthropic.Anthropic(api_key=api_key)
    prompt  = (
        f"Ти — інженер з безпеки. На основі ТЗ нижче склади мінімальний "
        f"кошторис у форматі JSON-масиву: "
        f'[{{"item_name":"...", "qty":1, "rate":0, "unit":"шт"}}]. '
        f"Тільки JSON, без пояснень.\nТЗ: {tz}"
    )
    msg    = client.messages.create(
        model="claude-sonnet-4-6", max_tokens=1000,
        messages=[{"role": "user", "content": prompt}]
    )
    import json
    items = json.loads(msg.content[0].text)
    for it in items:
        doc.append("items", it)
    doc.calculate_totals()
    doc.save(ignore_permissions=True)
    return "OK"
```
API-ключ зберігати у `site_config.json` або DocType `Security ERP Settings`
(не у `.env` — щоб не потрапив у compose).

**Готово коли:** На формі `Estimate` заповнено `tz_text` → натиснуто
«Згенерувати AI-чернетку» → у child table `items` з'являються позиції,
сума перераховується; без `tz_text` показується зрозуміла помилка.

---

## БЛОК В — Прибирання

---

### C-1 · Видалити CUT-теки через `git rm -r`

**Теки для видалення:**
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

**Готово коли:** `git status` не показує цих тек; `git log --oneline -1`
містить commit із повідомленням про видалення.

---

### C-2 · Додати перевірку `.env` у `scripts/deploy.sh`

**Файл:** `scripts/deploy.sh`

**Що зробити:** На початку скрипту (після `set -e`) додати:
```bash
if [ ! -f .env ]; then
  echo "ERROR: .env not found. Copy .env.example and fill in values." >&2
  exit 1
fi
```

**Готово коли:** `bash scripts/deploy.sh` без `.env` виводить зрозуміле
повідомлення і виходить з кодом 1 (не виконує `docker compose up`).

---

### C-3 · Додати lint `erpnext/security_erp/` до CI

**Файл:** `.github/workflows/ci.yml`

**Що зробити:** Додати новий job (або step у наявний):
```yaml
- name: Lint security_erp app
  run: |
    pip install pyflakes
    python -m pyflakes erpnext/security_erp/security_erp/ || true
    python -c "
    import ast, sys, pathlib
    errors = []
    for f in pathlib.Path('erpnext/security_erp').rglob('*.py'):
        try: ast.parse(f.read_text())
        except SyntaxError as e: errors.append(f'{f}: {e}')
    if errors: [print(e) for e in errors]; sys.exit(1)
    "
```

**Готово коли:** CI-пайплайн на GitHub перевіряє синтаксис усіх `.py`
файлів у `erpnext/security_erp/`; SyntaxError ламає білд.

---

## Зведена таблиця задач

| # | Блок | Задача | Файли | ≤ год |
|---|------|--------|-------|-------|
| A-1 | Запуск | Прибрати `chmod init-minio.sh` | `scripts/start.sh` | 0.1 |
| A-2 | Запуск | Прибрати `security_erp_app/` з `.gitignore` | `.gitignore` | 0.1 |
| A-3 | Запуск | Створити `configs/mariadb.cnf` | `configs/mariadb.cnf` | 0.2 |
| A-4 | Запуск | Створити `.env.example` і `.env` | `.env.example`, `.env` | 0.3 |
| A-5 | Запуск | Замінити `docker-compose.yml` (20→9 сервісів) | `docker-compose.yml` | 1.5 |
| A-6 | Запуск | Перевірити `Dockerfile.backend` | `Dockerfile.backend` | 0.2 |
| A-7 | Запуск | Створити `permissions.py` | `erpnext/security_erp/security_erp/permissions.py` | 0.3 |
| A-8 | Запуск | Ініціалізувати сайт (bench new-site + install-app) | ручна операція в контейнері | 0.5 |
| B-1 | Потік | Поле `tz_text` в `estimate.json` | `doctype/estimate/estimate.json` | 0.3 |
| B-2 | Потік | Поле `lead` в `estimate.json` | `doctype/estimate/estimate.json` | 0.2 |
| B-3 | Потік | `apply_template()` в `estimate.py` | `doctype/estimate/estimate.py` | 0.5 |
| B-4 | Потік | `apply_scenario()` в `estimate.py` | `doctype/estimate/estimate.py` | 0.5 |
| B-5 | Потік | `on_submit()` → Equipment у `installation_act.py` | `doctype/installation_act/installation_act.py` | 1.0 |
| B-6 | Потік | Виправити `contract.py`, поле `quotation` | `doctype/contract/contract.py`, `contract.json` | 0.5 |
| B-7 | Потік | Print Format для Quotation (КП) | `print_format/security_kp/security_kp.html` | 1.5 |
| B-8 | Потік | Print Format для Installation Act | `print_format/installation_act/installation_act.html` | 1.0 |
| B-9 | Потік | DocType `Warranty Letter` | `doctype/warranty_letter/`, `print_format/warranty_letter/` | 2.0 |
| B-10 | Потік | AI-чернетка кошторису (Anthropic API) | `estimate_utils.py`, `Dockerfile.backend`, `estimate.js` | 2.0 |
| C-1 | Прибирання | `git rm -r` CUT-тек | `services/fsm-service/`, `cmdb-service/`, `ai-service/`, `telegram-service/`, `configs/n8n/` тощо | 0.3 |
| C-2 | Прибирання | Перевірка `.env` у `deploy.sh` | `scripts/deploy.sh` | 0.2 |
| C-3 | Прибирання | Lint `security_erp/` у CI | `.github/workflows/ci.yml` | 0.5 |
