# Аудит Блоку 3: AI/Whisper сервіси

**Дата:** 2026-06-23
**Метод:** systematic-debugging (Phase 1: Root Cause Investigation)
**Статус:** АУДИТ — нічого не виправлено

---

## 1. orchestrator.py — імпорти

**Файл:** `erpnext/security_erp/security_erp/ai/orchestrator.py`

| Імпорт | Резолвиться? | Примітка |
|--------|-------------|----------|
| `security_erp.ai.adapters.base` (AIResult, AbstractAIAdapter, timed_call) | ✅ | Файл існує, всі класи експортовані |
| `security_erp.ai.circuit_breaker` (CBState, CircuitBreaker) | ✅ | Файл існує, Lua-скрипт коректний |
| `asyncio` (stdlib) | ✅ | — |

**Вердикт:** Всі імпорти резолвляться. Модуль чистий. `orchestrator.py` працює **лише** в контексті Frappe-процесу (де `security_erp` встановлений як app через `.pth` файл у `Dockerfile.backend`).

---

## 2. api.py — asyncio.run() в WSGI контексті

**Файл:** `erpnext/security_erp/security_erp/ai/api.py`

### Проблема: 🔴 КРИТИЧНА

```python
# Рядок 83
result = asyncio.run(orch.execute(task, payload_dict, params_dict))
```

**Контекст:**
- `execute_ai()` — це `@frappe.whitelist()` метод, який викликається через HTTP у Frappe-процесі.
- Frappe працює на **Gunicorn з gevent-воркерами** (стандартна конфігурація).
- `gevent` monkey-patches stdlib, включаючи `threading` і `socket`.
- `asyncio.run()` створює новий event loop. У gevent-контексті це **непередбачувано**: gevent блокує I/O на рівні сокетів, а asyncio очікує на свій event loop.

**Fallback-код (рядки 84-89):**
```python
except RuntimeError:
    loop = asyncio.new_event_loop()
    try:
        result = loop.run_until_complete(...)
    finally:
        loop.close()
```

Цей fallback ловить `RuntimeError` (якщо event loop вже існує), але **не вирішує фундаментальну проблему gevent+asyncio несумісності**. Можливі сценарії:
- `asyncio.run()` працює випадково (якщо gevent ще не запатчив event loop у поточному greenlet) — **мовчазний успіх**
- Deadlock: gevent блокує сокет, asyncio чекає на I/O через свій event loop — **зависання**
- `RuntimeError` → fallback створює `new_event_loop()` під gevent — **непередбачувана поведінка**

**Додатково:** `aioredis.Redis` (async client) використовується всередині `orch.execute()`, але `_get_redis()` (рядок 22-25) створює **async** клієнт. У sync Frappe-контексті цей клієнт не буде коректно працювати без event loop.

**Контракт §4.6 (docs/03_api_ai_architecture.md):**
> "RQ-воркери (БЕЗ Vault key-context)" — оркестратор має працювати в RQ-контексті (sync), а `orchestrator.py` написаний повністю async.

**Вердикт:** `asyncio.run()` в Frappe `@whitelist` — **архітектурний конфлікт**. Frappe = WSGI (gevent), orchestrator = async. Працює випадково або висне.

---

## 3. transcribe.py — drive_file_id обробка

**Файл:** `erpnext/security_erp/security_erp/tasks/transcribe.py`

### 3.1 URL vs Google Drive ID: 🟡 ЧАСТКОВО НЕБЕЗПЕЧНО

```python
# Рядки 53-57
drive_id = doc.drive_file_id
if drive_id.startswith("http"):
    audio_url = drive_id
else:
    audio_url = f"https://drive.google.com/uc?export=download&id={drive_id}"
```

**Проблема:** Код припускає, що якщо `drive_file_id` не починається з `http` — це Google Drive file ID. Але:
- `Media Asset.drive_file_id` — це `Data` field (varchar 140), без валідації формату.
- Туди може потрапити: Google Drive ID, OneDrive URL, локальний шлях, довільний рядок.
- `https://drive.google.com/uc?export=download&id=` працює лише для **публічних** файлів Google Drive.
- Для приватних файлів Google поверне HTML-сторінку з підтвердженням вірусного сканування (для файлів >100MB) або 403.

### 3.2 Google Drive download для великих файлів: 🔴 НЕПРАЦЮЄ

