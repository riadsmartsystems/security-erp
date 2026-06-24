# Повний аудит RIAD Security ERP — Фази R1–S4

**Дата:** 2026-06-23  
**Аудитор:** незалежна перевірка (Claude Code, claude-sonnet-4-6)  
**Метод:** verification-before-completion — evidence before claims  
**Статус:** АУДИТ, нічого не виправлено

---

## 0. Джерела правди (прочитано)

| Документ | Статус |
|---|---|
| `CLAUDE.md` (конституція) | ✅ прочитано |
| `docs/DECISIONS.md` | ✅ прочитано повністю |
| `BUILD_LOG.md` (1523 рядки) | ✅ прочитано повністю |
| `docs/07_build_playbook.md` | ✅ прочитано |
| `docs/02_data_model.md` | звірено через JSON-аудит DocType |

---

## 1. ЗВЕДЕНА ТАБЛИЦЯ ЗНАХІДОК

| # | Блок | Фаза | Знахідка | Серйозність | Файл:рядок |
|---|---|---|---|---|---|
| 1 | A | R3 | Refresh-ротація + reuse-detection НЕ реалізовано: `create_refresh_token` не містить `jti`/`did`; у `/refresh` немає blacklist-перевірки; `GET/DELETE /sessions` відсутні | 🔴 CRITICAL | `app/auth/jwt.py:37`, `app/routes/auth.py:51` |
| 2 | A | R4 | BUILD_LOG R4 = rate limiting; Playbook R4 = gateway discipline. Gateway discipline (CI-лінт проти direct frappe_get з routes/) НЕ реалізована і відсутня в CI | 🔴 CRITICAL | `ci.yml` (відсутній крок), `app/routes/visits.py`, `app/routes/vault.py` |
| 3 | A | R4 | Per-endpoint rate limit для `/login`/`/refresh` (з BUILD_LOG R4) відсутній в `auth.py`; є лише глобальний middleware по IP в `main.py` | 🟡 HIGH | `app/routes/auth.py` (весь файл), `app/main.py:64` |
| 4 | A | R2 | Українські ролі (`Технік`→`engineer`, `Бухгалтер`→`accountant`, `Склад`→`warehouse`, `Директор`→`director`) з BUILD_LOG R2 DoD відсутні в `_map_frappe_role_from_names()` | 🟡 HIGH | `app/routes/auth.py:161-174` |
| 5 | B | R6 | `estimate.json` НЕ містить поля R6: `origin`, `variant`, `reviewed_by`, `reviewed_at`, `total_cost`, `total_margin` | 🔴 CRITICAL | `doctype/estimate/estimate.json` |
| 6 | B | R6 | `estimate_item.json` НЕ містить поля R6: `purchase_rate`, `profit`, `margin_pct`, `line_source` | 🔴 CRITICAL | `doctype/estimate_item/estimate_item.json` |
| 7 | B | R6 | Жодне поле `estimate`/`estimate_item` не має `permlevel=1` в JSON → permlevel-приховування цін НЕ працює через REST API | 🔴 CRITICAL | `doctype/estimate/estimate.json`, `doctype/estimate_item/estimate_item.json` |
| 8 | C | V1 | `vault/_key.py`, `vault/_crypto.py`, `vault/_hooks.py`, `vault/api.py`, `vault/audit.py`, `vault/mfa.py` ВІДСУТНІ з файлової системи (є лише `.pyc` в `__pycache__`) | 🔴 CRITICAL | `erpnext/security_erp/security_erp/vault/` |
| 9 | C | V1 | `vault_entry.py:7` імпортує `from security_erp.vault._hooks import encrypt_doc_fields` → `ImportError` при кожному `before_save` | 🔴 CRITICAL | `doctype/vault_entry/vault_entry.py:7` |
| 10 | C | V2 | CI крок `V2 Vault isolation lint` (`tests/vault_isolation/check_vault_isolation.py`) ВІДСУТНІЙ в `.github/workflows/ci.yml` | 🔴 CRITICAL | `ci.yml` (відсутній крок) |
| 11 | D | A3/A4 | `estimate_service.py:108` викликає `security_erp.tasks.ai_estimate.enqueue_ai_estimate` — функція НЕ ІСНУЄ; у файлі є лише `run_ai_estimate` | 🔴 CRITICAL | `app/services/estimate_service.py:108` |
| 12 | D | A3 | `tasks/ai_estimate.py:37` використовує `frappe.get_all("AI Provider", filters={"is_active": 1})` — поле `is_active` відсутнє; DocType має `is_enabled` | 🟡 HIGH | `tasks/ai_estimate.py:37` |
| 13 | D | A3 | `Media Asset` DocType не має поля `transcription_status` у JSON; `_set_status()` викликає `db_set("transcription_status", ...)` на неіснуючому полі | 🟡 HIGH | `tasks/transcribe.py:103-109`, `doctype/media_asset/media_asset.json` |
| 14 | D | A2/A3 | PII-анонімізація перед зовнішнім AI-викликом: відсутній NER-шар; `estimate_service.py:58` передає `brief_text` напряму в AI без scrubbing | ⚪ LOW (design) | `app/services/estimate_service.py:58`, `app/routes/ai.py` |
| 15 | B | R4 | Прямі виклики `frappe_get/post/put` з routes/ (обхід сервіс-шару): `visits.py`, `vault.py`, `ai_admin.py`, `ai.py`, `maps.py`, `media.py`, `warehouse.py`, `act.py` | 🟡 HIGH | `app/routes/*.py` (множина файлів) |
| 16 | E | S1 | Watermark формально "непрозорий" для клієнта (`base64(json(ts))`), але структура тривіально декодується — порушує контракт "opaque token" | ⚪ LOW | `app/services/sync_service.py:70-78` |
| 17 | C | V4 | `act.py` в Vault існує ✅; але Vault UI (`act.html`) і Desk buttons зазначені в BUILD_LOG — перевірка presence ERPNext desk JS файлів не проводилась (немає running ERPNext) | НЕ ПЕРЕВІРЕНО | `vault/act.py` |
| 18 | A | R5 | BUILD_LOG R5 фіксує критичні прогалини (binlog вимкнено, Redis AOF вимкнено, бекап-пайплайн зламаний). Виправлення (R5-FIX-1..5) НЕ виконані як окремі commit'и — код `backup-mariadb.sh` та `configs/mariadb.cnf` не перевірено | НЕ ПЕРЕВІРЕНО | `scripts/`, `configs/mariadb.cnf` |

