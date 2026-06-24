# План виправлень за аудитом A2-A4/S2-S4

**Дата:** 2026-06-23
**Метод:** systematic-debugging (4 phases)
**Джерело:** `docs/audit/block_{1-5}_report.md`
**Статус:** ПЛАН — нічого не впроваджено

---

## Зведена таблиця знахідок

| # | Блок | Знахідка | Серйозність | Файл |
|---|------|----------|-------------|------|
| 1 | 3 | `asyncio.run()` в WSGI/gevent контексті — deadlock | 🔴 CRITICAL | `ai/api.py:83` |
| 2 | 2+3 | `security_erp.*` імпорти недоступні в security-api контейнері | 🔴 CRITICAL | `routes/ai.py:40-43` |
| 3 | 3 | `_run_orchestrator_sync()` не реально sync — `complete_sync()` не існує | 🔴 CRITICAL | `tasks/ai_estimate.py:91` |
| 4 | 2 | 5 dead code файлів (сервіси + schema) | 🟡 HIGH | `services/`, `schemas/admin.py` |
| 5 | 2 | `doctypes.py` — моноліт 665 рядків, 23 маршрути, R4 порушення | 🟡 HIGH | `routes/doctypes.py` |
| 6 | 2 | Два шляхи створення Quotation | 🟡 HIGH | `routes/doctypes.py:302` |
| 7 | 3 | `drive_file_id` працює лише для публічних GDrive <100MB | 🟡 MEDIUM | `tasks/transcribe.py:53-76` |
| 8 | 3 | `_set_status("error")` — неіснуючий Select option | 🟡 MEDIUM | `tasks/transcribe.py:66,85` |
| 9 | 1 | `passport_client_release.py` втратив `before_insert` | 🟡 MEDIUM | `doctype/passport_client_release/` |
| 10 | 5 | 67 тестів не запускаються на хості (missing deps), CI не тестує бізнес-логіку | 🟡 MEDIUM | 6 тестових файлів |
| 11 | 2 | `banking.py` — невикористаний `import uuid` | ⚪ LOW | `routes/banking.py:2` |
| 12 | 2 | `portal.py` — невикористаний `from datetime import datetime, timezone` | ⚪ LOW | `routes/portal.py:2` |
| 13 | 3 | Circuit Breakер не задіяний в RQ-шляху | ⚪ LOW | `tasks/ai_estimate.py` |
| 14 | 2 | `estimate_service.py:57` — circular import (service → routes) | 🟡 HIGH | `services/estimate_service.py:57` |

---

## Фаза 1: Root Cause Investigation

### Знахідка 1+2+3: AI-оркестратор не працює

**Що відбувається:**
- `POST /api/v2/ai/execute` падає з `ModuleNotFoundError: security_erp` в security-api контейнері
- Якщо б імпорти працювали — `asyncio.run()` в gevent-контексті викликає deadlock або непередбачувану поведінку
- `_run_orchestrator_sync()` намагається викликати неіснуючий `provider.complete_sync()`, завжди падає в fallback

**Root cause (один на всі три):**
Оркестратор (`orchestrator.py`) написаний повністю async, прив'язаний до `security_erp` пакету (Frappe-процес). Security-api контейнер не має доступу до цього пакету. Немає sync-варіанту оркестратора.

**Evidence:**
- `services/security-api/Dockerfile` — `COPY . .` копіює лише `services/security-api/`
- `ai/api.py:83` — `asyncio.run(orch.execute(...))`
- `ai/adapters/base.py:31` — `async def complete()`, жодного `complete_sync()`
- `.github/workflows/ci.yml` — `PYTHONPATH: services/security-api:erpnext/security_erp` (CI маскує проблему)

---

### Знахідка 4: Dead code сервіси

**Що:** 5 файлів ніким не імпортується: `ai_service.py`, `admin_service.py`, `media_service.py`, `scenario_service.py`, `schemas/admin.py`

**Root cause:** Сервіси створені, але роутери не оновлені для їх використання. Роутери викликають `frappe_*` напряму.

**Evidence:**
- `grep -r "from app.services.scenario_service" services/security-api/` → 0 результатів
- `routes/scenarios.py` використовує `frappe_get/post/put` напряму з `app.core.database`

---

### Знахідка 5+6: doctypes.py моноліт

**Що:** 23 маршрути, 665 рядків, R4 порушення (прямі frappe_* виклики), два шляхи створення Quotation.

**Root cause:** `doctypes.py` був першим роутером, створеним до введення R4 (gateway-дисципліна). Маршрути не були розбиті на service+route модулі.

