# Аудит розбіжностей: Дизайн vs Реалізація
_Складено: 2026-06-21. Стан: тільки аудит, без вибору напряму._

---

## Джерела

| Роль | Файл |
|------|------|
| **Дизайн-еталон** | `Security_ERP_Platform_Architecture_v3.txt` (v3.0, "Architecture Freeze") |
| **Revised design** | `docs/PROJECT-PLAN-v3.md` (в заголовку — "v4.0", оновлено 2026-06-17 "після аудиту") |
| **Код API** | `services/security-api/app/**` |
| **Frappe-додаток** | `erpnext/security_erp/security_erp/**` |
| **Інфраструктура** | `docker-compose.yml` |

> **Важливе зауваження щодо документації**: v3.0-txt і PROJECT-PLAN-v3.md (v4.0) суперечать одне одному. v3.0 описує мікросервісну архітектуру з PostgreSQL; v4.0 вже ухвалила рішення "Variant A (Simple)" — усе в MariaDB. Код на диску відповідає v4.0. У кожному розділі нижче вказано, відносно якого документа існує конфлікт.

---

## Вісь 1 — API: in-process Frappe methods vs окремий FastAPI-проксі

### Що в дизайні (v3.0)

- Security API маршрутизує запити до трьох **окремих FastAPI-мікросервісів**: FSM Service, CMDB Service, AI Service — кожен зі своєю PostgreSQL-схемою.
- ERPNext обробляє лише CRM/Sales/Finance/Inventory/Projects.
- Кожен мікросервіс надає свій власний REST API; Security API агрегує.

### Що в дизайні (v4.0 / PROJECT-PLAN-v3.md)

- Security API — "тонкий proxy + JWT + RBAC".
- FSM/CMDB/AI-мікросервіси **видалені**, "все в Frappe".

### Що на диску

- `services/security-api/app/routes/proxy.py`: catch-all `@router.api_route("/api/v1/{path:path}")` → Frappe REST `/api/resource/{DocType}`. 10 DocType-маппінгів. Повертає **сирий** Frappe-формат.
- `services/security-api/app/routes/doctypes.py`: `/api/v2/*` — бізнес-логіка всередині FastAPI (розрахунок маржі, Quotation→PO→SI, warranty scan, scenario calculate). Це НЕ тонкий проксі.
- `services/security-api/app/routes/visits.py`, `mobile.py`, `banking.py`, `signatures.py`, `portal.py` — додаткові спеціалізовані маршрути.
- Окремих контейнерів FSM Service, CMDB Service, AI Service **немає** в `docker-compose.yml`.

### Тип розбіжності

| vs v3.0 | КОНФЛІКТ — мікросервіси не побудовані |
|---|---|
| vs v4.0 | ЧАСТКОВИЙ КОНФЛІКТ — проксі є, але містить бізнес-логіку (doctypes.py), тобто не є "тонким" |

### Варіанти узгодження

A. Прийняти v4.0 як еталон: перенести залишки бізнес-логіки з `doctypes.py` в Frappe-методи (`@frappe.whitelist()`), зробити proxy справді тонким.  
B. Повернутись до v3.0: побудувати FSM/CMDB як окремі FastAPI-сервіси з PostgreSQL (великий обсяг роботи).  
C. Гібрид: `doctypes.py` залишається в security-api, але переїздить у власний `business-logic-layer` між proxy та Frappe.

---

## Вісь 2 — Права: Frappe permission engine vs FastAPI-RBAC + автентифікація як Administrator

### Що в дизайні (v3.0 + v4.0)

- JWT + RBAC у Security API ✅
- Frappe permission engine застосовується до DocumentType-доступу — кожен користувач бачить лише "свої" документи.
- Інженер A не може отримати об'єкти, до яких не прикріплений.
- AI успадковує права поточного користувача.

### Що на диску

**`database.py` (рядки 12–26):** при першому запиті виконується `POST /api/method/login` з `frappe_username` (default: `"Administrator"`) + `frappe_password`. Отриманий `sid`-cookie кешується глобально (`_sid`) і використовується для **всіх** наступних запитів до Frappe незалежно від того, хто автентифікований у Security API.

**`proxy.py` (рядок 21):** паралельно використовує `token {frappe_api_key}:{frappe_api_secret}` — ключ рівня Administrator.

**`auth.py` (рядки 142–147):** при логіні `_default_role` призначає роль за ім'ям користувача (`Administrator → "owner"`), а **не** за актуальними ролями Frappe, які отримує лише при `/refresh`.

