# STAGE-3: Доменна модель проти цільового потоку
_Дата аудиту: 2026-06-18_
_Джерела: `erpnext/security_erp/security_erp/doctype/*/`, `hooks.py`, `events.py`, `tasks/`_

---

## Методологія

Читалися ЛИШЕ файли `erpnext/security_erp/`:
- `doctype/*/**.json` — структура полів
- `doctype/*/**.py` — бізнес-логіка
- `hooks.py` — doc_events, scheduler_events, fixtures
- `events.py` — обробники подій
- `tasks/hourly.py`, `tasks/daily.py` — фонові задачі

---

## Таблиця: Цільовий потік vs Реальний стан

| # | КРОК ПОТОКУ | СТАН | DocType / Файл | Що бракує для роботи |
|---|---|:---:|---|---|
| 1 | **Клієнт / об'єкт** — ім'я, телефон, адреса | ✅ є | ERPNext `Customer`, `Lead`; `doctype/security_object/security_object.json` (поля: customer, address, gps_lat/lon) | — |
| 2 | **ТЗ (технічне завдання)** — текстовий опис задачі клієнта | ❌ відсутнє | Немає ні в `Lead`, ні в `Security Object`, ні в `Estimate` жодного поля `tz_text` / `technical_spec` | Додати Custom Field `tz_text` (Long Text) до `Lead` або `Estimate`; прописати у `fixtures` в `hooks.py` |
| 3 | **AI-чернетка кошторису з ТЗ** | ❌ відсутнє | `services/ai-service/` — порожня заглушка (лише `requirements.txt`). В `security_erp/` немає жодного Python-файлу з AI-логікою (немає виклику Anthropic/OpenAI API) | Реалізувати Frappe whitelisted method `generate_ai_estimate(tz_text, security_type, object_type)` в `security_erp`; додати `anthropic` або `openai` до `requirements.txt` Dockerfile.backend |
| 4 | **Estimate** — інженер редагує позиції | ✅ є | `doctype/estimate/estimate.json` (поля: customer, security_type, object details, items↔EstimateItem); `estimate.py`: `calculate_totals()`, `create_quotation()` | Бракує поля `lead` (Link→Lead) для зв'язку estimate з джерелом; бракує `apply_template()` whitelisted method (структура є, виклику немає) |
| 5 | **Estimate Template** — шаблони комплектів | ✅ є | `doctype/estimate_template/estimate_template.json` (поля: template_name, security_type, object_type, items↔EstimateTemplateItem); `estimate_template.py`: `pass` | Бракує whitelisted method `apply_template(template_name)` в `estimate.py` який переносить items з шаблону в estimate; зараз тільки структура даних |
| 6 | **Security Scenario** — авто-комплект позицій | ⚠️ наполовину | `doctype/security_scenario/security_scenario.json` (поля: scenario_name, security_type, is_active, items↔SecurityScenarioItem); `security_scenario.py`: `pass` | Логіка `apply_scenario_to_estimate()` існує лише в `services/security-api/app/services/scenario_service.py` (DEFER) і оперує `Lead.ai_estimate_result` (JSON-рядок) — не Estimate DocType. В `security_erp` немає whitelisted method для додавання scenario items до Estimate |
| 7 | **КП / PDF (Quotation)** | ⚠️ наполовину | `estimate.py::create_quotation()` ✅ — метод створює ERPNext `Quotation` з items; `hooks.py::doc_events["Quotation"]` ✅ — realtime-подія при зміні статусу | Бракує Print Format (HTML/Jinja) для кастомного КП з логотипом і реквізитами (немає `print_format/` тек у security_erp); поле `object_address` передається в Quotation але не зареєстроване як Custom Field у `fixtures` |
| 8 | **Contract (Договір)** | ⚠️ наполовину | `doctype/contract/contract.json` ✅ (поля: contract_number, customer, contract_type, start/end_date, status, contract_value, SLA fields, child table `ContractObject`); `hooks.py::has_permission["Contract"]` ✅ | `contract.py` — порожній (`pass`); немає автоматичного створення Contract після підписання Quotation/Sales Order; немає поля `quotation` для зв'язку; `permissions.contract_has_permission` викликається але файл `permissions.py` не знайдено в project knowledge |
| 9 | **Рахунок (Sales Invoice)** | ⚠️ наполовину | ERPNext стандартний `Sales Invoice` ✅ (вбудований); `events.py::sales_order_on_update` ✅ — realtime при зміні Sales Order | В `security_erp` немає жодного hook або whitelisted method для створення SI з Contract або Sales Order; логіка є лише в `services/security-api/app/routes/doctypes.py` (DEFER); через стандартний ERPNext UI — вручну |
| 10 | **Installation Act (Акт виконаних робіт)** | ⚠️ наполовину | `doctype/installation_act/installation_act.json` ✅ (поля: act_number, project, customer, act_date, status, items↔InstallationActItem, customer_signature); `installation_act.py` ✅: `validate_items()`, `calculate_totals()`, `on_submit()→"Pending Approval"` | Бракує Print Format для Акту (немає `print_format/` тек); немає hook `on_submit` → автооновлення Equipment.status = "Installed" та копіювання serial_number; немає автостворення InstallationAct з Project при завершенні |
| 11 | **Гарантійний лист (Warranty Letter)** | ❌ відсутнє | `doctype/warranty_case/warranty_case.json` — це ГАРАНТІЙНИЙ ВИПАДОК (claim), не гарантійний лист; `tasks/daily.py::check_warranty_expiry()` ✅ — ToDo при спливанні | Окремий DocType `Warranty Letter` або Print Format відсутній; в `services/security-api` є `Warranty Card` (ERPNext стандартний), але сервіс DEFER; потрібен або новий DocType, або кастомний Print Format для `Installation Act` |
| 12 | **Серійні номери обладнання** (реєстрація при прийманні) | ⚠️ наполовину | `doctype/installation_act_item/installation_act_item.json` ✅ — поле `serial_number`; `doctype/equipment/equipment.json` ✅ — поле `serial_number` (унікальне) | Немає Python-логіки `on_submit(InstallationAct)` → auto-create/update `Equipment` records із serial_number з кожного рядка акту; зв'язок між `InstallationActItem.serial_number` і `Equipment` лише концептуальний, не автоматичний |