---

## 2. БЛОК A — Фази R1–R4: Auth / RBAC / Sessions

### R1 — Per-user делегування

| Перевірка | Результат | Доказ |
|---|---|---|
| `database.py` прибрано Administrator-логін | ✅ | `app/core/database.py` — `frappe_login()` повертає user SID; `frappe_get/post/put/delete` приймають `sid=` |
| Frappe SID зберігається в Redis per-user | ✅ | `app/routes/auth.py:30` `redis_client.setex("frappe:sid:{user_id}", ...)` |
| `CurrentUser.frappe_sid` доступний у хендлерах | ✅ | `app/auth/dependencies.py:55` читає SID з Redis |
| Запити до Frappe йдуть від реального юзера | ✅ | всі `frappe_get(…, sid=current_user.frappe_sid)` |

**Вердикт R1: DoD виконано.** ✅

---

### R2 — Реальні Frappe-ролі

| Перевірка | Результат | Доказ |
|---|---|---|
| `_default_role()` відсутній | ✅ | `app/routes/auth.py` — функція відсутня |
| `_extract_frappe_roles()` витягує ролі з Frappe | ✅ | `app/routes/auth.py:151-153` |
| Маппінг Frappe→FastAPI Role | ⚠️ ЧАСТКОВО | English ролі маппляться; Українські (`Технік`, `Бухгалтер`, `Склад`, `Директор`) — відсутні в `_map_frappe_role_from_names()` (рядки 162-174) |
| `frappe_roles` у JWT і `/me` | ✅ | `app/auth/jwt.py:31`, `app/routes/auth.py:101` |

**Вердикт R2: DoD частково виконано.** ⚠️ Українські назви ролей не маппляться — Frappe-User з роллю `Технік` отримає `role: "viewer"`, а не `"engineer"`.

---

### R3 — Refresh-ротація + reuse-detection + Device Session

| Перевірка | Результат | Доказ |
|---|---|---|
| `create_refresh_token` містить `jti` (UUID) | 🔴 НІ | `app/auth/jwt.py:37-45` — лише `sub`, `type`, `iat`, `exp` |
| `create_refresh_token` містить `did` (device_id) | 🔴 НІ | те саме |
| `/refresh` перевіряє `rt:bl:{jti}` blacklist | 🔴 НІ | `app/routes/auth.py:51-78` — blacklist-перевірки немає |
| reuse-detection: старий RT → `REFRESH-REUSE` | 🔴 НІ | логіка відсутня |
| `GET /api/v2/auth/sessions` | 🔴 НІ | endpoint відсутній |
| `DELETE /api/v2/auth/sessions/{device_id}` | 🔴 НІ | endpoint відсутній |
| `RIAD Device Session` DocType (схема) | ✅ | `doctype/riad_device_session/riad_device_session.json` існує з полями `user, device_id, jwt_jti, revoked, ...` |

**Вердикт R3: DoD провалено.** 🔴 BUILD_LOG каже "✅ DONE" — але жодна з ключових функцій (jti, blacklist, reuse-detection, sessions endpoints) не присутня в коді. DocType-схема існує, логіка — ні.

---

### R4 — (BUILD_LOG) Rate limiting / (Playbook) Gateway discipline

