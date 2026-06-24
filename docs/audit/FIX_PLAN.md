# RIAD Security ERP — План виправлення після аудиту
**Дата:** 2026-06-23  
**Базується на:** full_audit_R1_S4.md  
**Принцип:** verification-before-completion (код > BUILD_LOG)

---

## ЗАГАЛЬНА ОЦІНКА

| Категорія | Кількість | Блокує продакшн? |
|---|---|---|
| 🔴 CRITICAL (runtime crash / security breach) | 5 | ТАК |
| 🟡 HIGH (неправильна поведінка) | 5 | Частково |
| ⚪ LOW (design debt) | 2 | НІ |
| ❓ НЕ ПЕРЕВІРЕНО (потрібен running server) | 10 | Невідомо |

**Ключовий висновок:** BUILD_LOG є ненадійним джерелом правди.  
R3, R4 rate-limiting, R6 estimate — позначені як ✅ DONE, але код відсутній.  
Обов'язковий DoD: `code exists → tests green → CI passes`, не самозвіт.

---

## РІШЕННЯ: ПЕРЕПИСАТИ ЧИ ВИПРАВИТИ?

### Vault (V1/V2/V3) → **ПЕРЕПИСАТИ З НУЛЯ** ✍️
**Чому:** Вихідні файли `_key.py`, `_crypto.py`, `_hooks.py`, `api.py`, `audit.py`, `mfa.py` відсутні.  
Є лише `.pyc` в `__pycache__`. Декомпіляція `.pyc` дає нечитабельний код,  
без коментарів, без типів — технічний борг гірший за відсутність коду.  
Дизайн повністю задокументований у DECISIONS.md + ТЗ. Переписати → чистіше.

### R3 Auth → **Реалізувати** (схема DocType є)
### R6 estimate fields → **Додати поля** (JSON + bench migrate)
### A3/A4 AI → **Точкові правки** (rename function + fix field name)
### R4/R2 → **Підключити існуюче** (rate_limit.py є, просто не підключено)
### Gateway discipline → **Поетапний рефакторинг** (не блокує продакшн зараз)

---

## КАРТА ЗАЛЕЖНОСТЕЙ І ПРІОРИТЕТІВ

```
FIX-1: R3 Auth (jti+blacklist+sessions)     ← SECURITY CRITICAL, незалежний
FIX-2: Vault rewrite (V1+V2+V3)             ← CRASH CRITICAL, незалежний
FIX-3: R6 estimate fields+permlevel         ← BUSINESS CRITICAL, незалежний
FIX-4: A3/A4 AI task fixes                  ← залежить від Vault (FIX-2) для runtime
FIX-5: R4 rate limit + R2 roles + CI        ← незалежний, HIGH priority
FIX-6: Gateway discipline refactor          ← рефакторинг, найнижчий пріоритет
FIX-7: R5 durability verification           ← ✅ DONE (2026-06-24)
```

---

## FIX-1: R3 — Refresh-ротація + Reuse-detection + Device Sessions
**Серйозність:** 🔴 CRITICAL (Security breach)  
**Що зламано:** Refresh token можна використати необмежено; немає per-device revoke  
**Файли:** `app/auth/jwt.py`, `app/routes/auth.py`

### Що треба реалізувати:
1. `create_refresh_token(user_id, device_id)` → додати `jti` (UUID) + `did` в payload
2. `/refresh` endpoint:
   - Decode RT → отримати `jti` + `did`
   - Перевірити `rt:bl:{jti}` в Redis → якщо є → `REFRESH_TOKEN_REUSED` + revoke всі сесії юзера
   - Blacklist старий `jti`: `redis.setex(f"rt:bl:{jti}", RT_TTL, "revoked")`
   - Видати новий RT з новим `jti`
3. `GET /api/v2/auth/sessions` → список `RIAD Device Session` для поточного юзера
4. `DELETE /api/v2/auth/sessions/{device_id}` → revoke конкретного пристрою
5. При login → зберегти `RIAD Device Session` з `jti`, `did`, `user_agent`, `ip`

### Кінцевий стан:
- `jwt.py`: `create_refresh_token(user_id, device_id) → str` з `jti+did`
- `auth.py /refresh`: blacklist + reuse-detection
- `auth.py GET/DELETE /sessions`: управління сесіями
- DocType `RIAD Device Session` використовується (вже є схема)

---

## FIX-2: Vault — Переписати крипто-ядро (V1 + V2 + V3)
**Серйозність:** 🔴 CRITICAL (System crash при кожному VaultEntry.save())  
**Що зламано:** Source files відсутні → ImportError → весь Vault не працює