**Evidence:**
- `routes/doctypes.py` — 20+ викликів `frappe_get/post/put` напряму
- `POST /api/v2/quotation` (doctypes.py) vs `POST /api/v2/estimates/{name}/confirm` (estimates.py) — два шляхи до Quotation

---

### Знахідка 7+8: transcribe.py обмеження

**Що:**
- `drive_file_id` обробка працює лише для публічних Google Drive файлів <100MB
- `_set_status("error")` — неіснуючий Select option (`none|pending|done|manual`)

**Root cause:**
- Google Drive `uc?export=download` endpoint не підтримує приватні файли або файли >100MB
- Код написаний до визначення фінального набору Select options для `transcription_status`

---

### Знахідка 9: passport_client_release.py

**Що:** cpython-311 .pyc мав `before_insert` метод. Поточний .py має лише `pass`.

**Root cause:** Метод був видалений свідомо або випадково при міграції з Python 3.11 на 3.12.

---

### Знахідка 10: Тести не запускаються

**Що:** 67 тестів падають з `ModuleNotFoundError` на хості.

**Root cause:** Тести написані для Docker-контейнера де всі pip-залежності встановлені. На хості `fastapi`, `pydantic`, `httpx`, `redis`, `python-jose` не встановлені. CI не встановлює їх теж — тому CI фактично робить лише syntax check.

---

### Знахідка 14: Circular import

**Що:** `estimate_service.py:57` імпортує з `routes/ai.py`.

**Root cause:** `_build_orchestrator()` знаходиться в routes-шарі, але потрібен в service-шарі. Service імпортує з routes — порушення R4.

---

## Фаза 2: Pattern Analysis

### Працюючий приклад: Vault (V3)

**Патерн:** Тонкий проксі — security-api викликає Frappe через REST API, не через прямий import.

**Як працює:**
1. `routes/vault.py` приймає HTTP-запит
2. Викликає `frappe_post("/api/method/security_erp.vault.api.mfa_verify", ...)` через `app.core.database`
3. Frappe-процес виконує логіку (sync, в своєму контексті)
4. Повертає результат

**Чому працює:** Vault не потребує async-оркестрації. Весь sync-код живе всередині Frappe-процесу.

---

### Працюючий приклад: Estimates (R4-compliant)

**Патерн:** Service-шар між route та Frappe.

**Як працює:**
1. `routes/estimates.py` імпортує з `services/estimate_service.py`
2. `estimate_service.py` викликає `frappe_get/post` через `app.core.database`
3. Жодного прямого Frappe-звернення в routes

**Чому працює:** Чітке розділення route ↔ service ↔ database.

---

### Працюючий приклад: Whisper

**Патерн:** Окремий мікросервіс.

**Як працює:**
1. RQ-задача `transcribe_media` викликає `http://whisper:8000/transcribe`
2. Whisper — окремий FastAPI-контейнер
3. Жодного прямого import між Frappe та Whisper

**Чому працює:** Ізоляція через HTTP. Кожен сервіс має свій Python-контекст.

---

### Непрацюючий приклад: AI-оркестратор

**Патерн:** Прямий import між контейнерами.

**Чому не працює:**
1. `routes/ai.py` імпортує `security_erp.ai.*` — пакет недоступний в security-api контейнері
2. Оркестратор async — Frappe-контекст sync (gevent)
3. Circuit Breakер потребує async Redis — RQ-контекст не має event loop

---

## Фаза 3: Hypothesis and Testing

### H1: AI-оркестрація має працювати всередині Frappe-процесу

**Гіпотеза:** Перенести виклик оркестратора в Frappe `@whitelist` метод (як Vault), зробити security-api тонким проксі.

**Тест:** `POST /api/v2/ai/execute` → security-api викликає `frappe_post("/api/method/security_erp.ai.api.execute_ai", ...)` → Frappe-процес виконує оркестрацію.

**Перевірка:** Endpoint повертає 200, не ImportError/RuntimeError.

**Ризик:** `asyncio.run()` в gevent-контексті все ще проблема. Потрібен sync-варіант оркестратора.

---

### H2: Sync-варіант оркестратора через httpx

**Гіпотеза:** Замінити async-адаптери на sync httpx-виклики в RQ-контексті.

**Тест:** `provider.complete_sync(task, payload, None)` — реалізувати в `GeminiAdapter` та `StubAdapter` через `httpx.post()` (sync).

**Перевірка:** `_run_orchestrator_sync()` повертає результат без `asyncio.run()`.

**Ризик:** Дублювання логіки (async + sync версії адаптерів).

---

### H3: Dead code — видалити або інтегрувати

**Гіпотеза:** 5 dead code файлів можна видалити без наслідків.