### Наслідки безпеки

> ⚠️ **КРИТИЧНИЙ НАСЛІДОК**: Frappe's permission engine **повністю обходиться**. Авторизований користувач з роллю `engineer` у Security API може отримати будь-який DocType через `proxy.py` запитом до Frappe, якщо тільки `proxy.py/_has_access` не заблокує — а цей check є лише для визначених `ROLE_PATH_PERMISSIONS` prefix'ів (не всіх маршрутів). Frappe-рівень row-level security (Engineer бачить лише свої заявки) не працює. Прямі запити до Frappe API ззовні (без Security API) повністю відкриті через Administrator-ключ.

### Тип розбіжності

| vs v3.0 і v4.0 | КОНФЛІКТ + БЕЗПЕКОВИЙ РИЗИК |
|---|---|

### Варіанти узгодження

A. Передавати JWT-identité в кожен запит до Frappe: логінитись у Frappe від імені кожного реального користувача (окремий SID per request/session) — Frappe permission engine починає працювати.  
B. Реалізувати повний RBAC-фільтр у Security API для кожного endpoint: перевіряти не лише path prefix, але й конкретні поля документа (engineer_id == current_user).  
C. Комбінація: user-level sid + документ-рівнева перевірка у Frappe hooks.  
D. Заблокувати пряме звернення до Frappe API ззовні (Traefik middleware) — мінімальне пом'якшення без виправлення кореня.

---

## Вісь 3 — Дата-модель: 20 спроєктованих DocType vs наявні

### Що в дизайні (v3.0)

v3.0 описує **PostgreSQL-таблиці** у схемах `fsm` і `cmdb`, та Frappe DocTypes лише для ERPNext-домену (Contract, ContractSLA).

### Що в дизайні (v4.0)

25 DocTypes у MariaDB через Frappe.

### Що на диску (`erpnext/security_erp/security_erp/doctype/`)

27 Frappe DocTypes:

| DocType (диск) | v3.0 PostgreSQL таблиця | v4.0 список | Статус |
|----------------|-------------------------|-------------|--------|
| Service Ticket | `fsm.tickets` | ✅ | ✅ MAPPED |
| Visit | `fsm.visits` | ✅ | ✅ MAPPED |
| Visit Photo | `fsm.visit_photos` | ✅ | ✅ MAPPED |
| Visit Material | `fsm.visit_materials` | ✅ | ✅ MAPPED |
| SLA Event | `fsm.sla_events` | ✅ | ✅ MAPPED |
| Maintenance Plan | `fsm.maintenance_plans` | ✅ | ✅ MAPPED |
| Warranty Case | `fsm.warranty_cases` | ✅ | ✅ MAPPED |
| Security Object | `cmdb.objects` | ✅ | ✅ MAPPED |
| Object Building | `cmdb.buildings` | ✅ | ✅ MAPPED |
| Object Floor | `cmdb.floors` | ✅ | ✅ MAPPED |
| Object Room | `cmdb.rooms` | ✅ | ✅ MAPPED |
| Equipment | `cmdb.equipment` | ✅ | ✅ MAPPED |
| Equipment Type | `cmdb.equipment_types` | ✅ | ✅ MAPPED |
| Equipment Relation | `cmdb.equipment_relations` | ✅ | ✅ MAPPED |
| Vendor | `cmdb.vendors` | ✅ | ✅ MAPPED |
| Contract | ERPNext DocType | ✅ | ✅ MAPPED |
| Contract Object | — | ✅ | ✅ (v4 only) |
| Estimate | — | ✅ | ✅ (v4 only) |
| Estimate Item | — | ✅ | ✅ (v4 only) |
| Estimate Template | — | ✅ | ✅ (v4 only) |
| Estimate Template Item | — | ✅ | ✅ (v4 only) |
| Installation Act | — | ✅ | ✅ (v4 only) |
| Installation Act Item | — | ✅ | ✅ (v4 only) |
| Material Reservation | — | ✅ | ✅ (v4 only) |
| Material Reservation Item | — | ✅ | ✅ (v4 only) |
| **Security Scenario** | **—** | **—** | ⚠️ EXTRA (не в жодному плані) |
| **Security Scenario Item** | **—** | **—** | ⚠️ EXTRA (не в жодному плані) |

**ВІДСУТНІ на диску (з v3.0 проекту):**