### Структура файлів для написання:
```
security_erp/vault/
├── __init__.py          (порожній або re-export)
├── _key.py              (завантаження master key з env/file, НЕ з БД)
├── _crypto.py           (AES-256-GCM encrypt/decrypt пополе)
├── _hooks.py            (encrypt_doc_fields, decrypt_doc_fields для DocType hooks)
├── api.py               (Frappe whitelisted методи: vault_get, vault_set, vault_list)
├── audit.py             (append-only hash-chain: prev_hash → sha256 → record_hash)
└── mfa.py               (TOTP verify step-up: pyotp.TOTP(secret).verify(code))
```

### Ключові контракти:
- `_key.py`: `get_master_key() → bytes` — з `VAULT_MASTER_KEY` env або файлу; NO БД; NO AI контекст
- `_crypto.py`: `encrypt(plaintext: str, key: bytes) → str` (base64 encoded "nonce:ciphertext:tag")
- `_crypto.py`: `decrypt(ciphertext: str, key: bytes) → str`
- `_hooks.py`: `encrypt_doc_fields(doc, method=None)` — before_save hook
- `_hooks.py`: `decrypt_doc_fields(doc, method=None)` — after_fetch hook  
- `audit.py`: `log_action(action, doc_name, user, meta) → None` (append-only, hash-chain)
- `mfa.py`: `verify_totp(user, code) → bool` (pyotp, raises VaultMFAError if invalid)

### V2 — CI isolation lint:
Додати в `.github/workflows/ci.yml`:
```yaml
- name: V2 Vault isolation lint
  run: python tests/vault_isolation/check_vault_isolation.py
```
(скрипт `check_vault_isolation.py` вже існує, тільки CI-крок відсутній)

### Ізоляція (Конституція принцип 5):
- AI Services (`app/services/`, `tasks/`) НЕ МАЮТЬ імпортувати з `security_erp.vault.*`
- Тест: `grep -r "from security_erp.vault" app/ tasks/` → має бути порожньо

---

## FIX-3: R6 — Estimate DocType: поля + permlevel
**Серйозність:** 🔴 CRITICAL (Монтажник бачить ціни → порушення бізнес-логіки)  
**Що зламано:** `estimate.json` + `estimate_item.json` не мають R6-полів і permlevel=1

### Поля для `estimate.json` (додати):
```json
{"fieldname": "origin", "fieldtype": "Select", "options": "manual\nai\nimported"},
{"fieldname": "variant", "fieldtype": "Data"},
{"fieldname": "reviewed_by", "fieldtype": "Link", "options": "User", "permlevel": 1},
{"fieldname": "reviewed_at", "fieldtype": "Datetime", "permlevel": 1},
{"fieldname": "total_cost", "fieldtype": "Currency", "permlevel": 1},
{"fieldname": "total_margin", "fieldtype": "Currency", "permlevel": 1}
```

### Поля для `estimate_item.json` (додати):
```json
{"fieldname": "purchase_rate", "fieldtype": "Currency", "permlevel": 1},
{"fieldname": "profit", "fieldtype": "Currency", "permlevel": 1},
{"fieldname": "margin_pct", "fieldtype": "Percent", "permlevel": 1},
{"fieldname": "line_source", "fieldtype": "Select", "options": "manual\nai\ncatalog"}
```

### Після змін: `bench migrate` (щоб DDL застосувалось до MariaDB)

### Перевірка permlevel:
- Frappe Engineer role → `GET /api/resource/AI Estimate/{name}` → `purchase_rate` відсутнє у відповіді
- Frappe Director role → те саме → `purchase_rate` присутнє

---

## FIX-4: A3/A4 — AI Task fixes
**Серйозність:** 🔴 CRITICAL (Runtime crash при estimate timeout)  
**Файли:** `app/services/estimate_service.py`, `tasks/ai_estimate.py`, `tasks/transcribe.py`

### Правки:

**A. `estimate_service.py:108`**
```python
# БУЛО (не існує):
security_erp.tasks.ai_estimate.enqueue_ai_estimate(...)
# СТАЛО:
from security_erp.tasks.ai_estimate import enqueue_ai_estimate
enqueue_ai_estimate(estimate_name, site_brief, variant)
```
АБО: в `tasks/ai_estimate.py` додати обгортку:
```python
def enqueue_ai_estimate(estimate_name: str, site_brief: str, variant: str = "standard"):
    frappe.enqueue("security_erp.tasks.ai_estimate.run_ai_estimate",
                   estimate_name=estimate_name, site_brief=site_brief, variant=variant)
```

**B. `tasks/ai_estimate.py:37`**
```python
# БУЛО (поле не існує):
frappe.get_all("AI Provider", filters={"is_active": 1})
# СТАЛО:
frappe.get_all("AI Provider", filters={"is_enabled": 1})
```

**C. `doctype/media_asset/media_asset.json`**  
Додати поле `transcription_status`:
```json
{"fieldname": "transcription_status", "fieldtype": "Select",
 "options": "pending\nprocessing\ndone\nfailed", "default": "pending"}
```

---