**Конфлікт**: Playbook R4 = "Gateway-дисципліна: v2 DTO-шар + лінт «без сирого DocType поза сервіс-шаром»". BUILD_LOG R4 = "Rate limiting для auth endpoints". Ці задачі різні.

| Перевірка (Playbook R4: gateway discipline) | Результат | Доказ |
|---|---|---|
| CI-лінт, що routes/ не викликають `frappe_get` напряму | 🔴 НІ | `ci.yml` — такого кроку немає |
| Обов'язковий сервіс-шар між routes і database | 🔴 НІ | `visits.py`, `vault.py`, `ai_admin.py`, `ai.py`, `maps.py`, `media.py`, `warehouse.py`, `act.py` — прямі виклики |

| Перевірка (BUILD_LOG R4: per-endpoint rate limit) | Результат | Доказ |
|---|---|---|
| `/login`: sliding window 5/900s per IP | 🔴 НІ | `app/routes/auth.py` — імпорт `check_rate_limit` відсутній |
| `/refresh`: sliding window 30/900s per user_id | 🔴 НІ | те саме |
| Глобальний rate limit middleware | ✅ | `app/main.py:63-80` — простий incr per IP |
| `rate_limit.py` модуль | ✅ | `app/core/rate_limit.py` існує з sliding window реалізацією |

**Вердикт R4: DoD провалено (обидва варіанти).** 🔴 Sliding window rate limit існує як модуль, але не підключений до auth endpoints. Gateway discipline не реалізована і не задокументована в CI.

---

## 3. БЛОК B — Фази R4–R8: Gateway-дисципліна + дата-модель

### R4 — Прямі виклики з routes/ (детальний перелік)

```
app/routes/visits.py       — 4 прямі виклики frappe_put/post
app/routes/vault.py        — 5 прямі виклики frappe_post/get
app/routes/act.py          — 1 прямий виклик frappe_post
app/routes/ai_admin.py     — 4 прямі виклики frappe_get/put/post
app/routes/ai.py           — 1 прямий виклик frappe_post
app/routes/maps.py         — 4 прямі виклики frappe_get/put
app/routes/media.py        — 5 прямих викликів frappe_get/put/post
app/routes/warehouse.py    — 3 прямих виклики frappe_get
app/routes/doctypes.py     — 15+ прямих викликів (legacy, але prefix /api/v2/)
```

Найчистіші (через сервіс-шар): `estimates.py`, `sync.py`, `scenarios.py`.

**CI-лінт відсутній.** `ci.yml` не має кроку, який перевіряє `frappe_get/post` у `routes/`.

---

### R5 — Durability audit

BUILD_LOG R5 задокументував 5 критичних прогалин (R5-FIX-1..5):

| Прогалина | Статус виправлення |
|---|---|
| R5-FIX-1: binlog вимкнено | НЕ ПЕРЕВІРЕНО — `configs/mariadb.cnf` не читався |
| R5-FIX-2: Redis AOF вимкнено | НЕ ПЕРЕВІРЕНО — `configs/redis.conf` не читався |
| R5-FIX-3: бекапи незашифровані | НЕ ПЕРЕВІРЕНО — `scripts/backup-mariadb.sh` не читався |
| R5-FIX-4: бекап-пайплайн зламаний | НЕ ПЕРЕВІРЕНО — потрібен running cron |
| R5-FIX-5: restore без `--databases` | НЕ ПЕРЕВІРЕНО |

**Вердикт R5:** НЕ ПЕРЕВІРЕНО. BUILD_LOG задокументував проблеми, але не фіксує їх виправлення.

---

### R6 — Дата-модель: злиття перетинів

| DocType | Поля R6 | В JSON | permlevel |
|---|---|---|---|
| `visit.json` | client_uuid, riad_version, riad_deleted, riad_deleted_at | ✅ всі | n/a |
| `visit_material.json` | ті самі | ✅ всі | n/a |
| `visit_photo.json` | ті самі | ✅ всі | n/a |
| `estimate.json` | origin, variant, reviewed_by, reviewed_at, total_cost, total_margin | 🔴 ЖОДНОГО | 🔴 немає |
| `estimate_item.json` | purchase_rate, profit, margin_pct, line_source | 🔴 ЖОДНОГО | 🔴 немає |

Перевірено командою: `python3 -c "import json; d=json.load(open('...estimate.json')); [print(f) for f in d['fields']]"` — поля origin/variant/reviewed_by тощо відсутні.

**Вердикт R6: DoD частково виконано.** ✅ Visit sync-поля OK. 🔴 Estimate/EstimateItem поля відсутні в JSON → permlevel не ензфорсується через REST API.

---

### R7 — Батч відсутніх DocType (13 штук)

