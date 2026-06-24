# Аудит Блоку 2 — Імпорти, маршрути, dead code

**Дата:** 2026-06-23
**Обсяг:** `services/security-api/app/` (routes/, services/, schemas/, main.py)
**Метод:** ручний аудит кожного файлу, перевірка існування модулів та символів

---

## 1. Нерезолвні імпорти

**Результат: НЕ ЗНАЙДЕНО.** Усі `from X import Y` у routes/, services/, schemas/ резолвяться коректно — файли-джерела існують, імпортовані символи (класи, функції, константи) присутні у відповідних модулях.

Перевірені файли (22 routes + 8 services + 13 schemas + main.py + auth/ + core/ = 50+ файлів).

---

## 2. Shadowed маршрути (prefix overlap)

**Результат: НЕ ЗНАЙДЕНО критичних shadow.**

Префіксна структура роутерів у `main.py`:

| Роутер | Префікс | Тип |
|--------|---------|-----|
| auth | `/api/v2/auth` | specific |
| banking | `/api/v1/banking` | specific |
| signatures | `/api/v1/signatures` | specific |
| portal | `/api/v1/portal` | specific |
| public | `/api/v1/public` | specific |
| mobile | `/api/v1/mobile` | specific |
| estimates | `/api/v2/estimates` | specific |
| media | `/api/v2/media` | specific |
| scenarios | `/api/v2/scenarios` | specific |
| ai_admin | `/api/v2/ai-admin` | specific |
| doctypes | `/api/v2` | **wide** |
| visits | _(no prefix, explicit paths)_ | specific |
| vault | `/api/v2/vault` | specific |
| act_router | `/api/v2/vault/act` | specific |
| act_public | `/api/v2/act/public` | specific |
| ai | `/api/v2/ai` | specific |
| sync | `/api/v2/sync` | specific |
| serial | `/api/v2/serial` | specific |
| maps | `/api/v2/maps` | specific |
| warehouse | `/api/v2/warehouse` | specific |
| proxy | `/api/v1/{path:path}` | **catch-all** |

**Примітки:**

- `doctypes` (`/api/v2`) — широкий префікс. FastAPI резолвить за конкретністю, тому `/api/v2/estimates` → `estimates_router`, а не `doctypes_router`. Не є shadow, але **порушує gateway-дисципліну R4** — doctypes.py містить роути, що мали б бути у власних service-шарах.

- `visits.py` реєструє маршрути `/api/v1/visits/...` і `/api/v2/visits/...` одночасно. Оскільки `visits_router` реєструється **до** `proxy_router`, явні маршрути мають пріоритет над catch-all `/api/v1/{path:path}`. Це коректно, але **v1-маршрути у visits.py конфліктують із catch-all proxy.py** — якщо proxy реєструється першим, він перехопить ці шляхи.

---

## 3. Dead code файли (ніким не імпортуються)

| Файл | Статус |
|------|--------|
| `app/services/ai_service.py` | 🔴 **DEAD CODE** — жоден файл не імпортує `AIService` чи `ai_service` |
| `app/services/admin_service.py` | 🔴 **DEAD CODE** — жоден файл не імпортує `list_providers`, `upsert_provider`, `list_request_logs`, `get_degradation_status` |
| `app/services/media_service.py` | 🔴 **DEAD CODE** — жоден файл не імпортує `enqueue_transcription`, `set_manual_transcription` |
| `app/services/scenario_service.py` | 🔴 **DEAD CODE** — жоден файл не імпортує `ScenarioService` чи `scenario_service` |
| `app/schemas/admin.py` | 🔴 **DEAD CODE** — жоден файл не імпортує `AIProviderUpsertRequest`, `DegradationResponse` з цього модуля |

**Всього:** 5 dead code файлів.

**Примітка:** `routes/ai_admin.py` дублює логіку `admin_service.py` напряму (викликає `frappe_get/post/put` inline). `routes/media.py` дублює логіку `media_service.py` (transcribe + manual transcription inline). `routes/scenarios.py` використовує `frappe_*` напряму замість `scenario_service.py`. `routes/ai.py` використовує `ai_orchestrator_service.py` замість `ai_service.py`.

---

## 4. Невикористані імпорти

| Файл:рядок | Що не використовується |
|-------------|----------------------|
| `routes/ai.py:13` | `import redis.asyncio as aioredis` — `aioredis` використовується як type hint у `_build_orchestrator` та Depends, **OK** |
| `routes/banking.py:1` | `Query` — ніде не використовується |
| `routes/banking.py:2` | `import uuid` — ніде не використовується |
| `routes/mobile.py:2` | `from datetime import datetime, timezone` — `datetime` використовується у `mobile_sync` та `mobile_gps_location`, **OK** |
| `routes/mobile.py:3` | `import uuid` — використовується у `mobile_upload_chunk`, **OK** |
| `routes/portal.py:2` | `from datetime import datetime, timezone` — ніде не використовується |
| `routes/portal.py:3` | `import uuid` — використовується у `portal_create_ticket`, **OK** |
| `routes/signatures.py:2` | `import uuid` — використовується у `create_signature_request`, **OK** |
| `routes/public_api.py:1` | `Header` — використовується у `verify_api_key`, **OK** |
| `routes/doctypes.py:2` | `from typing import Optional` — використовується у BaseModel полях, **OK** |
| `routes/doctypes.py:3` | `Query` — ніде не використовується |
| `services/ai_service.py:1` | `import json` — використовується у `generate_estimate`, **OK** |

**Підтверджені невикористані імпорти:**

| Файл:рядок | Що не використовується |
|-------------|----------------------|
| `routes/banking.py:2` | `import uuid` — ніде не використовується |
| `routes/portal.py:2` | `from datetime import datetime, timezone` — ніде не використовується |