## FIX-5: R4 Rate limiting + R2 Ukrainian roles + CI
**Серйозність:** 🟡 HIGH  
**Файли:** `app/routes/auth.py`, `.github/workflows/ci.yml`

### R4 — Per-endpoint rate limit (модуль вже існує):
```python
# В auth.py /login:
from app.core.rate_limit import check_rate_limit
check_rate_limit(f"login:{client_ip}", limit=5, window=900)

# В auth.py /refresh:
check_rate_limit(f"refresh:{current_user.id}", limit=30, window=900)
```

### R2 — Ukrainian role mapping (перевірити і виправити якщо треба):
```python
def _map_frappe_role_from_names(role_names: list[str]) -> Role:
    mapping = {
        # English
        "Engineer": Role.engineer, "Accountant": Role.accountant,
        "Warehouse Manager": Role.warehouse, "Director": Role.director,
        # Ukrainian (можливо відсутні незважаючи на BUILD_LOG)
        "Технік": Role.engineer, "Бухгалтер": Role.accountant,
        "Склад": Role.warehouse, "Директор": Role.director,
    }
```

### CI — додати кроки перевірки:
```yaml
- name: Verify R3 jti in refresh token
  run: python -c "from app.auth.jwt import create_refresh_token; import json,base64; t=create_refresh_token('u1','d1'); p=json.loads(base64.b64decode(t.split('.')[1]+'==')); assert 'jti' in p and 'did' in p"

- name: Verify auth rate limit connected  
  run: grep -n "check_rate_limit" app/routes/auth.py | grep -E "login|refresh"
```

---

## FIX-6: Gateway Discipline (поетапний рефакторинг)
**Серйозність:** 🟡 HIGH (але не блокує продакшн негайно)  
**Поточна проблема:** `visits.py`, `vault.py`, `ai_admin.py`, `ai.py`, `maps.py`, `media.py`, `warehouse.py`, `act.py` — прямі виклики `frappe_get/post/put` з routes/

### Стратегія (3 ітерації):
1. **Ітерація 1:** Написати сервіс-шар для найбільш критичних routes (visits, warehouse)
2. **Ітерація 2:** Мігрувати решту routes (maps, media, ai_admin)
3. **Ітерація 3:** CI-лінт що routes/ не викликають frappe_get напряму

### CI lint (після міграції):
```python
# tests/lint/check_gateway_discipline.py
import ast, pathlib, sys
for f in pathlib.Path("app/routes").rglob("*.py"):
    tree = ast.parse(f.read_text())
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            if hasattr(node.func, 'id') and node.func.id in ('frappe_get','frappe_post','frappe_put','frappe_delete'):
                print(f"VIOLATION: {f}:{node.lineno}")
                sys.exit(1)
```

---

## FIX-7: R5 Durability Verification
**Статус:** ✅ DONE (2026-06-24)
**Серйозність:** ✅ ВИПРАВЛЕНО  
**Що було зламано:** binlog вимкнено, Redis AOF вимкнено, backup pipeline зламаний з 18.06
**Що зроблено:** binlog ON/ROW/expire7, AOF yes/everysec, backup.sh + restore.sh + deploy.sh виправлені, CI gate додано, bench migrate виконано

### Чек-лист (виконати на сервері):
```bash
# 1. binlog
mysql -e "SHOW VARIABLES LIKE 'log_bin';"  # має бути ON

# 2. Redis AOF
redis-cli CONFIG GET appendonly  # має бути yes

# 3. Backup script
ls -la scripts/backup-mariadb.sh
bash scripts/backup-mariadb.sh && echo "OK"

# 4. Cron
crontab -l | grep backup

# 5. Остання успішна резервна копія
ls -lth /backups/ | head -5
```

---

## ПОРЯДОК ВИКОНАННЯ (рекомендований)

```
Тиждень 1:
  День 1-2:  FIX-1 (R3 Auth)        ← Security не терпить
  День 2-4:  FIX-2 (Vault rewrite)  ← Система не стартує без Vault
  День 4-5:  FIX-3 (R6 estimate)    ← Перед наступним bench migrate

Тиждень 2:
  День 1:    FIX-4 (AI fixes)       ← 30 хвилин роботи, 3 баги
  День 2:    FIX-5 (Rate+Roles+CI)  ← Підключити існуюче
  День 7:    FIX-7 (Durability)     ← ✅ DONE

Тиждень 3+:
  Поетапно:  FIX-6 (Gateway)        ← Рефакторинг без дедлайну
```

---

## НОВІ ПРАВИЛА DoD (після цього аудиту)

Кожна фаза відтепер ЗОБОВ'ЯЗАНА мати:
1. **Code evidence** — конкретний файл:рядок, що підтверджує реалізацію
2. **CI green** — всі кроки ci.yml проходять
3. **Independent verification** — окрема сесія перевірки (не той самий чат що писав код)
4. **BUILD_LOG = narrative, not DoD** — BUILD_LOG описує що робили, але DoD = перевірений код