**Тест:** `grep -r "from app.services.scenario_service" services/` → 0 результатів. Аналогічно для інших 4 файлів.

**Перевірка:** Тести проходять, нічого не зламано.

**Ризик:** `ai_service.py` може використовуватись поза routes/ — потрібна перевірка.

---

### H4: `_set_status("error")` → `_set_status("manual")`

**Гіпотеза:** Заміна "error" на "manual" (існуючий Select option) вирішує проблему.

**Тест:** `_set_status(doc, "manual")` — перевірити що `transcription_status` в БД входить до Select options.

**Перевірка:** `SELECT transcription_status FROM tabMedia Asset WHERE transcription_status='error'` → 0 рядків після міграції.

**Ризик:** Міграція існуючих записів з `status='error'` → `status='manual'`.

---

### H5: doctypes.py — розбити на service+route модулі

**Гіпотеза:** Виділити маршрути з doctypes.py в окремі файли (quotation_service.py, warranty_service.py тощо).

**Тест:** Кожен новий service+route модуль працює незалежно. Тести проходять.

**Перевірка:** `doctypes.py` зменшується до catch-all або видаляється.

**Ризик:** Великий обсяг роботи (23 маршрути). Потрібна поетапна міграція.

---

## Фаза 4: Implementation Plan

### Крок 1: Failing Test Cases

| Знахідка | Тест що мав би існувати |
|----------|-------------------------|
| 1+2+3 | `POST /api/v2/ai/execute` в Docker-контейнері security-api → очікується 200 (не ImportError/RuntimeError) |
| 4 | `grep -r "from app.services.{name}" services/security-api/` → 0 результатів для кожного dead code файлу |
| 5+6 | `POST /api/v2/quotation` → створює Quotation через service-шар (не напряму) |
| 8 | `_set_status(doc, "manual")` → `transcription_status` в БД входить до Select options Media Asset |
| 10 | `python -m pytest tests/` на хості → всі тести PASS (не skip через missing deps) |
| 14 | `estimate_service.py` не імпортує з `routes/` |

---

### Крок 2: Implement Single Fix (порядок виконання)

#### Крок 2.1: Видалити dead code (знахідка 4)

**Файли для видалення:**
- `services/security-api/app/services/ai_service.py`
- `services/security-api/app/services/admin_service.py`
- `services/security-api/app/services/media_service.py`
- `services/security-api/app/services/scenario_service.py`
- `services/security-api/app/schemas/admin.py`

**Перед видаленням:** `grep -r "from app.services.{name}" services/security-api/` — підтвердити 0 імпортів.

---

#### Крок 2.2: Виправити `_set_status("error")` (знахідка 8)

**Файл:** `erpnext/security_erp/security_erp/tasks/transcribe.py`

**Зміна:**
- Рядок 66: `_set_status(doc, "error")` → `_set_status(doc, "manual")`
- Рядок 85: `_set_status(doc, "error")` → `_set_status(doc, "manual")`

**Додатково:** Міграція існуючих записів:
```sql
UPDATE tabMedia Asset SET transcription_status = 'manual' WHERE transcription_status = 'error';
```

---

#### Крок 2.3: Перенести AI-оркестрацію в Frappe-процес (знахідки 1+2+3)

**Варіант A (рекомендований): Тонкий проксі**

1. `routes/ai.py` — видалити lazy import `security_erp.ai.*`
2. `routes/ai.py` — `_build_orchestrator()` замінити на `frappe_post("/api/method/security_erp.ai.api.execute_ai", ...)`
3. `ai/api.py` — `execute_ai()` вже є `@frappe.whitelist()` методом. Працює в Frappe-контексті.
4. Проблема `asyncio.run()` в gevent залишається — потрібен крок 2.4.

**Варіант B (альтернативний): Окремий AI-сервіс (як Whisper)**

1. Створити `services/ai-service/` окремий FastAPI-контейнер
2. Перенести `orchestrator.py`, `adapters/`, `circuit_breaker.py` туди
3. Security-api викликає AI-service через HTTP
4. AI-service працює на uvicorn (async без gevent)

---

#### Крок 2.4: Sync-варіант оркестратора (знахідка 3)

**Файл:** `erpnext/security_erp/security_erp/ai/adapters/base.py`, `gemini.py`, `stub.py`

**Зміна:** Додати `complete_sync()` метод в кожен адаптер:
```python
def complete_sync(self, task: str, payload: dict, params: dict | None) -> AIResult:
    """Sync version for RQ workers (no event loop)."""
    import httpx
    # ... sync httpx.post() замість async client
```

**Файл:** `erpnext/security_erp/security_erp/tasks/ai_estimate.py`