Google Drive `uc?export=download` endpoint:
- Для файлів <100MB: працює (якщо файл публічний).
- Для файлів >100MB: повертає HTML-сторінку "Download anyway" замість файлу.
- Для приватних файлів: повертає 403 або redirect на login.

**Рішення потребує:** Google Drive API з OAuth2/service account, або використання `google-api-python-client` (вже в `requirements.txt` security-api, але НЕ в Frappe-контейнері).

### 3.3 _set_status("error") — неіснуючий Select option: 🟡

```python
# Рядки 66, 85
_set_status(doc, "error")
```

`Media Asset.transcription_status` — Select з options: `none|pending|done|manual`. Значення `"error"` **не входить** до цього списку. Оскільки `_set_status` використовує `db_set` (bypasses validation), значення запишеться в БД, але:
- UI-фільтр не покаже "error" статус коректно.
- Select dropdown не матиме цієї опції.

**Вердикт:** `drive_file_id` обробка працює лише для публічних Google Drive файлів <100MB. Статус "error" неіснуючий у Select.

---

## 4. ai_estimate.py — _run_orchestrator_sync()

**Файл:** `erpnext/security_erp/security_erp/tasks/ai_estimate.py`

### 4.1 asyncio.get_event_loop(): ✅ НЕ ВИКОРИСТОВУЄТЬСЯ

Код НЕ використовує `asyncio.get_event_loop()` (deprecated у Python 3.12). Використовується `asyncio.run()`.

### 4.2 _run_orchestrator_sync() — реальність: 🟡 ЧАСТКОВО РЕАЛЬНА

```python
# Рядки 82-111
def _run_orchestrator_sync(providers, task, payload):
    for provider in providers:
        try:
            result = provider.complete_sync(task, payload, None) if hasattr(provider, "complete_sync") else None
            if result is None:
                result = asyncio.run(_timed_call(provider, task, payload, None))
```

**Аналіз:**
1. Спочатку намагається `provider.complete_sync()` — **не існує** ні в `GeminiAdapter`, ні в `StubAdapter`. Обидва мають лише `async def complete()`. Тому `hasattr(provider, "complete_sync")` завжди `False` → `result = None`.
2. Потім `asyncio.run(_timed_call(...))` — та сама проблема, що в `api.py`: asyncio.run() в RQ-воркері (який працює під gevent).
3. Circuit Breaker **не використовується** в цьому шляху (коментар: "without circuit breaker — Redis sync client not available"). Це означає, що RQ-шлях не має failover-логіки CB.

**Додатково:** `_timed_call` (рядок 114-117) — async функція, яка імпортує `timed_call` з `adapters.base`. Це коректний async-код, але його виклик через `asyncio.run()` в gevent-контексті — та сама проблема.

**Вердикт:** `_run_orchestrator_sync()` — **не реально синхронний**. Він падає в `asyncio.run()` через fallback-path. Circuit Breaker не задіяний.

---

## 5. Whisper entry points — main.py vs app.py

**Директорія:** `services/whisper/`

| Файл | Існує? | Призначення |
|------|--------|-------------|
| `main.py` | ✅ | FastAPI app (`app = FastAPI(...)`) |
| `app.py` | ❌ | Не існує |

**Dockerfile CMD:**
```dockerfile
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000", "--workers", "1"]
```

**docker-compose.yml:**
```yaml
whisper:
  build:
    context: ./services/whisper
    dockerfile: Dockerfile
```

**Вердикт:** Конкуруючих entry points **немає**. Єдиний entry point — `main.py`. Dockerfile CMD коректний (`main:app`). Жодної проблеми.

---

## 6. ai.py — cross-package import доступність

**Файл:** `services/security-api/app/routes/ai.py`

### 🔴 КРИТИЧНА ПРОБЛЕМА: security_erp НЕДОСТУПНИЙ в security-api контейнері

```python
# Рядки 40-43 (у _build_orchestrator)
from security_erp.ai.adapters.gemini import GeminiAdapter
from security_erp.ai.adapters.stub import StubAdapter
from security_erp.ai.circuit_breaker import CircuitBreaker
from security_erp.ai.orchestrator import AIOrchestrator
```

**Аналіз Dockerfile (`services/security-api/Dockerfile`):**
```dockerfile
FROM python:3.12-slim
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .   # копіює лише services/security-api/
```