**Скориговані (використовуються):**
- `routes/banking.py:1` `Query` — ✅ використовується у `list_transactions(limit: int = Query(50, le=200))`
- `routes/doctypes.py:3` `Query` — ✅ використовується у `list_quotations(status: str = Query(None))`

---

## 5. Конфліктуючі маршрути: doctypes.py ↔ estimates/scenarios

### 5.1 doctypes.py ↔ estimates.py

| doctypes.py маршрут | estimates.py маршрут | Конфлікт? |
|---------------------|---------------------|-----------|
| `POST /api/v2/quotation` | `POST /api/v2/estimates/{name}/confirm` | ❌ Немає (різні шляхи) |
| `GET /api/v2/quotations/{name}` | — | ❌ Немає |

**Конфлікту маршрутів немає.** Але є **архітектурний конфлікт**: `doctypes.py` містить `POST /api/v2/quotation` (створення Quotation напряму), тоді як `estimates.py` → `confirm_estimate()` створює Quotation через anti-corruption gateway. Два шляхи створення Quotation — порушення R4 (gateway-дисципліна).

### 5.2 doctypes.py ↔ scenarios.py

| doctypes.py маршрут | scenarios.py маршрут | Конфлікт? |
|---------------------|---------------------|-----------|
| `POST /api/v2/scenarios/{scenario_id}/apply` | `POST /api/v2/scenarios/{name}/items` | ❌ Немає (різні патерни) |
| `POST /api/v2/scenarios/{scenario_name}/calculate` | `GET /api/v2/scenarios/{name}` | ❌ Немає |

**Конфлікту маршрутів немає.** Але є **дублювання логіки**: `doctypes.py:apply_scenario` та `scenarios.py:upsert_scenario_item` обидва прають із Security Scenario Item — різними способами, без спільного service-шару.

### 5.3 doctypes.py — загальне зауваження

`doctypes.py` (prefix `/api/v2`) містить **23 маршрути**, більшість із яких:
- Викликають `frappe_get/post/put` напряму (порушення R4 — мають іти через service-шар)
- Працюють зі стандартними ERPNext DocType (Quotation, Purchase Order, Sales Invoice, Sales Order) напряму, без anti-corruption gateway
- Мають inline Pydantic-моделі замість окремих schemas

---

## 6. Специфічні перевірки

### `routes/ai.py` → `services/ai_orchestrator_service.py`

✅ **Так, імпортує:**
```python
from app.services.ai_orchestrator_service import (
    _anonymize_payload, sync_provider_health, write_ai_request_log,
)
```
Але: `_build_orchestrator` імпортує з `security_erp.ai.*` (Frappe-процес) — працює лише якщо security-api та Frappe ділять один Python environment.

### `routes/estimates.py` → `services/estimate_service.py`

✅ **Так, імпортує:**
```python
from app.services.estimate_service import build_estimate, review_estimate, confirm_estimate
```

### `routes/scenarios.py` → `services/scenario_service.py`

❌ **НІ, не імпортує.** `scenarios.py` використовує `frappe_get/post/put` напряму з `app.core.database`. `scenario_service.py` — dead code.

### `routes/media.py` → `services/drive_service.py`

✅ **Так, імпортує (локально):**
```python
from app.services.drive_service import upload_to_drive  # line 45, inside media_upload()
```
Але: `media.py` НЕ імпортує `media_service.py` (transcribe + manual transcription робить inline). `media_service.py` — dead code.

### `routes/doctypes.py` — конфлікти з estimates/scenarios

✅ Див. §5 вище. Конфліктів **маршрутів** немає. Конфлікт **архітектурний** (два шляхи до Quotation, пряме звернення до Frappe без service-шару).

---

## 7. Порядок include_router() у main.py

Порядок реєстрації (рядки 100–120 `main.py`):

```
auth → banking → signatures → portal → public → mobile →
estimates → media → scenarios → ai_admin → doctypes → visits →
vault → act_router → act_public → ai → sync → serial →
maps → warehouse → proxy
```

**proxy_router** (catch-all `/api/v1/{path:path}`) — **останній**. Це коректно: всі явні маршрути реєструються раніше, тому вони мають пріоритет.

**doctypes_router** (`/api/v2`) — реєструється **після** estimates/media/scenarios/ai_admin. Це означає, що специфічні `/api/v2/estimates/*` тощо будуть знайдені раніше, ніж широкі маршрути doctypes. **Коректно.**

---

## Резюме

| Категорія | Кількість | Деталі |
|-----------|-----------|--------|
| Нерезолвні імпорти | **0** | — |
| Shadowed маршрути | **0** | є архітектурні зауваження по doctypes |
| Dead code файли | **5** | ai_service.py, admin_service.py, media_service.py, scenario_service.py, schemas/admin.py |
| Невикористані імпорти | **2** | banking.py (uuid), portal.py (datetime, timezone) |
| Конфліктуючі маршрути | **0** | але є архітектурний конфлікт: два шляхи створення Quotation |

### Критичні знахідки

1. **4 dead service файли** — `ai_service.py`, `admin_service.py`, `media_service.py`, `scenario_service.py` створені, але жоден роутер їх не використовує. Роути дублюють логіку inline, порушуючи R4 (gateway-дисципліна: service-шар обов'язковий між route та database).

2. **`doctypes.py` — моноліт** (665 рядків, 23 маршрути) — працює напряму з `frappe_get/post/put`, без service-шару. Містить маршрути, що мали б бути у власних модулях (Quotation, Purchase Order, Sales Invoice, Warranty, Scenario apply/calculate).

3. **Два шляхи створення Quotation**: `POST /api/v2/quotation` (doctypes.py, напряму) та `POST /api/v2/estimates/{name}/confirm` (через gateway). Порушення єдиної точки входу.