**Зміна:** `_run_orchestrator_sync()` — видалити `asyncio.run()` fallback, використовувати лише `provider.complete_sync()`.

---

#### Крок 2.5: Виправити circular import (знахідка 14)

**Файл:** `services/security-api/app/services/estimate_service.py`

**Зміна:** Видалити `from app.routes.ai import _build_orchestrator` (рядок 57). Замінити на прямий виклик через `frappe_post` або перенести `_build_orchestrator()` в service-шар.

---

#### Крок 2.6: Відновити passport_client_release.py before_insert (знахідка 9)

**Файл:** `erpnext/security_erp/security_erp/security_erp/doctype/passport_client_release/passport_client_release.py`

**Зміна:** Декомпілювати cpython-311 .pyc, відновити `before_insert` метод. Перевірити чи він ще актуальний.

---

#### Крок 2.7: Видалити unused imports (знахідки 11+12)

**Файли:**
- `routes/banking.py:2` — видалити `import uuid`
- `routes/portal.py:2` — видалити `from datetime import datetime, timezone`

---

#### Крок 2.8: Виправити CI тестовий pipeline (знахідка 10)

**Файл:** `.github/workflows/ci.yml`

**Зміна:** Додати крок:
```yaml
- name: Install test dependencies
  run: pip install fastapi pydantic httpx python-jose[cryptography] redis pydantic_settings
```

Або: запускати тести всередині Docker-контейнера security-api.

---

#### Крок 2.9: doctypes.py рефакторинг (знахідки 5+6) — ВІДКЛАДАЄТЬСЯ

**Причина відкладання:** Великий обсяг (23 маршрути). Потребує окремої сесії. Не блокує інші виправлення.

**Майбутній план:**
1. Виділити `quotation_service.py` + `routes/quotation.py`
2. Виділити `warranty_service.py` + `routes/warranty.py`
3. Виділити `pricing_service.py` + `routes/pricing.py`
4. Залишити в doctypes.py лише generic CRUD для DocType'ів без кастомної логіки

---

### Крок 3: Verify Fix

| Знахідка | Верифікація |
|----------|-------------|
| 1+2+3 | `POST /api/v2/ai/execute` в Docker повертає 200 (не ImportError/RuntimeError) |
| 4 | `grep -r "from app.services.scenario_service" services/` → 0 результатів |
| 5+6 | Відкладено |
| 8 | `SELECT transcription_status FROM tabMedia Asset WHERE transcription_status='error'` → 0 рядків |
| 9 | `passport_client_release.py` має `before_insert` метод |
| 10 | `python -m pytest tests/` на хості → всі PASS |
| 11+12 | `flake8 --select=F401 routes/banking.py routes/portal.py` → 0 помилок |
| 14 | `grep "from app.routes" services/estimate_service.py` → 0 результатів |

---

### Крок 4: If Fix Doesn't Work → Return to Phase 1

**Для знахідок 1+2+3:** Якщо перенесення оркестратора в Frappe-процес не працює (asyncio+gevent конфлікт) → **H5: Окремий AI-сервіс (як Whisper)**. Це архітектурне рішення — обговорити з користувачем.

**Для знахідки 8:** Якщо міграція `error` → `manual` ламає UI-фільтри → додати "error" до Select options замість міграції.

---

### Крок 5: If 3+ Fixes Failed → Question Architecture

**Патерн що вказує на архітектурну проблему:**
- Знахідки 1+2+3 — це ОДНА архітектурна проблема: AI-оркестратор не належить ні security-api, ні Frappe-процесу.
- Якщо sync-варіант адаптерів + тонкий проксі не працює → оркестратор має бути окремим мікросервісом.

**Архітектурне питання:** Чи потрібен AI-оркестратор як окремий контейнер (як Whisper), чи достатньо sync-обгортки в Frappe?

---

## Пріоритет виконання

| Крок | Знахідки | Час | Залежності |
|------|----------|-----|------------|
| 2.1 | 4 (dead code) | 15 хв | — |
| 2.2 | 8 (error→manual) | 10 хв | — |
| 2.7 | 11+12 (unused imports) | 5 хв | — |
| 2.5 | 14 (circular import) | 20 хв | — |
| 2.3 | 1+2+3 (AI proxy) | 1 год | — |
| 2.4 | 3 (sync adapter) | 2 год | 2.3 |
| 2.6 | 9 (passport) | 30 хв | — |
| 2.8 | 10 (CI tests) | 30 хв | — |
| 2.9 | 5+6 (doctypes) | 4+ год | окрема сесія |

**Загальний час (без 2.9):** ~5 годин
