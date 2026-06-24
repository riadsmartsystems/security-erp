# E5 — AISL + Анонімізація + Whisper + AI Builder → ERPNext

**Дата:** 2026-06-25
**Складність:** 5
**Статус:** План готовий до виконання

## Що вже є (A1-A2 частково)

| Компонент | Файл | Статус |
|-----------|------|--------|
| Circuit Breaker (sync+async) | `security_erp/ai/circuit_breaker.py` | ✓ |
| AI Orchestrator (failover) | `security_erp/ai/orchestrator.py` | ✓ |
| AI Adapters (Gemini, Stub) | `security_erp/ai/adapters/` | ✓ |
| AI Provider DocType | `security_erp/doctype/ai_provider/` | ✓ |
| AI Request Log DocType | `security_erp/doctype/ai_request_log/` | ✓ |
| Anon base | `ai_orchestrator_service.py:_anonymize_payload()` | ✓ (базовий) |
| Provider health sync | `ai_orchestrator_service.py:sync_provider_health()` | ✓ |
| AI Admin service | `ai_admin_service.py` | ✓ |
| AI routes | `app/routes/ai.py` | ✓ |
| RQ tasks | `tasks/ai_estimate.py` | ✓ |
| Tests A1-A2 | `tests/ai/test_a1_*.py`, `test_a2_*.py` | ✓ |

## Що потрібно зробити

---

### Сесія A1: Анонімізація fail-closed + людський gate

**Мета:** Захистити PII перед зовнішнім AI. Fail-closed = помилка анонімізації → зовнішній виклик НЕ робиться.

**Завдання:**

1. **Розширити `_anonymize_payload()`** в `ai_orchestrator_service.py`:
   - Додати regex-анонімізацію телефонів (`\+380\d{9}`, `0\d{9}`)
   - Додати regex для email (`[\w.-]+@[\w.-]+\.\w+`)
   - Додати regex для ІПН/ЄДРПОУ (`\d{10}`, `\d{8}`)
   - Повертати `{ok: True/False, payload: {...}, blocked_fields: [...]}`

2. **Додати human gate endpoint** в `ai.py`:
   - `POST /api/v2/ai/preview` — показує анонімізований payload + що буде відправлено
   - `POST /api/v2/ai/approve` — підтверджує відправку (зберігає approval в Redis з TTL 5хв)

3. **Додати fail-closed логіку** в `execute_ai()`:
   - Якщо `_anonymize_payload()` повертає `ok=False` → НЕ відправляти в AI
   - Повертати 409 з `blocked_fields` для UI

4. **Тести:**
   - Тест анонімізації телефонів/email/ІПН
   - Тест fail-closed: невалідний payload → 409
   - Тест human gate: preview → approve → execute

**DoD:**
- ✅ Телефони, email, ІПН/ЄДРПОУ анонімізуються
- ✅ Fail-closed: помилка анонімізації → 409, AI не викликається
- ✅ Human gate: preview → approve → execute
- ✅ Тести проходять

---

### Сесія A2: Whisper self-hosted + RQ-задачі транскрипції

**Мета:** Self-hosted Whisper для транскрипції аудіо. RQ-задачі для async обробки.

**Завдання:**

1. **Docker Compose: Whisper контейнер** (використовується з E0):
   - `whisper` service: `onerahmet/openai-whisper-asr-webservice:latest` (CPU)
   - Endpoint: `POST http://whisper:9000/asr?task=transcribe&language=uk`
   - Порт 9000 тільки всередині мережі

2. **RQ-задача `transcribe_media`** в `tasks/ai_transcribe.py`:
   - Приймає `media_asset_uuid`
   - Завантажує аудіо з Google Drive (через `drive_file_id`)
   - Відправляє в Whisper API
   - Оновлює `MediaAsset.transcription` та `transcription_status`
   - Записує в `AI Request Log`

3. **API endpoint** `POST /api/v2/ai/transcribe`:
   - Приймає `media_asset_uuid`
   - Перевіряє `ai_allowed` на MediaAsset (H2: `ai_allowed=0` → блок)
   - Enqueue RQ-задачу
   - Повертає `{status: "pending", task_id: "..."}`

4. **Flutter: voice_note_screen.dart** — відправка транскрипції:
   - Після upload → `POST /api/v2/ai/transcribe`
   - Оновлює `transcriptionStatus` в локальній БД

5. **Тести:**
   - Тест Whisper API (mock HTTP)
   - Тест `ai_allowed` блокування
   - Тест RQ enqueue