| Відсутній елемент | Причина відсутності |
|---|---|
| `fsm.visit_checklists` / `fsm.sla_policies` | Не перенесено у v4.0 |
| `cmdb.network` / `cmdb.vlan` / `cmdb.ip_addresses` | Phase 2+ |
| `cmdb.config_backups` | Phase 2+ (Oxidized) |
| `ai.*` (knowledge_base, embeddings, conversations, ai_reports) | Phase 2+ |
| `audit.audit_log` | Відсутній повністю |
| `integration.event_outbox` | Відсутній повністю |
| UUID v7 primary keys | Frappe використовує власну naming series |
| BaseEntity soft-delete fields | Frappe використовує `docstatus` |

### Тип розбіжності

| vs v3.0 | КОНФЛІКТ (PostgreSQL замінено на MariaDB DocTypes, схема змінена) |
|---|---|
| vs v4.0 | В ОСНОВНОМУ СУМІСНЕ + 2 зайвих DocType + відсутні чеклисти і SLA policy |

---

## Вісь 4 — Gateway: RIAD-DTO єдина точка vs proxy.py catch-all

### Що в дизайні (v3.0)

- Єдиний стандартний формат відповіді: `{ success, data }` або `{ success, error: {code, message} }`.
- Circuit Breaker (tenacity або pybreaker): при 5 помилках → open 30 сек.
- Rate Limiting: Redis sliding window ✅
- Tracing: кожен запит отримує `trace_id`, що передається через всі сервіси.
- API versioning: `/api/v1/` зі збереженням 24 місяці.

### Що на диску

| Вимога v3.0 | Реалізація | Статус |
|---|---|---|
| DTO `{success, data}` | `/api/v2/*` — так; `/api/v1/*` — повертає **сирий** Frappe-формат (інший) | ⚠️ ЧАСТКОВО |
| Circuit Breaker | `requirements.txt` не містить tenacity/pybreaker | ❌ ВІДСУТНІЙ |
| Rate Limiting | Redis, 1000 req/хв per IP, в `main.py` | ✅ |
| trace_id | Немає в коді | ❌ ВІДСУТНІЙ |
| `/api/v1/` — поточна версія | v1 позначена як deprecated (`X-Deprecated: true` header); основний API — `/api/v2/` | ⚠️ КОНФЛІКТ версіонування |

### Тип розбіжності

| vs v3.0 | КОНФЛІКТ (немає Circuit Breaker, trace_id, DTO непослідовне, версіонування інвертоване) |
|---|---|
| vs v4.0 | В ОСНОВНОМУ СУМІСНЕ (thin proxy + JWT) |

### Варіанти узгодження

A. Додати `tenacity` circuit breaker для httpx-клієнта (мінімальне зусилля).  
B. Стандартизувати відповіді: або прийняти сирий Frappe-формат як стандарт, або обгорнути `/api/v1/` теж у `{success, data}`.  
C. Додати `X-Trace-ID` middleware в `main.py` (незначне зусилля).

---

## Вісь 5 — AI: провайдер-агностичний + анонімізація vs прямий ANTHROPIC_API_KEY

### Що в дизайні (v3.0)

- LLM Abstraction Layer: OpenAI → fallback Anthropic → Google Gemini → Ollama.
- Circuit Breaker при недоступності LLM.
- AI НЕ в Phase 1 (MVP). Розробка починається з Phase 2.
- AI НІКОЛИ не має прямого доступу до БД. Дані через Tool Calls → API Layer.
- AI успадковує RBAC поточного користувача.
- Захист від Prompt Injection.
- Логування всіх AI-запитів (промпт, контекст, відповідь, вартість, модель).
- Ліміти вартості по користувачу/відділу/місяцю.
- Anonymization перед відправкою до зовнішнього LLM.

### Що на диску (`services/security-api/app/services/ai_service.py`)

```python
import anthropic, json
class AIService:
    def __init__(self):
        self.api_key = settings.anthropic_api_key
    async def generate_estimate(self, ta: str) -> dict:
        ...
        client = anthropic.Anthropic(api_key=self.api_key)
        msg = client.messages.create(model="claude-sonnet-4-6", ...)
```