| DocType | Присутній |
|---|---|
| Site Brief | ✅ |
| Object Passport | ✅ |
| Passport Client Release | ✅ |
| Installation Map | ✅ |
| Mount Point | ✅ |
| Cable Route | ✅ |
| Checklist Template | ✅ |
| Checklist Template Item | ✅ |
| Checklist Instance | ✅ |
| Checklist Instance Item | ✅ |
| Remote Inspection | ✅ |
| Remote Inspection Media | ✅ |
| Media Asset | ✅ |

Object Passport → `security_object (Link)` без дублювання CMDB ✅  
Media Asset `ai_allowed default=0` ✅ (перевірено: `ai_allowed int(1) NOT NULL DEFAULT 0`)

**Вердикт R7: DoD виконано.** ✅

---

### R8 — Vault-неймспейс DocType (8 штук)

| DocType | Присутній | *_enc = Long Text |
|---|---|---|
| Vault Entry | ✅ | ✅ (login/password/ip/domain/ddns/serial/notes_enc = Long Text, permlevel=1) |
| Vault Access Enrollment | ✅ | ✅ (totp_secret_enc = Long Text, permlevel=1) |
| Vault Audit Log | ✅ | n/a |
| Access Transfer Act | ✅ | n/a |
| Access Transfer Act Entry | ✅ | n/a |
| AI Provider | ✅ | n/a (немає api_key_enc у JSON!) |
| AI Request Log | ✅ | n/a |
| Sync Conflict | ✅ | n/a |

**Vault Entry *_enc поля**: перевірено `vault_entry.json` — всі 7 `*_enc` полів мають `fieldtype: "Long Text"` та `permlevel: 1` ✅

**КОНФЛІКТ**: `ai_estimate.py:47` використовує `p.get("api_key_enc", "")` — поле `api_key_enc` відсутнє в `ai_provider.json`. Це несумісність між кодом і схемою.

AI Request Log жодного Link на Vault ✅

**Вердикт R8: DoD виконано** (схема) ✅ але є несумісність ai_estimate.py vs ai_provider.json.

---

## 4. БЛОК C — Фази V1–V4: Vault

### V1 — Vault-модуль: криптографічне ядро

| Компонент | Статус | Доказ |
|---|---|---|
| `security_erp/vault/_key.py` | 🔴 ВІДСУТНІЙ (файл) | лише `__pycache__/_key.cpython-311/312.pyc` |
| `security_erp/vault/_crypto.py` | 🔴 ВІДСУТНІЙ (файл) | лише `.pyc` |
| `security_erp/vault/_hooks.py` | 🔴 ВІДСУТНІЙ (файл) | лише `.pyc` |
| `security_erp/vault/api.py` | 🔴 ВІДСУТНІЙ (файл) | лише `.pyc` |
| `security_erp/vault/__init__.py` | 🔴 ВІДСУТНІЙ (файл) | лише `.pyc` |
| `security_erp/vault/act.py` | ✅ присутній | файл існує |
| `vault_entry.py` before_save | 🔴 КРАШИТЬ | рядок 7: `from security_erp.vault._hooks import encrypt_doc_fields` → `ModuleNotFoundError` |

**Пояснення**: `.pyc` файли в `__pycache__` доводять, що вихідні файли ІСНУВАЛИ (збирались), але більше не присутні в робочому дереві. Вони або видалені, або не committed до репозиторію.

**Вердикт V1: DoD провалено.** 🔴 Крипто-ядро Vault відсутнє у вихідному коді. `VaultEntry.before_save()` крашить при кожному збереженні.

---

### V2 — Ізоляція Vault↔AI (CI двошарова) + hash-chain аудит

| Перевірка | Результат | Доказ |
|---|---|---|
| `tests/vault_isolation/check_vault_isolation.py` існує | ✅ | файл існує, коректний AST-сканер |
| CI крок `V2 Vault isolation lint` у `ci.yml` | 🔴 ВІДСУТНІЙ | `ci.yml` не містить кроку для `check_vault_isolation.py` |
| CI крок `A1 AI-Vault isolation lint` | ✅ | `ci.yml:71-73` — `python tests/ai_isolation/check_ai_isolation.py` |
| `audit.py` (hash-chain) | 🔴 ВІДСУТНІЙ (файл) | лише `__pycache__/audit.cpython-311.pyc` |
| Vault-імпорти в AI/tasks шляхах | ✅ | `check_vault_isolation.py` якщо запустити — проходить (немає vault-імпортів у restricted paths) |

**Вердикт V2: DoD частково.** ⚠️ AST-лінтер існує і коректний, але не підключений до CI. Hash-chain `audit.py` відсутній у джерелах.

---

### V3 — MFA step-up + Vault read/write API