**DoD:**
- ✅ Whisper контейнер в docker-compose
- ✅ `transcribe_media` RQ-задача працює
- ✅ `ai_allowed=0` блокує транскрипцію
- ✅ Flutter voice_note → transcribe → transcription status
- ✅ Тести проходять

---

### Сесія A3: estimate.confirm → gateway межа

**Мета:** Жорстка межа: AI-кошторис НЕ входить у ERPNext без інженера (`reviewed_by`).

**Завдання:**

1. **DocType `AI Estimate`** (якщо не існує — створити):
   - Поля: `site_brief`, `object_type`, `area_sqm`, `cameras_count`, `variant`, `ai_result`, `ai_provider_used`, `origin`, `status` (Draft→AI Draft→On Review→Approved→Rejected)
   - `reviewed_by` (Link → User) — ОБОВ'ЯЗКОВО для confirm

2. **Метод `estimate.confirm`** в `estimate_service.py`:
   - Перевіряє `status == "On Review"` AND `reviewed_by IS NOT NULL`
   - Якщо `reviewed_by` порожній → 409 "Requires engineer review"
   - Викликає `gateway.create_quotation` тільки після перевірки

3. **Метод `estimate.build`** в `estimate_service.py`:
   - Приймає `site_brief` + `variant`
   - Enqueue RQ-задачу `ai_estimate_build`
   - Повертає `{status: "pending", estimate_id: "..."}`

4. **Метод `estimate.review.submit`**:
   - Приймає `estimate_id` + `action` (approve/reject) + `comment`
   - Оновлює `status` + `reviewed_by`

5. **Тести:**
   - Тест confirm без reviewed_by → 409
   - Тест confirm з reviewed_by → success
   - Тест build → pending → AI result → review → confirm

**DoD:**
- ✅ `confirm` без `reviewed_by` → 409
- ✅ `confirm` з `reviewed_by` → створює Quotation
- ✅ `build` enqueue RQ → AI result
- ✅ `review.submit` оновлює status + reviewed_by
- ✅ Тести проходять

---

### Сесія A4: no-code адмінки + AI-деградація UI

**Мета:** No-code управління AI провайдерами, сценаріями, чек-листами. AI-деградація = чип+банер.

**Завдання:**

1. **Admin endpoints** (розширити `ai_admin_service.py`):
   - `GET /api/v2/ai/admin/providers` → список провайдерів
   - `PUT /api/v2/ai/admin/providers/{name}` → оновити провайдер
   - `GET /api/v2/ai/admin/request-logs` → пагінований лог
   - `GET /api/v2/ai/admin/scenarios` → список сценаріїв
   - `POST /api/v2/ai/admin/scenarios` → створити/оновити сценарій

2. **Security Scenario CRUD**:
   - `scenario.list` → список сценаріїв
   - `scenario.get` → деталі сценарію з items
   - `scenario.create/update` → створити/оновити (no-code)

3. **Checklist Template CRUD**:
   - `checklist_template.list/get/create/update`

4. **Flutter: AI degradation badge**:
   - Чип "AI: primary/fallback/manual" в AppBar
   - Банер при degradation="manual" з текстом "Ручний режим"

5. **Тести:**
   - Тест admin provider CRUD
   - Тест scenario CRUD
   - Тест degradation endpoint

**DoD:**
- ✅ Admin provider CRUD працює
- ✅ Scenario CRUD працює
- ✅ Checklist Template CRUD працює
- ✅ AI degradation badge в Flutter
- ✅ Тести проходять

---

## Порядок виконання

```
A1 (анонімізація) → A2 (Whisper) → A3 (confirm→gateway) → A4 (admin+UI)
```

Кожна сесія незалежна після A1 (A2/A3/A4 можна паралелізувати за наявності ресурсів).

## Загальні DoD E5

- ✅ Анонімізація fail-closed (помилка → AI не викликається)
- ✅ Жоден AI-кошторис не входить у ERPNext без `reviewed_by`
- ✅ AI Request Log містить лише анонімізований payload
- ✅ Circuit Breaker спільний між воркерами (Redis)
- ✅ Whisper concurrency=1 у лімітах
- ✅ Сире фото не йде в зовнішній AI (`ai_allowed=0`)
- ✅ AI-деградація показана як бізнес-стан, не червона помилка
- ✅ Тести проходять
- ✅ `flutter analyze` — 0 issues
