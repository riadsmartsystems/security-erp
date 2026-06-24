# Аудит Блоку 5: Тести та компіляція

**Дата:** 2026-06-23
**Метод:** verification-before-completion (Evidence before claims)
**Статус:** АУДИТ — нічого не виправлено

---

## 1. Тестова таблиця

| Тест | Статус | Кількість | Помилка |
|------|--------|-----------|---------|
| `tests/s1/test_s1_sync.py` | ❌ ERROR | 9/9 fail | `ModuleNotFoundError: pydantic` (та `httpx`) |
| `tests/ai/test_a1_circuit_breaker.py` | ❌ ERROR | 0 (import fail) | `ModuleNotFoundError: redis` |
| `tests/ai/test_a2_ai_service.py` | ❌ ERROR | 11/11 fail | `ModuleNotFoundError: httpx` (та `fastapi`) |
| `tests/a3/test_a3_tasks.py` | ✅ PASS | 10/10 | — |
| `tests/a4/test_a4_session.py` | ❌ ERROR | 27/27 fail | `ModuleNotFoundError: fastapi`, `httpx`, `jose` |
| `tests/s4/test_s4_gateway.py` | ❌ ERROR | 0 (import fail) | `ModuleNotFoundError: httpx` |
| `tests/vault_isolation/check_vault_isolation.py` | ✅ PASS | — | 58 files scanned across 7 restricted paths |
| `tests/ai_isolation/check_ai_isolation.py` | ✅ PASS | — | 67 files scanned across 4 restricted paths |
| `tests/vault/test_act_pure.py` | ✅ PASS | exit 0 | — |
| `tests/security-api/test_models.py` | ⚠️ SKIP | 1 pass / 15 skip | Missing: `fastapi`, `pydantic_settings`, `httpx` |

**Підсумок:** 3 PASS, 6 ERROR, 1 SKIP (15 підтестів)

---

## 2. Відсутні залежності

| Пакет | Потрібен для тестів | Наявний локально? |
|-------|---------------------|-------------------|
| `pydantic` | test_s1_sync, test_models | ❌ |
| `httpx` | test_s1_sync, test_a2, test_a4, test_s4, test_models | ❌ |
| `fastapi` | test_a2, test_a4, test_models | ❌ |
| `redis` | test_a1_circuit_breaker | ❌ |
| `jose` (python-jose) | test_a4_session | ❌ |
| `pydantic_settings` | test_models | ❌ |

**Причина:** Тести написані для запуску в Docker-контейнері `security-api` де всі залежності встановлені. На хост-машині pip-пакети не встановлені.

**Виняток:** `test_a3_tasks.py` працює бо використовує лише stdlib + тести чистих функцій без FastAPI/httpx імпортів. `check_vault_isolation.py` та `check_ai_isolation.py` — AST-сканери на stdlib. `test_act_pure.py` — чисті обчислення.

---

## 3. py_compile — синтаксис файлів

### 3.1 `services/security-api/app/**/*.py`

**Статус:** ✅ ВСІ OK (0 помилок)

### 3.2 `erpnext/security_erp/security_erp/tasks/**/*.py`

**Статус:** ✅ ВСІ OK (0 помилок)

### 3.3 `erpnext/security_erp/security_erp/ai/**/*.py`

**Статус:** ✅ ВСІ OK (0 помилок)

---

## 4. Вердикт

| Критерій | Статус |
|----------|--------|
| Тести запускаються на хості | ❌ 6/10 падають через відсутні pip-пакети |
| Тести працюють у Docker | ⚠️ Не перевірялось (потрібен running контейнер) |
| Isolation-чеки (AST) | ✅ 2/2 PASS |
| py_compile всіх .py | ✅ 0 помилок |
| Чисті тести (stdlib only) | ✅ 2/2 PASS (a3, vault act) |

**Критична знахідка:** 67 тестів (9+11+27+...) не можуть запуститись на хості через відсутність pip-залежностей. CI використовує `python tests/security-api/test_models.py` з graceful skip — але це означає що **CI фактично не тестує бізнес-логіку**, лише syntax check.

**Рекомендація (не впроваджено — аудит-only):** Додати `pip install fastapi pydantic httpx python-jose[cryptography] redis` до CI або запускати тести всередині Docker-контейнера.