| Компонент | Статус | Доказ |
|---|---|---|
| `security_erp/vault/mfa.py` | 🔴 ВІДСУТНІЙ | лише `.pyc` |
| FastAPI `/api/v2/vault/mfa/enroll` | ✅ | `app/routes/vault.py:53-60` |
| FastAPI `/api/v2/vault/mfa/verify` | ✅ | `app/routes/vault.py:71-79` |
| FastAPI `/api/v2/vault/entry/decrypt` | ✅ | `app/routes/vault.py:81-100` |
| FastAPI `/api/v2/vault/entry/upsert` | ✅ | `app/routes/vault.py:103-135` |
| FastAPI ці роути делегують до Frappe `vault.*` | ✅ | `vault.py` викликає `frappe_post("/api/method/security_erp.vault.mfa.*")` |

Проблема: FastAPI routes викликають Frappe whitelist methods, але самі whitelist methods (`vault.mfa`, `vault.api`) відсутні у вихідному коді → виклики завершаться 404/500 від Frappe.

**Вердикт V3: DoD провалено.** 🔴 Frappe-модулі `vault.mfa` і `vault.api` відсутні.

---

### V4 — Access Transfer Act

| Компонент | Статус | Доказ |
|---|---|---|
| `security_erp/vault/act.py` | ✅ | файл існує |
| Frappe whitelist `act.generate/serve/acknowledge` | ✅ | `vault/act.py` — 4 `@frappe.whitelist` методи |
| Redis keys `act:tok:`, `act:otp:`, `act:act_to_tok:` | ✅ | `vault/act.py` |
| MariaDB зберігає лише `sha256(token)` | ✅ | `vault/act.py:deliver_token` |
| FastAPI `/api/v2/act/public/{token}` (без JWT) | ✅ | `app/routes/act.py` |
| Vault Audit Log action: `act_revoke/view/acknowledge` | ✅ | `vault_audit_log.json` — всі 3 дії в Select |
| Gate C2 задокументовано | ✅ | BUILD_LOG V4 |

**Вердикт V4: DoD виконано** (для того що можна перевірити без running ERPNext). ✅

---

### Vault: критичний шлях Vault → AISL

Виконано grep всіх AI/tasks шляхів:

```bash
grep -rn "from security_erp.vault\|import security_erp.vault" \
  erpnext/security_erp/security_erp/ai/ \
  erpnext/security_erp/security_erp/tasks/ \
  services/security-api/
```

**Результат:** Vault-імпортів в AI/tasks/security-api не знайдено. ✅ Ізоляція на рівні коду дотримана. Але CI-gate (V2 Vault isolation lint) у `ci.yml` відсутній → ніщо не запобігає регресії.

---

## 5. БЛОК D — Фази A1–A4: AI-шар

### A1 — Провайдер-агностичний AI-адаптер + Circuit Breaker

| Перевірка | Результат | Доказ |
|---|---|---|
| `AbstractAIAdapter` з `complete()/health_check()` | ✅ | `ai/adapters/base.py` |
| `GeminiAdapter`, `StubAdapter` | ✅ | `ai/adapters/gemini.py`, `ai/adapters/stub.py` |
| Circuit Breaker через Redis (не per-process) | ✅ | `ai/circuit_breaker.py` — Lua-скрипт на `cb:provider:{name}` ключах |
| Failover: primary→fallback→manual | ✅ | `ai/orchestrator.py` |

**Вердикт A1: DoD виконано.** ✅

---

### A2 — AI Request Log + sync_provider_health + AI Execute

| Перевірка | Результат | Доказ |
|---|---|---|
| `POST /api/v2/ai/execute` | ✅ | `app/routes/ai.py` |
| AI Request Log після кожного execute | ✅ | `app/services/ai_orchestrator_service.py:write_ai_request_log` |
| `_anonymize_payload`: тільки ключі + довжини | ✅ | `ai_orchestrator_service.py:28-33` |
| `sync_provider_health` | ✅ | `ai_orchestrator_service.py:sync_provider_health` |
| `GET /api/v2/ai/providers` | ✅ | `app/routes/ai.py` |
| scheduler hook для `sync_provider_health` | НЕ ПЕРЕВІРЕНО | потрібен running Frappe scheduler |

**Вердикт A2: DoD виконано.** ✅

---

### A3 — Whisper self-hosted + RQ-задачі

| Перевірка | Результат | Доказ |
|---|---|---|
| Whisper як окремий контейнер | ✅ | `services/whisper/` (main.py, Dockerfile) |
| `concurrency=1` (asyncio.Lock) | ✅ | `services/whisper/main.py` |
| `transcribe_media` RQ-задача | ✅ | `tasks/transcribe.py:43` |
| Транскрипт ЛИШЕ в `Media Asset.transcription`, НЕ автоматично в AI | ✅ | `tasks/transcribe.py:93` |
| `asyncio.run()` в RQ контексті (виправлено) | ✅ | FIX 2.5: `tasks/ai_estimate.py:81` — `timed_call()`, не asyncio.run |
| `_set_status` пише `transcription_status` | 🔴 | `media_asset.json` НЕ має поля `transcription_status` |
| `ai_estimate.py:37` filter `is_active` vs DocType `is_enabled` | 🔴 | `ai_provider.json` field = `is_enabled`, код фільтрує `is_active` |

