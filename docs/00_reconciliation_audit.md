# 00 Reconciliation Audit — RIAD Smart System vs Security ERP Platform

> **Дата:** 2026-06-21  
> **Мета:** Чесна карта розходжень між цільовою архітектурою (docs/, Фази 1–3) і реалізованим кодом  
> **Метод:** Прочитано docs/01–03, hooks.py, doctype/*, routes/*, services/*, docker-compose.yml  
> **Рішення — НЕ обираються тут.** Кожна вісь завершується варіантами, не вибором.

---

## Вісь 1 — API: in-process whitelisted-методи vs FastAPI-проксі

### Що в дизайні (01_architecture.md, 03_api_ai_architecture.md)
RIAD API = **whitelisted-методи custom app** усередині Frappe-сайту. Фронтенд → HTTPS → `POST /api/method/riad.api.v1.<module>.<method>` → метод перевіряє JWT → `frappe.set_user()` → **in-process Frappe ORM**. Жодного мережевого хопу між «RIAD» і «ERPNext» — це один процес, одна транзакційна межа.

### Що на диску
Окремий Docker-контейнер `security-api` (FastAPI, порт 8000 зовні). Кожен запит:
- проходить JWT-верифікацію у FastAPI
- потім іде **окремим HTTP-запитом** через `httpx.AsyncClient` до `erpnext-backend:8000`
- автентифікація до Frappe — через SID-cookie або API-ключ (`token KEY:SECRET`), залежно від маршруту

Маршрути: `/api/v2/*` — типізовані FastAPI-ендпоінти (auth, visits, doctypes, mobile, signatures, banking, portal, public\_api); `/api/v1/*` — catch-all proxy через `proxy.py`.

### Тип: **КОНФЛІКТ (фундаментальний)**

| Параметр | Дизайн | Диск |
|---|---|---|
| Де живе API | Python-методи всередині Frappe app | Окремий FastAPI-контейнер |
| Зв'язок з ERPNext | In-process ORM | HTTP httpx через мережу Docker |
| Транзакційна межа | Одна (Frappe DB) | Дві (FastAPI + Frappe кожен окремо) |
| Деплой | Один образ (bench) | Два Docker-образи |

### Варіанти узгодження
**A.** Залишити FastAPI як зовнішній gateway (поточне); визнати відхилення від дизайну свідомим рішенням. Зафіксувати в DECISIONS.  
**B.** Перенести API-логіку у whitelisted Frappe-методи; прибрати security-api як окремий сервіс (наслідок: втрата FastAPI DX, але відповідність дизайну).  
**C.** Гібрид: security-api лишається для аутентифікації і gateway, але бізнес-логіка переноситься у Frappe-методи; security-api викликає конкретні whitelisted-методи, а не загальний REST `/api/resource`.

---

## Вісь 2 — Права: Frappe permission engine vs FastAPI-RBAC + Administrator-обхід

### Що в дизайні
JWT **лише автентифікує** і резолвить у конкретного Frappe User. Після `frappe.set_user(sub)` **усі ORM-операції виконуються в контексті цього user-а**. Frappe permission engine — єдине джерело прав. JWT-claim `roles` — інформативний (для UI), **не** авторитетний. Рядки `User Permission` Frappe забезпечують «свої об'єкти».

### Що на диску
`app/core/database.py` — `_get_sid()` логіниться у Frappe як **Administrator** (`settings.frappe_username` / `settings.frappe_password`) і кешує SID. Всі подальші запити до Frappe йдуть від імені Administrator. Frappe permission engine **не перевіряє нічого** — Administrator має доступ до всього.

`app/auth/permissions.py` — FastAPI-RBAC: `Role` enum (9 ролей) + `Permission` enum (19 дозволів) + `ROLE_PERMISSIONS` dict. Права вирішує FastAPI-код, **не** Frappe.

`app/routes/auth.py` — роль при логіні хардкодиться через `_default_role()`:
```python
def _default_role(username: str) -> str:
    defaults = {"Administrator": "owner", "joker": "service_manager"}
    return defaults.get(username, "viewer")
```
При refresh — намагається отримати роль через `frappe_get("/api/resource/User/{id}")`, але якщо Frappe повертає порожній список ролей — fallback `"viewer"`.

### Тип: **КОНФЛІКТ + БЕЗПЕКОВИЙ НАСЛІДОК**

**Безпековий наслідок:** Будь-який автентифікований користувач FastAPI фактично виконує операції у Frappe від імені Administrator. Якщо FastAPI-RBAC має баг або вразливість (помилкова перевірка, JWT-помилка), другий рубіж (Frappe permissions) відсутній. Frappe row-level permissions (`User Permission`), field-level permissions (`permlevel`) і document-level permissions не діють.

| Параметр | Дизайн | Диск |
|---|---|---|
| Хто ензфорсить права | Frappe permission engine | FastAPI-RBAC (Python dict) |
| Frappe-контекст запиту | `frappe.set_user(конкретний user)` | Administrator (SID-cookie) |
| Field-level (`permlevel`) | Frappe ензфорсить автоматично | Не ензфорситься — Administrator бачить все |
| Row-level (`User Permission`) | Frappe ензфорсить | Не ензфорситься |
| Призначення ролі | Frappe Role of User | Хардкод `_default_role()` або fallback з User.roles |
| Аудит Frappe | Так (Version log за user) | Логи тільки як Administrator |

### Варіанти узгодження
**A.** Залишити FastAPI-RBAC як єдиний рубіж; документувати ризик; додати чіткий список дозволів per endpoint; посилити тести RBAC.  
**B.** Змінити `database.py` — замість Admin SID виконувати запити від імені конкретного Frappe User (API-ключ per user або `sudo`-механізм); тоді Frappe permission engine стає другим рубіжем.  
**C.** Переробити на Frappe whitelisted-методи (вісь 1-B) — тоді `frappe.set_user` природній і двошарове ензфорсення відновлюється.

---

## Вісь 3 — Дата-модель: 20 спроєктованих DocType vs наявні

### Що в дизайні (02_data_model.md)
20 кастомних DocType (+ child-таблиці) у семи модульних групах. Нижче — зіставлення.

### Що на диску (`erpnext/security_erp/security_erp/security_erp/doctype/`)

| # | DocType дизайну | Наявне на диску | Тип |
|---|---|---|---|
| 1 | `Site Brief` | — | **ВІДСУТНЄ** |
| 2 | `Calculator Submission` | — | **ВІДСУТНЄ** |
| 3 | `Object Passport` | — | **ВІДСУТНЄ** |
| 4 | `Passport Client Release` | — | **ВІДСУТНЄ** |
| 5 | `Installation Map` (+Mount Point, Cable Route) | — | **ВІДСУТНЄ** |
| 6 | `Scenario` (+Scenario Item) | `security_scenario` + `security_scenario_item` | ~ЧАСТКОВЕ (назва, концепція збігаються; поля RIAD: `qty_rule`, `qty_factor` — перевірити) |
| 7 | `AI Estimate` (+AI Estimate Line) | `estimate` + `estimate_item` + `estimate_template` + `estimate_template_item` | ~ЧАСТКОВЕ (без AI-статусів: origin/variant/reviewed_by, без permlevel на ціні) |
| 8 | `AI Provider` | — | **ВІДСУТНЄ** |
| 9 | `AI Request Log` | — | **ВІДСУТНЄ** |
| 10 | `Remote Inspection` | — | **ВІДСУТНЄ** |
| 11 | `Engineer Visit` (+Visit Material, Visit Photo) | `visit` + `visit_material` + `visit_photo` | ~ЧАСТКОВЕ (немає sync-метаданих: `riad_version`, `riad_deleted`, `client_uuid`) |
| 12 | `Checklist Template` (+child) | — | **ВІДСУТНЄ** |
| 13 | `Checklist Instance` (+child) | — | **ВІДСУТНЄ** |
| 14 | `Media Asset` | `visit_photo` (вузько) | **ЧАСТКОВЕ** (немає: drive_file_id, transcription, ai_allowed, tombstone) |
| 15 | `Vault Entry` | — | **ВІДСУТНЄ** |
| 16 | `Vault Access Enrollment` | — | **ВІДСУТНЄ** |
| 17 | `Vault Audit Log` | — | **ВІДСУТНЄ** |
| 18 | `Access Transfer Act` | `warranty_letter` (інше призначення) | **КОНФЛІКТ НАЗВ** (warranty\_letter = гарантійний лист клієнту, не акт передачі доступів Vault) |
| 19 | `Service Request` | `service_ticket` | ~ЧАСТКОВЕ (без vault\_audit\_ref, без offline-sync полів) |
| 20 | `RIAD Device Session` | — | **ВІДСУТНЄ** (JWT blacklist у Redis є в auth/dependencies.py, але DocType відсутній) |
| 21 | `RIAD Audit Log` | — | **ВІДСУТНЄ** |
| 22 | `Sync Conflict` | — | **ВІДСУТНЄ** |

**На диску є, але НЕМАЄ в дизайні Фаз 1–3:**

| DocType на диску | Призначення | Статус у дизайні |
|---|---|---|
| `contract` + `contract_object` | Договір | Згадується у Фазі 6 (ризики), не спроєктовано |
| `installation_act` + `installation_act_item` | Акт виконаних робіт | Не спроєктовано |
| `maintenance_plan` | Плани ТО | Не спроєктовано |
| `material_reservation` | Резервування матеріалів | Не спроєктовано |
| `sla_event` | Відстеження SLA | Не спроєктовано |
| `warranty_case` | Гарантійний випадок | Не спроєктовано (є Warranty Claim ERPNext) |
| `security_object` | Об'єкт | Частково = Object Passport, але без PII/Geo |
| `equipment` + `equipment_type` + `equipment_relation` | CMDB | Не спроєктовано як окремий DocType |
| `vendor` | Постачальник | ERPNext `Supplier` є стандартним |
| `object_building` + `object_floor` + `object_room` | Будівля/поверх/кімната | Не спроєктовано |

### Тип: **ЧАСТКОВІ ВІДПОВІДНОСТІ + СУТТЄВІ ВІДСУТНОСТІ + ВЛАСНІ РОЗШИРЕННЯ**

### Варіанти узгодження
**A.** Визнати, що наявні DocType = власна FSM/CMDB-реалізація; проєктні Vault/AI/Sync DocType спроєктувати окремо поверх.  
**B.** Провести mapping: `security_object` → переростити у `Object Passport`; `security_scenario` → зберегти як базу для `Scenario`; `estimate` → розширити до `AI Estimate`.  
**C.** Підготувати Фазу 2-реалізацію як нові DocType поруч, зберігши наявні як legacy.

---

## Вісь 4 — Gateway: RIAD-DTO антикорупційний адаптер vs proxy.py catch-all

### Що в дизайні
`riad.erpnext_gateway` — єдиний Python-модуль, що інкапсулює доступ до стандартних DocType ERPNext. 7 операцій: `create_quotation_from_estimate`, `create_sales_order`, `get_item_pricing`, `record_serial_scan`, `link_warranty_claim`, `reconcile_payment`, `resolve_customer`. RIAD-DTO замість сирих Frappe-документів. CI-лінт на згадки ERPNext DocType поза gateway.

### Що на диску
`services/security-api/app/routes/proxy.py` — catch-all HTTP-проксі:
```python
FRAPPE_DOCTYPE_MAP = {
    "/api/v1/tickets": "Service Ticket",
    "/api/v1/visits": "Visit",
    ...  # 10 prefix-to-doctype mappings
}
```
Маршрут `/api/v1/{path:path}` транслює URL-префікс у Frappe DocType і відправляє сирий HTTP-запит до `/api/resource/{doctype}`. Відповідь від Frappe передається без трансформації (тільки додається `X-Deprecated: true`).

Інші route-файли (`visits.py`, `banking.py`, `portal.py` тощо) викликають `frappe_get/post/put/delete` напряму без жодного DTO-шару. Немає концепції RIAD-DTO. Немає антикорупційної межі.

### Тип: **КОНФЛІКТ**

| Параметр | Дизайн | Диск |
|---|---|---|
| Ізоляція від ERPNext API-змін | Так (gateway інкапсулює) | Ні (прямий `/api/resource/`) |
| Трансформація даних | RIAD-DTO | Сирі Frappe JSON |
| Покриття операцій | 7 типізованих функцій | Генеричний catch-all + прямі httpx-виклики |
| CI-перевірка межі | Лінт-правило (план) | Немає |

### Варіанти узгодження
**A.** Залишити proxy.py як legacy `/api/v1`; нові `/api/v2` ендпоінти розробляти з явними DTO-шарами у FastAPI service-класах.  
**B.** Виділити `gateway.py` у security-api з 7+ операціями — що відповідає духу ACL-адаптера, хоча й через HTTP.  
**C.** Прибрати proxy.py; всі маршрути мають типізовані FastAPI-ендпоінти з Pydantic DTO.

---

## Вісь 5 — AI: провайдер-агностичний + анонімізація vs прямий Anthropic

### Що в дизайні
- Провайдер-агностичний інтерфейс адаптера: `complete(task, payload, params)` + `health_check()`
- `AI Provider` DocType (no-code реєстр провайдерів з пріоритетом)
- Circuit Breaker у Redis (спільний між воркерами, атомарний)
- Failover ланцюг: основний → резервний → ручний (Scenario)
- Шар анонімізації (мінімізація-first): вхід — `Site Brief` (неперсональна сутність), NER — defense-in-depth, fail-closed
- Людський gate (показати точний payload → підтвердити)
- Логування лише анонімізованого payload у `AI Request Log`

### Що на диску (`services/security-api/app/services/ai_service.py`)
```python
import anthropic, json
class AIService:
    def __init__(self):
        self.api_key = settings.anthropic_api_key

    async def generate_estimate(self, ta: str) -> dict:
        # ta = сирий текст ТЗ (вхід без анонімізації)
        catalog = await self._catalog(ta)
        client = anthropic.Anthropic(api_key=self.api_key)
        msg = client.messages.create(model="claude-sonnet-4-6", ...)
        return json.loads(msg.content[0].text)
```

- Один провайдер: Claude (жорстко закодований `"claude-sonnet-4-6"`)
- Жодного Circuit Breaker
- Жодного failover
- Жодної анонімізації — сирий текст ТЗ (`ta: str`) іде напряму в Claude
- Вхід — не `Site Brief`, а довільний текст
- Жодного людського gate
- Жодного `AI Request Log`
- `ANTHROPIC_API_KEY` — у `.env`, читається через `settings.anthropic_api_key`

### Тип: **КОНФЛІКТ (суттєвий)**

| Параметр | Дизайн | Диск |
|---|---|---|
| Провайдери | Gemini / OpenAI / Claude (конфіговані) | Тільки Claude |
| Failover | Основний→резервний→ручний | Немає (помилка = 500) |
| Circuit Breaker | Redis, спільний | Немає |
| Анонімізація | Мінімізація-first + NER fail-closed | Немає |
| Вхід | Site Brief (неперсональний) | Сирий текст ТЗ |
| Людський gate | Є | Немає |
| Логування | AI Request Log (анонімізоване) | Немає |
| Ключі | Поза БД (секрети сервера) | `.env` (менш суворо, але прийнятно) |

### Варіанти узгодження
**A.** Прийняти поточний Claude-only як MVP; додати абстрактний `AIProvider` клас у services/ для майбутніх провайдерів; окремим кроком — анонімізацію та Circuit Breaker.  
**B.** Реалізувати `AI Provider` DocType + адаптери + Circuit Breaker поетапно; додати мінімальний PII-скрубер перед зовнішніми викликами.  
**C.** Повний дизайн — всі 13 рішень Фази 3 реалізувати повністю.

---

## Вісь 6 — Відсутнє повністю

Нижче — компоненти, спроєктовані як обов'язкові у Фазах 1–3, яких **немає на диску взагалі**.

| Компонент | Фаза | Що є на диску | Вплив |
|---|---|---|---|
| **Password Vault** (Vault Entry + Enrollment + Audit Log + Access Transfer Act) | 1.5, 2 | — | Ключова диференційна фіча для клієнтів — відсутня повністю |
| **Шар анонімізації PII** (NER, fail-closed, людський gate) | 1, 3 | — | Поточний AI-виклик передає сирий PII зовнішньому провайдеру |
| **Мультипровайдер AI + failover** (AI Provider DocType, адаптери Gemini/OpenAI) | 3 | Тільки Claude | Будь-яка недоступність Claude = відмова функції без деградації |
| **Circuit Breaker (Redis)** | 3 | — | Немає graceful degradation до ручного режиму |
| **Whisper self-hosted STT** | 1, 3 | Немає контейнера в docker-compose.yml | Голосові нотатки/транскрипція недоступні |
| **Offline-sync протокол** (push/pull, UUID-name, tombstones, Sync Conflict) | 3 | — | Flutter offline-first неможливий |
| **Next.js PWA** (веб-кабінет) | 1, 4 | Тільки ERPNext desk UI | Клієнтська поверхня — ERPNext, а не кастомний PWA |
| **Публічний калькулятор** (детермінований, captcha, rate-limit) | 3 | `public_api.py` — заглушки без логіки | Лід-форма та AI-попередня оцінка не реалізовані |
| **RIAD Device Session DocType** | 2, 3 | Redis blacklist є; DocType немає | Refresh-token ротація і per-device revoke не реалізовані |
| **Антикорупційний адаптер (riad.erpnext_gateway)** | 3 | HTTP proxy catch-all | Ізоляція від ERPNext v15→v16 змін відсутня |
| **CI import-linter** (Vault↔AI + ERPNext-DocType поза gateway) | 3 | Немає | Межі не перевіряються автоматично |
| **Flutter Android app** | 1 | — | Мобільний клієнт не існує |

---

## Вісь 7 — Назва app: riad vs security\_erp

### Що в дизайні
Custom app називається **`riad`**. API namespace: `riad.api.v1.*`. Whitelisted-методи: `riad.api.v1.auth.login` тощо. Package: `riad`.

### Що на диску
```python
# hooks.py
app_name = "security_erp"
app_title = "Security ERP"
app_publisher = "Riad Smart Systems"
```
DocType module: `Security ERP`. API (FastAPI): `security-api`. Всі шляхи: `security_erp.*`.

### Тип: **КОНФЛІКТ (косметичний + namespace)**

Не блокує функціональність. Але при переході до whitelisted Frappe-методів (вісь 1) конфлікт стане практичним: або перейменовувати, або адаптувати документацію.

### Варіанти узгодження
**A.** Залишити `security_erp` — воно вже встановлене на production, renaming потребує міграції.  
**B.** Перейменувати на `riad` — якщо сайт ще не у production або є час на міграцію.  
**C.** Залишити `security_erp` як app\_name; у майбутніх Frappe whitelisted-методах використовувати namespace `security_erp.api.v1.*`, а документацію оновити.

---

## Зведена таблиця — варіанти мінімального кроку узгодження

| Вісь | Тип | Варіанти мінімального кроку (без вибору) |
|---|---|---|
| **1. API** | КОНФЛІКТ (фундаментальний) | A: Зафіксувати FastAPI як свідоме відхилення в DECISIONS; B: Перенести бізнес-логіку у Frappe whitelisted-методи; C: Гібрид — gateway залишається, але не проксіює сирий REST |
| **2. Права** | КОНФЛІКТ + БЕЗПЕКА | A: Посилити FastAPI-RBAC, документувати ризик; B: Виконувати Frappe-запити від імені конкретного user (не Administrator); C: Перехід на whitelisted-методи з `frappe.set_user` |
| **3. Дата-модель** | ЧАСТКОВІ + ВІДСУТНІ + ВЛАСНІ | A: Визнати security\_erp DocType як FSM/CMDB-шар, будувати Vault/AI/Sync окремо; B: Mapping і розширення наявних; C: Нові DocType Фази 2 поруч зі старими |
| **4. Gateway** | КОНФЛІКТ | A: Залишити proxy.py legacy; v2 — типізовані DTO; B: `gateway.py` у security-api; C: Прибрати proxy.py повністю |
| **5. AI** | КОНФЛІКТ (суттєвий) | A: MVP Claude + додати абстракцію для майбутніх провайдерів; B: AI Provider DocType + адаптери + Circuit Breaker; C: Повна реалізація Фази 3 AI |
| **6. Відсутнє** | ВІДСУТНЄ | A: Пріоритизувати Vault (безпека) і анонімізацію (GDPR); B: Пріоритизувати offline-sync (Flutter); C: Відкласти все до MVP-3 milestone |
| **7. Назва** | КОНФЛІКТ (namespace) | A: Залишити security\_erp навічно; B: Перейменувати до першого production-деплою; C: Залишити security\_erp, оновити документацію |

---

*Звіт завершено. Рішення — на розсуд власника.*

---

## Доповнення після звірки з DECISIONS.md / 015 / 04 / 05 / 06

> **Дата звірки:** 2026-06-21  
> **Прочитано:** docs/DECISIONS.md (повністю, включно з блоком «Напрям B1»), docs/015_architecture_audit.md, docs/04_ux_map.md, docs/05_dev_plan.md, docs/06_risks_scaling_audit.md.  
> **Метод:** звірення кожного з 7 «Що в дизайні» проти щойно прочитаних документів; перевірка C1/H4; перевірка реєстру ризиків.

---

### D1. Головна знахідка: DECISIONS.md містить блок «Напрям B1», якого НЕ БУЛО в первинному read-списку аудиту

Первинний аудит читав лише `01_architecture.md`, `02_data_model.md`, `03_api_ai_architecture.md`. Файл `DECISIONS.md` містить два блоки **після** блоку Фази 6:

- **«Напрям B»** — власник обрав залишити FastAPI-гейтвей, оновити дизайн під нього.
- **«Напрям B1»** (найновіший) — уточнення: per-user делегування замість Administrator-обходу; B2 (переписати модель прав у Python) — відхилено.

Наслідок: **більшість «КОНФЛІКТ» у первинному аудиті — це стан до рішення власника.** Після B1 ці конфлікти отримали обраний напрям. Нижче — постісь.

---

### D2. Вісь 1 (API) — напрям вже обраний

Первинний аудит: «КОНФЛІКТ (фундаментальний)» — дизайн Фаз 1/3 вимагав in-process ORM, диск має FastAPI.

**Що в DECISIONS.md B1:**
> «ВІСЬ 1 (API): RIAD API = FastAPI-гейтвей (security-api) перед Frappe. Скасовує рішення Фази 1 «in-process без HTTP-хопу». Свідомо приймаємо два процеси, дві транзакційні межі.»

**Статус після звірки:** Не конфлікт. Власник свідомо обрав FastAPI. Первинний аудит коректно описав розходження; B1 є його резолюцією.

**Додатково** (з 05_dev_plan.md): E1 і E2 у плані Фази 5 використовують простір `riad.api.v1.*` та in-process ORM — план писався до B1 і є **застарілим** відносно нього. DECISIONS.md B1 містить: «Розблоковує: переписаний build playbook під B1» — є окремий файл `docs/07_build_playbook.md`, який не входив у первинний read-список аудиту.

---

### D3. Вісь 2 (Права) — напрям вже обраний, B2 відхилено явно

Первинний аудит: «КОНФЛІКТ + БЕЗПЕКА» з варіантами A/B/C.

**Що в DECISIONS.md B1:**
> «ВІСЬ 2 (права/БЕЗПЕКА) — B1: FastAPI автентифікується до Frappe ВІД ІМЕНІ РЕАЛЬНОГО КОРИСТУВАЧА (делегована сесія або персональний API-ключ), НЕ від Administrator. Frappe permission engine лишається авторитетним ензфорсером. B2 (переписати модель прав у Python) — відхилено: дублювання безпекової моделі ERPNext + ризик розсинхрону = ризик витоку. Роль при логіні — з реального Frappe User.roles, без хардкоду `_default_role()`.»

**Статус після звірки:** Напрям обрано — варіант B (per-user делегування). Хардкод `_default_role()` і Administrator-обхід підлягають усуненню. Варіант B2 (дублювання моделі в Python) — явно відхилений.

**Відкрите питання B1 (не вирішено):** точний механізм per-user делегування: кешована Frappe-сесія per-user **vs** персональні API-ключі `token KEY:SECRET` per user → вирішується технічно в «сесії R1».

**З 06_risks_scaling_audit.md:** R-H7 (ризик розсинхрону прав) має DoD-прив'язку: E2 (CRUD ензфорсить permlevel 1; PermissionError→PERM-DENIED) + E1 (field-level перевірка двома ролями). Аудит не посилався на цю прив'язку.

---

### D4. Вісь 3 (Дата-модель) — union-підхід формалізовано в B1

Первинний аудит: «ЧАСТКОВІ ВІДПОВІДНОСТІ + СУТТЄВІ ВІДСУТНОСТІ + ВЛАСНІ РОЗШИРЕННЯ».

**Що в DECISIONS.md B1:**
> «ВІСЬ 3 (дата-модель): union — 11 наявних доменних DocType + 15 відсутніх спроєктованих + узгодження 3 перетинів (security_scenario→Scenario; estimate→AI Estimate з origin/reviewed_by/permlevel; visit→Engineer Visit з sync-метаданими). Розширює Фазу 2. `warranty_letter` ≠ `Access Transfer Act` — Access Transfer Act створюється окремо в Vault-неймспейсі.»

**Статус після звірки:** Первинний аудит виявив ці розходження коректно. B1 підтверджує count (11+15) і формалізує 3 перетини. Конфлікт назв `warranty_letter` vs `Access Transfer Act` — підтверджено в B1 так само, як і в аудиті.

---

### D5. Вісь 4 (Gateway) — варіант обрано, proxy.py лишається legacy

Первинний аудит: «КОНФЛІКТ» з варіантами A/B/C.

**Що в DECISIONS.md B1:**
> «ВІСЬ 4 (gateway): /api/v1 (proxy.py) лишається задокументованим legacy (X-Deprecated). Увесь новий код — типізовані /api/v2/* з Pydantic-DTO як ACL-шар (антикорупційний адаптер у дусі дизайну, реалізований через HTTP, не in-process).»

**Статус після звірки:** Варіант A аудиту («залишити proxy.py legacy; v2 — типізовані DTO») обраний. Варіант C («прибрати proxy.py») — відхилено.

---

### D6. Вісь 5 (AI) — напрям вже обраний

Первинний аудит: «КОНФЛІКТ (суттєвий)» — прямий Anthropic без абстракції, анонімізації, Circuit Breaker.

**Що в DECISIONS.md B1:**
> «ВІСЬ 5 (AI): прямий anthropic-виклик обгортається провайдер-агностичним адаптером + Circuit Breaker (Redis) + анонімізацією fail-closed. Сирий текст ТЗ напряму в AI — заборонено.»

**Статус після звірки:** Напрям обрано — обгортка + Circuit Breaker + анонімізація. Відповідає варіанту B/C аудиту. Реалізації на диску поки немає — залишається технічним боргом.

---

### D7. Вісь 6 (Vault) — ключова деталь B1, якої немає в аудиті

Первинний аудит: Vault — «ВІДСУТНЄ повністю».

**Що в DECISIONS.md B1 (ключова деталь):**
> «ВІСЬ 6 (Vault — ІЗОЛЯЦІЯ, ключове рішення): Password Vault виноситься з AI-контуру. Реалізується як ОКРЕМИЙ МОДУЛЬ ERPNext/Frappe (in-process, поза FastAPI-AI-процесом) з власним шифруванням (AES-256-GCM пополе, ключ поза БД), власним hash-chain аудитом і контролем доступу (MFA). AI-сервіси та RQ/AI-воркери НЕ МАЮТЬ доступу до секретів, логінів, паролів і ключового контексту об'єктів — ні мережево, ні на рівні імпортів.»

**Що аудит пропустив:** Vault реалізується **всередині Frappe/ERPNext custom app** (in-process), а **не** у FastAPI-сервісі `security-api`. Це важлива архітектурна деталь — Vault живе в іншому процесі, ніж AI-клієнт (FastAPI), що забезпечує процесну межу навіть у рамках Варіанту A (C1).

**З DECISIONS.md Фаза 1.5:**
> «Конфлікт #1 (Vault-ізоляція) → ВАРІАНТ A прийнято: один custom app + CI-gate import-linter + роздільні воркери + ключ лише в людському web-контексті. ПОМІТКА: шов під Варіант B збережено.»

**Статус після звірки:** Аудит коректно зафіксував Vault як відсутній на диску. Але пропустив, що: (а) C1 вже вирішено (Варіант A); (б) Vault буде реалізований у Frappe-app, не в FastAPI.

---

### D8. Вісь 7 (Namespace) — рішення прийнято

Первинний аудит: «КОНФЛІКТ (namespace)» з варіантами A/B/C.

**Що в DECISIONS.md B1:**
> «ВІСЬ 7 (namespace): app лишається `security_erp` (прод уже на riad.fun, рейнеймінг — зайвий ризик); «RIAD» — бренд/UI-назва, не код-namespace.»

**Статус після звірки:** Варіант A аудиту обраний явно. Рішення прийнято.

---

### D9. Конфлікт #1 (C1) та Конфлікт #2 (H4) з 015 — обидва вирішені в DECISIONS.md

Первинний аудит не мав DECISIONS.md, тому не міг знати про ці резолюції.

**C1 (ізоляція Vault від AI «на рівні коду»):**
- 015 §5: відкритий конфлікт, потребує рішення людини (Варіант A vs B).
- DECISIONS.md «Фаза 1.5»: **Варіант A прийнято.** Один custom app + CI-gate import-linter + роздільні воркери + ключ лише в людському web-контексті. Шов під Варіант B збережено.
- DECISIONS.md B1: додатково уточнено, що Vault (in-process Frappe) і FastAPI-AI-процес — фізично різні процеси, що підсилює ізоляцію навіть у рамках Варіанту A.

**H4 (offline-first vs Vault-ізоляція):**
- 015 §5: конфлікт принципів, потребує підтвердження бізнесу.
- DECISIONS.md «Фаза 1.5»: **ПРИЙНЯТО online-only за замовчуванням**; нічого не кешується в локальний SQLite. Винятковий офлайн-кеш (шифрований+TTL+wipe) — майбутня опція.

---

### D10. Реєстр ризиків 06 — прив'язки до осей 1–7

06_risks_scaling_audit.md містить матрицю ризиків з прив'язкою до етапів E0–E9. Аудит їх не посилав. Релевантні для 7 осей:

| Ризик | Ось | Рейтинг (залишк.) | Етап-власник |
|---|---|---|---|
| R-H7 (розсинхрон прав JWT↔Frappe) | Вісь 2 | 2×4=8 (середній) | **E2** (DoD) + **E1** (field-level) |
| R-C1 (шлях Vault→AI) | Вісь 6 | 2×5=10 (високий) | **E6** (import-linter DoD) |
| R-C2 (key-escrow) | Вісь 6 | 2×5 (гейт) | Гейт перед прод **E6**, операціоналізація **E9** |
| R-H1 (витік PII в AI) | Вісь 5 | 2×4=8 (середній) | **E5** (fail-closed DoD) |
| R-H6 (Акт передачі доступів) | Вісь 6 | 1×5=5 (середній) | **E6** (DoD: не at-rest, TTL-доставка) |
| R-M3 (зв'язність ERPNext) | Вісь 4 | 2×3=6 (середній) | **E1** (CI-лінт червоний при порушенні) |

Два свідомо прийнятих залишкових ризики (06 §4.1): **C1** (enforced-convention, не фізичний бар'єр; шов під B збережено) і **M7** (транскордонне медіа; anon ≠ data-residency; у реєстрі під майбутню відповідність).

---

### D11. 05_dev_plan.md — застарів відносно DECISIONS.md B1

05_dev_plan.md писався до рішення B1 і використовує простір `riad.api.v1.*` та in-process ORM (E1, E2). Після B1 DECISIONS.md зазначає: «Розблоковує: переписаний build playbook під B1» — за цим є `docs/07_build_playbook.md` (не читався в жодному з аудитів). **05_dev_plan.md і 06_risks_scaling_audit.md описують архітектуру до B1** і не враховують FastAPI як затверджений gateway. Ризики і DoD E1/E2 потребують перегляду під B1.

---

### Підсумок звірки

**Розбіжності знайдено.** Первинний аудит коректно описав розходження між дизайном (Фази 1–3) і кодом на диску. Але через відсутність DECISIONS.md у read-списку аудит не знав, що власник вже прийняв рішення по всіх 7 осях через «Напрям B1».

Ключові уточнення до первинного аудиту:
1. Осі 1, 4, 5, 7 — «КОНФЛІКТ» стає «НАПРЯМ ОБРАНО (B1)».
2. Вісь 2 — «КОНФЛІКТ» стає «НАПРЯМ ОБРАНО (per-user, B2 відхилено); механізм відкритий (сесія R1)».
3. Вісь 6 (Vault) — B1 додає критичну деталь: Vault = in-process Frappe-модуль (поза FastAPI), що підсилює процесну ізоляцію.
4. C1 та H4 (015) — вирішені в «Фаза 1.5» DECISIONS.md ще до цього аудиту.
5. 05_dev_plan.md застарів відносно B1; актуальний план — `07_build_playbook.md`.

*Звірено проти DECISIONS.md/015/04/05/06 — 2026-06-21.*