| Вимога v3.0 | Реалізація | Статус |
|---|---|---|
| Phase 2+ only | Активний у Phase 1, вже використовується | ❌ КОНФЛІКТ |
| LLM Abstraction Layer | Один провайдер (Anthropic), модель hardcoded | ❌ ВІДСУТНІЙ |
| Fallback провайдер | Немає | ❌ ВІДСУТНІЙ |
| AI не має прямого доступу до БД | `_catalog()` викликає `frappe_get("/api/resource/Item", ...)` як Administrator | ❌ КОНФЛІКТ |
| RBAC наслідування | AI отримує каталог без перевірки прав поточного користувача | ❌ КОНФЛІКТ |
| Anonymization | Немає | ❌ ВІДСУТНЯ |
| Prompt Injection захист | Немає | ❌ ВІДСУТНІЙ |
| Логування AI-запитів | Немає | ❌ ВІДСУТНЄ |
| Ліміти вартості | Немає | ❌ ВІДСУТНІ |
| RAG / Qdrant | Немає | ❌ ВІДСУТНІЙ |

**Додатково**: `docker-compose.yml` має env-змінні `LLM_URL` і `LLM_MODEL` — натяк на майбутній abstraction layer, але поточний код їх не використовує.

> ⚠️ **БЕЗПЕКОВИЙ НАСЛІДОК**: Дані бізнес-каталогу (item_code, item_name, ціни) відправляються до зовнішнього Anthropic API без анонімізації та без логу. GDPR/бізнес-конфіденційність не захищені.

### Тип розбіжності

| vs v3.0 | КОНФЛІКТ по всіх субпунктах |
|---|---|

---

## Вісь 6 — Відсутнє повністю

| Компонент (з v3.0) | Статус в docker-compose | Статус у коді | Фаза за v3.0 |
|---|---|---|---|
| FSM Service (FastAPI + PostgreSQL) | ❌ ABSENT | ❌ ABSENT | Phase 1 |
| CMDB Service (FastAPI + PostgreSQL) | ❌ ABSENT | ❌ ABSENT | Phase 1 |
| AI Service (окремий контейнер) | ❌ ABSENT | Вбудовано в security-api | Phase 2+ |
| PostgreSQL 5 схем (fsm/cmdb/ai/integration/audit) | Лише n8n-БД | — | Phase 1 |
| HashiCorp Vault (або Docker Secrets) | ❌ ABSENT | `.env` файл | Phase 1 (security req) |
| PII Anonymization | ❌ ABSENT | ❌ ABSENT | Phase 2+ (AI) |
| Multi-provider LLM + failover | ❌ ABSENT | ❌ ABSENT | Phase 2+ |
| Qdrant (Vector DB) | ❌ ABSENT | ❌ ABSENT | Phase 2+ |
| RAG / Knowledge Base | ❌ ABSENT | ❌ ABSENT | Phase 2+ |
| Whisper (Audio) | ❌ Не згадується в жодному дизайн-документі | — | — (поза scope) |
| Offline sync `/mobile/sync` | ❌ ABSENT | ❌ ABSENT | Phase 4 |
| Next.js PWA | ❌ Не в жодному дизайн-документі | — | — (поза scope) |
| Estimate Calculator | Частково: `scenario_service.py`, `calculate_scenario` endpoint; `eval()` на формулах (risk) | ⚠️ ЧАСТКОВО | Phase 1 |
| Visit Checklists (DocType) | ❌ ABSENT | ❌ ABSENT | Phase 1 |
| SLA Policy (DocType/таблиця) | ❌ ABSENT | Параметри в Service Ticket? | Phase 1 |
| NATS publishers/consumers | ✅ Контейнер є | ❌ Жоден сервіс не публікує/слухає | Phase 1 |
| Oxidized (Config Backup) | ❌ ABSENT | ❌ ABSENT | Phase 2+ |
| Neo4j | ❌ ABSENT | ❌ ABSENT | Phase 3+ |
| MFA (TOTP) | ❌ ABSENT | ❌ ABSENT | Phase 1 (security req) |
| Audit Log (таблиця/DocType) | ❌ ABSENT | ❌ ABSENT | Phase 1 (security req) |
| audit.audit_log events | ❌ ABSENT | ❌ ABSENT | Phase 1 |
| integration.event_outbox | ❌ ABSENT | ❌ ABSENT | Phase 1 |
| Android App (Flutter) | — | `android-app/` директорія з кодом | Phase 4 |
| Watchtower | ❌ ABSENT у поточному docker-compose | — | Phase 1 |