**Вердикт A3: DoD частково.** ⚠️ `asyncio.run()` виправлено ✅. Але `transcription_status` і `is_active` vs `is_enabled` — баги.

---

### A4 — Estimate lifecycle + no-code адмінки + AI-деградація

| Перевірка | Результат | Доказ |
|---|---|---|
| `POST /api/v2/estimates/build` | ✅ | `app/routes/estimates.py` |
| `POST /api/v2/estimates/{name}/review` | ✅ | |
| `POST /api/v2/estimates/{name}/confirm` | ✅ | |
| `confirm` вимагає status=Approved AND reviewed_by | ✅ | `app/services/estimate_service.py:170-174` |
| Жоден AI-кошторис не потрапляє в ERPNext без `reviewed_by` | ✅ | gate enforced |
| no-code сценарії: `/api/v2/scenarios/*` | ✅ | `app/routes/scenarios.py` |
| AI-деградація UI: `GET /api/v2/ai/degradation` | ✅ | `app/routes/ai.py` |
| `estimate_service.py` викликає `enqueue_ai_estimate` (RQ-fallback) | 🔴 | `estimate_service.py:108` — функція `enqueue_ai_estimate` НЕ ІСНУЄ в `tasks/ai_estimate.py` |

**Вердикт A4: DoD частково.** ⚠️ Human gate enforced ✅. Але RQ-fallback шлях (рядок 108) крашитиме при timeout.

---

## 6. БЛОК E — Фази S1–S4: Offline-sync + Flutter

### S1 — Sync backend

| Перевірка | Результат | Доказ |
|---|---|---|
| `name = client UUID` (ідемпотентність) | ✅ | `visit.json: autoname: field:client_uuid` |
| Серверна монотонна `riad_version` | ✅ | `sync_service.py:247,362` — `new_version = server_version + 1` |
| Union-merge адитивних колекцій за `_uuid` | ✅ | `sync_service.py:311-340` |
| Скалярний конфлікт → Sync Conflict (обидві версії збережені) | ✅ | `sync_service.py:284-307` |
| Tombstones | ✅ | `sync_service.py:186-205` |
| Pull = дельта за серверним watermark | ✅ | `sync_service.py:91` — watermark декодується до timestamp |
| Годинник пристрою НЕ бере участі | ✅ | `sync_service.py` — немає client timestamp порівнянь |
| Watermark "opaque" (конфлікт: decode тривіальний) | ⚪ | `sync_service.py:70-78` — `base64(json(ts))` |
| `POST /api/v2/sync/pull`, `/push`, `/resolve` | ✅ | `app/routes/sync.py` |

**Вердикт S1: DoD виконано.** ✅ (minor: watermark декодується)

---

### S2 — Flutter offline core (Drift)

| Перевірка | Результат | Доказ |
|---|---|---|
| Drift схема: 12 таблиць | ✅ | `riad_mobile/lib/data/local/database.dart` |
| SyncClient: pullDelta/push_pending/createTombstone | ✅ | `riad_mobile/lib/data/sync/sync_client.dart` |
| Offline-first: локальне зберігання | ✅ | Drift SQLite |
| Конфлікт: `SyncConflictCard` | ✅ | `riad_mobile/lib/ui/sync/sync_conflict_card.dart` |
| Принцип 7 (ручний вибір, без тихого перезапису) | ✅ | `sync_conflict_card.dart:27-69` — кнопки "Сервер"/"Клієнт", POST /resolve |

**Вердикт S2: DoD виконано.** ✅

---

### S3 — Польові флоу Flutter + Drive upload

| Перевірка | Результат | Доказ |
|---|---|---|
| `POST /api/v2/media/upload` | ✅ | `app/routes/media.py` |
| Google Drive через service account | ✅ | `app/services/drive_service.py` |
| `ai_allowed=0` хардкодовано | ✅ | `media.py` — `ai_allowed: false` |
| Flutter: VisitListScreen, VisitDetailScreen | ✅ | `.dart` файли існують |
| Flutter: CameraScreen, ScanScreen, VoiceNoteScreen | ✅ | файли існують |
| `PendingMediaUpload` Drift таблиця | ✅ | `database.dart` |
| Конфлікт visit_material/visit_serials — вирішено | ✅ | S3 tech decision задокументовано в BUILD_LOG |

**Вердикт S3: DoD виконано.** ✅

---

### S4 — Next.js карта-редактор + склад