`security_erp` пакет **НЕ встановлений** в контейнері security-api. Немає:
- `pip install` для security_erp
- Volume mount (як у `Dockerfile.backend`)
- `.pth` файлу

**Чому CI проходить:**
```yaml
# .github/workflows/ci.yml
PYTHONPATH: services/security-api:erpnext/security_erp
```

CI додає `erpnext/security_erp` до `PYTHONPATH`, тому імпорти резолвляться. **Але Docker-контейнер цього не має.**

**docker-compose.yml:** `security-api` **відсутній** у `docker-compose.yml`. Посилання на нього є лише в `configs/cloudflared/config.yml`:
```yaml
service: http://security-api:8000
```

Це означає або:
- security-api запускається окремо (не через docker-compose)
- Він був видалений з compose, але cloudflared конфіг не оновлений
- Є інший compose-файл (не знайдено)

**Вердикт:** `_build_orchestrator()` імпортує `security_erp.*`, але цей пакет **недоступний** в runtime контейнері security-api. Endpoint `POST /api/v2/ai/execute` **падає з ImportError** при виклику.

---

## Зведена таблиця знахідок

| # | Файл | Знахідка | Серйозність |
|---|------|----------|-------------|
| 1 | `orchestrator.py` | Всі імпорти резолвляться (в Frappe-контексті) | ✅ OK |
| 2 | `api.py` | `asyncio.run()` в WSGI/gevent контексті — непередбачувано | 🔴 Критична |
| 3 | `transcribe.py` | `drive_file_id` обробка працює лише для публічних GDrive <100MB | 🟡 Обмеження |
| 4 | `transcribe.py` | `_set_status("error")` — неіснуючий Select option | 🟡 Баг |
| 5 | `ai_estimate.py` | `_run_orchestrator_sync()` не реально sync; `complete_sync()` не існує | 🟡 Частково непрацює |
| 6 | `ai_estimate.py` | Circuit Breakер не задіяний в RQ-шляху | 🟡 Обмеження |
| 7 | `whisper/main.py` vs `app.py` | Конкуруючих entry points немає | ✅ OK |
| 8 | `ai.py` (security-api) | `security_erp.*` імпорти **недоступні** в Docker-контейнері | 🔴 Критична |

---

## Контрактна звірка з §4.6 (docs/03_api_ai_architecture.md)

| Контракт §4.6 | Реалізація | Статус |
|---------------|-----------|--------|
| RQ-задача `transcribe_media` | `transcribe.py:transcribe_media()` | ✅ Реалізовано |
| Whisper self-hosted контейнер, HTTP | `whisper/main.py`, `WHISPER_URL = "http://whisper:8000/transcribe"` | ✅ Реалізовано |
| concurrency=1, cpu/mem ліміти | `asyncio.Lock` + docker-compose `deploy.resources.limits` | ✅ Реалізовано |
| Деградація: status=очікує → ручний текст | `_set_status(doc, "pending")` при whisper_unavailable | ✅ Реалізовано |
| Транскрипт — ДЛЯ ЛЮДИНИ, не авто-в AI | Жодного автоматичного виклику AISL після транскрипції | ✅ Контракт дотримано |
| RQ-воркери БЕЗ Vault key-context | `transcribe.py`, `ai_estimate.py` не імпортують vault | ✅ Контракт дотримано |
| Circuit Breaker у Redis (спільний стан) | `circuit_breaker.py` — Lua-скрипт, атомарні переходи | ✅ Реалізовано |
| CB НЕ per-process | CB в Redis — ✅. Але `_run_orchestrator_sync()` обходить CB | 🟡 Часткове порушення |

---

## Рекомендації (для наступних сесій, НЕ впроваджуються)

1. **api.py asyncio.run()** → замінити на sync-варіант оркестратора або винести AI-виклик в RQ-задачу (як передбачено §4.7).
2. **ai.py cross-package import** → або встановити `security_erp` в контейнер security-api (pip install + volume), або перенести оркестрацію повністю в Frappe-процес і зробити security-api тонким проксі (як у V3 для Vault).
3. **transcribe.py drive_file_id** → додати Google Drive API з service account для приватних файлів; замінити `_set_status("error")` на `_set_status("manual")` (існуючий Select option).
4. **ai_estimate.py _run_orchestrator_sync()** → реалізувати справжній sync-варіант `complete_sync()` в адаптерах, або використовувати `httpx` (sync) замість async-адаптерів у RQ-контексті.