---

## Зведена оцінка по кроках

| Статус | Кількість кроків | Кроки |
|---|:---:|---|
| ✅ є (структура + логіка) | 3 | Клієнт/об'єкт, Estimate (редагування), Estimate Template |
| ⚠️ наполовину (структура є, логіка або PDF відсутні) | 6 | Security Scenario, Quotation/КП, Contract, Рахунок, Installation Act, Серійні номери |
| ❌ відсутнє повністю | 3 | ТЗ (поле), AI-чернетка, Гарантійний лист |

---

## Пріоритизований список доробки (мінімум для запуску потоку)

### P0 — Блокери (без них потік не пройти наскрізь)

1. **ТЗ-поле в Lead або Estimate**
   - `erpnext/security_erp/security_erp/doctype/estimate/estimate.json` → додати поле `tz_text` (Long Text, label "Технічне завдання")
   - Зареєструвати як Custom Field у `fixtures` в `hooks.py`

2. **AI-чернетка кошторису**
   - Новий файл: `erpnext/security_erp/security_erp/estimate_utils.py`
   - Whitelisted method `generate_ai_estimate(doc_name)`: бере `tz_text` з Estimate, викликає Anthropic API, заповнює `items`
   - Додати `anthropic>=0.25` до `Dockerfile.backend` pip install

3. **apply_scenario_to_estimate (Security Scenario → Estimate items)**
   - `erpnext/security_erp/security_erp/doctype/estimate/estimate.py` → метод `apply_scenario(scenario_name)`
   - `@frappe.whitelist()` decorator для виклику з UI

4. **on_submit InstallationAct → реєстрація Equipment із serial_number**
   - `erpnext/security_erp/security_erp/doctype/installation_act/installation_act.py::on_submit()` → loop по items → `frappe.get_doc("Equipment", ...)` або `frappe.new_doc("Equipment")` → встановити serial_number, status="Installed"

### P1 — Важливо для повноти (але потік частково можна пройти вручну)

5. **Print Format для Quotation (КП)**
   - Новий файл: `erpnext/security_erp/security_erp/print_format/security_kp/security_kp.html` (Jinja2)
   - Зареєструвати через `fixtures` або `bench make-app-print-format`

6. **Print Format для Installation Act**
   - Новий файл: `erpnext/security_erp/security_erp/print_format/installation_act/installation_act.html`

7. **Warranty Letter — DocType або Print Format**
   - Варіант А: новий DocType `Warranty Letter` зі зв'язком до `Installation Act`
   - Варіант Б: Print Format для `Installation Act` з секцією гарантії

8. **apply_template в Estimate**
   - `estimate.py` → `apply_template(template_name)`: loop `EstimateTemplateItem` → append до `self.items`

9. **Поле `lead` в Estimate**
   - `estimate.json` → додати `{"fieldname": "lead", "fieldtype": "Link", "options": "Lead"}`

10. **permissions.py**
    - `hooks.py` посилається на `security_erp.permissions.contract_has_permission` — файл `permissions.py` відсутній (викине `ImportError` при спробі відкрити будь-який Contract)
    - Критично: `erpnext/security_erp/security_erp/permissions.py` → створити з функцією `contract_has_permission(doc, user)`