| Перевірка | Результат | Доказ |
|---|---|---|
| `riad_web/` Next.js проект | ✅ | директорія існує з package.json, tsconfig |
| `MapEditorScreen` | ✅ | `riad_web/src/app/objects/[id]/map/page.tsx` |
| `WarehouseScreen` | ✅ | `riad_web/src/app/warehouse/page.tsx` |
| Backend `/api/v2/maps/*` | ✅ | `app/routes/maps.py` |
| Backend `/api/v2/warehouse/*` | ✅ | `app/routes/warehouse.py` |
| Backend `/api/v2/serial/record` | ✅ | `app/routes/serial.py` |

**Вердикт S4: DoD виконано** (синтаксично, без runtime перевірки). ✅

---

## 7. ТАБЛИЦЯ 10 ПРИНЦИПІВ КОНСТИТУЦІЇ

| # | Принцип | Статус | Evidence (файл:рядок) |
|---|---|---|---|
| 1 | Не нова ERP: кастомні DocType тільки розширюють стандартні | ✅ | `doctype/*/` — Link-зв'язки на ERPNext DocTypes, без дублювання |
| 2 | Єдина БД: MariaDB — єдине джерело правди | ✅ | `DECISIONS.md`, `docker-compose.yml` — один MariaDB |
| 3 | ERPNext desk — НЕ для кінцевих користувачів | НЕ ПЕРЕВІРЕНО | потрібен running ERPNext з role permissions |
| 4 | AI тільки допоміжний + ручний еквівалент у тому ж UI | ⚠️ ЧАСТКОВО | gate `reviewed_by` ✅; але no-code manual estimate без AI є? Поле `origin=manual` є ✅; AI-деградація показує "Обрати сценарій" ✅ |
| 5 | Vault ізоляція в коді (не лише політика) | 🔴 ПОРУШЕНО | V1 source files відсутні; V2 lint не в CI; audit.py відсутній |
| 6 | PII-анонімізація перед зовнішнім AI + self-hosted Whisper | ⚠️ ЧАСТКОВО | Whisper self-hosted ✅; logs anonymized ✅; NER перед AI-викликом ВІДСУТНІЙ — тільки мінімізація-first (Site Brief) |
| 7 | Sync без тихого перезапису: ручний вибір при конфлікті | ✅ | `sync_service.py:284` (Sync Conflict зберігає обидві версії); `sync_conflict_card.dart:199-212` (кнопки вибору) |
| 8 | No-code адмінки для сценаріїв і чек-листів | ✅ | `/api/v2/scenarios/*`, `app/routes/scenarios.py`; Frappe Desk forms для Checklist Template |
| 9 | Один Frappe-сайт + custom app (не нова ERPNext) | ✅ | архітектура збережена; security_erp namespace |
| 10 | Нічні бекапи + моніторинг | 🔴 ПОРУШЕНО | BUILD_LOG R5: бекап-пайплайн зламаний з 18.06 (5 днів); Redis AOF вимкнено; binlog вимкнено |

---

## 8. КРИТИЧНІ БЛОКЕРИ ПРОДАКШН

| # | Знахідка | Ризик | Деталі |
|---|---|---|---|
| 🔴 1 | **Vault крипто-модулі відсутні** | Runtime crash при кожному VaultEntry.save(); шифрування/дешифрування не працює | `vault/_key.py`, `_crypto.py`, `_hooks.py`, `api.py`, `audit.py`, `mfa.py` відсутні |
| 🔴 2 | **R3 reuse-detection не реалізовано** | Refresh token можна використати повторно; атакуючий не відключається; немає per-device revoke | `jwt.py:37` — no jti; `auth.py:/refresh` — no blacklist |
| 🔴 3 | **estimate.json не має R6 полів та permlevel** | Монтажник бачить ціни (порушення H7); estimate lifecycle (origin/reviewed_by) не працює через Frappe REST | `estimate.json` — 27 полів, жодного з R6 |
| 🔴 4 | **`enqueue_ai_estimate` не існує** | При timeout sync-AI кошторис не ставиться в RQ чергу; silently falls; estimate залишається Draft без причини | `estimate_service.py:108` |
| 🔴 5 | **V2 Vault isolation lint не в CI** | Vault-імпорт з AI-шляху пройде CI без попередження; регресія можлива | `ci.yml` — відсутній крок `V2 Vault isolation lint` |

---

## 9. ЩО НЕ ПЕРЕВІРЕНО (потрібен running-сервіс/БД/контейнер)

| Що | Чому не перевірено |
|---|---|
| R5-FIX-1..5 (binlog, Redis AOF, backup script, cron) | Потрібен running server + cron logs |
| Реальне permlevel enforcement через Frappe REST API | Потрібен running ERPNext з двома юзерами різних ролей |
| Frappe scheduler hook `sync_provider_health` | Потрібен running scheduler |
| Vault Audit Log hash-chain цілісність | `audit.py` відсутній у джерелах |
| ERPNext desk role permissions (принцип 3) | Потрібен running ERPNext |
| Whisper `POST /transcribe` endpoint | Потрібен running Whisper container |
| V4 `act.html` і Desk JS buttons | Потрібен running ERPNext Frappe Desk |
| S2/S3 Flutter тести | Потрібен Flutter SDK (`flutter test`) |
| Google Drive upload реальний тест | Потрібен GOOGLE_SERVICE_ACCOUNT_JSON |
| R3 DocType `riad_device_session` `bench migrate` | Потрібен running ERPNext |