**Примітка щодо NATS**: контейнер запущений, `telegram-service` підключається до нього (`NATS_URL` env), але в `services/security-api/` жодного NATS-клієнта не знайдено. Шина подій фізично є, але не використовується.

---

## Вісь 7 — Назва app: riad vs security_erp

### Що в дизайні

v3.0: жодної специфічної назви Python-пакету.  
v4.0 / PROJECT-PLAN-v2: директива "Працювати в `/home/joker/RIAD CRM/`"; docker-compose монтує `./security_erp_app`.

### Що на диску

| Місце | Значення |
|---|---|
| `erpnext/security_erp/security_erp/hooks.py` | `app_name = "security_erp"` |
| `erpnext/security_erp/security_erp/security_erp/__init__.py` | Python-пакет: `security_erp` |
| `docker-compose.yml` volume | `./security_erp_app:/home/frappe/frappe-bench/apps/security_erp_app` |
| `docker-compose.yml` command (erpnext-backend) | реєструє `security_erp_app` в `apps.txt`, `pip install -e .../apps/security_erp_app` |
| Репозиторій root | Директорії `security_erp_app/` **немає** (код — в `erpnext/security_erp/`) |

### Наслідки конфлікту

1. Назва директорії в контейнері (`security_erp_app`) ≠ `app_name` в hooks.py (`security_erp`). Frappe реєструє додаток за назвою директорії, але Python-imports використовують `security_erp`. Залежно від конкретної Frappe-версії — або тихий збій, або конфлікт імпортів.
2. `docker-compose.yml` монтує `./security_erp_app` — директорії в репозиторії **немає**. Отже, або production сервер має файли в іншому layout, або volume-mount silent fails → контейнер не завантажує кастомний код.
3. `README.md` та PROJECT-PLAN документи не містять чіткої інструкції де розміщувати директорію.

### Тип розбіжності

| КОНФЛІКТ — різні імена пакету між hooks.py, docker-compose volume, та фактичною структурою репозиторію |
|---|

### Варіанти узгодження

A. Перейменувати volume mount: `./erpnext/security_erp:/home/frappe/frappe-bench/apps/security_erp` (синхронізувати з hooks.py).  
B. Перейменувати код: перемістити `erpnext/security_erp/` → `security_erp_app/` та оновити hooks.py `app_name = "security_erp_app"` та всі `security_erp.*` imports.  
C. Зберегти поточний layout, але додати symlink або скрипт розгортання, що копіює в правильну директорію.

---

## Зведена таблиця: вісь → рекомендований мінімальний крок узгодження (варіанти, не рішення)

| Вісь | Тип | Мінімальний крок A | Мінімальний крок B |
|------|-----|-------------------|-------------------|
| **1. API pattern** | КОНФЛІКТ (v3 vs диск) | Прийняти v4.0 як еталон; задокументувати рішення в ADR | Перенести `doctypes.py` business logic у Frappe `@whitelist` методи |
| **2. Права / Auth** | КОНФЛІКТ + БЕЗПЕКА | Реалізувати user-level Frappe session замість глобального Administrator SID | Додати document-level фільтр в proxy (engineer бачить лише свої doc) |
| **3. Дата-модель** | КОНФЛІКТ (v3) / СУМІСНЕ (v4) | Зафіксувати v4.0 як вибраний дата-патерн; задокументувати відсутні DocTypes (Checklist, SLA Policy) як backlog | Додати Audit Log DocType (мінімум для security events) |
| **4. Gateway DTO** | КОНФЛІКТ | Стандартизувати `/api/v1/` відповіді в `{success, data}` або офіційно deprecated | Додати `tenacity` Circuit Breaker + `X-Trace-ID` middleware |
| **5. AI** | КОНФЛІКТ + БЕЗПЕКА | Заборонити AI доступ до Item-каталогу з Administrator; передавати лише знеособлені item_code | Додати логування AI-запитів (промпт, модель, час, user_id) |
| **6. Відсутнє** | ВІДСУТНЄ | Визначити пріоритет: NATS-consumers (вже є контейнер), Audit Log, MFA | Vault або Docker Secrets для API ключів (поточний .env — ризик) |
| **7. Назва app** | КОНФЛІКТ | Виправити volume mount в docker-compose: `./erpnext/security_erp` → `/apps/security_erp` | Перемістити код у `security_erp_app/` та уніфікувати всі imports |

---

_Звіт складено на основі читання коду та документації без внесення змін. Вибір напряму узгодження залишається за власником._