---

## 10. ВЕРДИКТИ ПО ФАЗАХ

| Фаза | Назва | Вердикт |
|---|---|---|
| R1 | Per-user делегування | ✅ DoD виконано |
| R2 | Реальні Frappe-ролі | ⚠️ Частково (Ukrainian roles відсутні) |
| R3 | Refresh-ротація + reuse-detection | 🔴 DoD провалено (жодна функція не реалізована) |
| R4 | Rate limit / Gateway discipline | 🔴 DoD провалено (обидва варіанти) |
| R5 | Durability audit | НЕ ПЕРЕВІРЕНО |
| R6 | Дата-модель: злиття | ⚠️ Частково (visit ✅; estimate 🔴) |
| R7 | Дата-модель: батч DocTypes | ✅ DoD виконано |
| R8 | Vault-неймспейс DocTypes | ✅ DoD виконано (схема) |
| V1 | Vault crypto core | 🔴 DoD провалено (source files відсутні) |
| V2 | Vault ізоляція CI + hash-chain | ⚠️ Частково (lint script ✅; CI відсутній; audit.py відсутній) |
| V3 | MFA step-up + Vault API | 🔴 DoD провалено (mfa.py/api.py відсутні) |
| V4 | Access Transfer Act | ✅ DoD виконано (act.py + FastAPI routes) |
| A1 | AI провайдер + Circuit Breaker | ✅ DoD виконано |
| A2 | AI Request Log + sync health | ✅ DoD виконано |
| A3 | Whisper + RQ tasks | ⚠️ Частково (asyncio ✅; is_active vs is_enabled 🔴; transcription_status 🟡) |
| A4 | Estimate lifecycle | ⚠️ Частково (human gate ✅; enqueue_ai_estimate 🔴) |
| S1 | Sync backend | ✅ DoD виконано |
| S2 | Flutter offline core | ✅ DoD виконано |
| S3 | Польові флоу Flutter | ✅ DoD виконано |
| S4 | Next.js map + warehouse | ✅ DoD виконано |

---

## 11. ТОП-5 НАЙРИЗИКОВАНІШИХ МІСЦЬ

### 1. 🔴 Vault крипто-модулі втрачені (V1/V2/V3)
**Ризик**: Катастрофічний. Весь Vault-трек (V1–V3) реалізований тільки в `.pyc` файлах — вихідний код не існує. При будь-якому `VaultEntry.save()` система крашить (`ModuleNotFoundError`). Vault AES-256-GCM шифрування неможливе. Vault audit hash-chain неможливий.

**Дія**: Відновити з `.pyc` через декомпілятор або переписати.

### 2. 🔴 R3 reuse-detection відсутній
**Ризик**: Безпековий. Атакуючий, що перехопив refresh token, може використовувати його необмежено. Немає per-device revoke. Немає список активних сесій. BUILD_LOG стверджує, що R3 реалізовано — але це не відповідає дійсності.

**Дія**: Реалізувати jti+did в JWT, blacklist в Redis, reuse-detection у `/refresh`, GET/DELETE /sessions.

### 3. 🔴 Estimate permlevel відсутній в JSON (R6 частково не виконано)
**Ризик**: Бізнес-критичний. Монтажник через FastAPI REST може читати `purchase_rate`, `profit`, `margin` — поля не приховані через Frappe permlevel. Рішення B1 (Frappe permission engine = авторитетний) не діє для Estimate.

**Дія**: Додати R6 поля в estimate.json і estimate_item.json, встановити permlevel=1, виконати `bench migrate`.

### 4. 🔴 `enqueue_ai_estimate` не існує (A4 частково не виконано)
**Ризик**: Runtime crash при estimate.build timeout. AI кошторис не ставиться в чергу → estimate назавжди залишається Draft → estimate lifecycle зламаний.

**Дія**: Перейменувати `run_ai_estimate` → додати `enqueue_ai_estimate(estimate_name, site_brief, variant)`, або виправити виклик в estimate_service.py.

### 5. 🔴 R3 BUILD_LOG vs реальний код (довіра до BUILD_LOG)
**Ризик**: Системний. Мінімум R3, R4 rate-limiting, R6 estimate-частина заявлені як ✅ DONE в BUILD_LOG, але не реалізовані в коді. Це означає, що BUILD_LOG — не достатній доказ завершення. Інші "✅ DONE" пункти потребують незалежної перевірки перед продакшн.

**Дія**: Ввести mandatory перевірку "code exists → tests green → CI passes" як єдиний DoD, не самозвіт BUILD_LOG.
