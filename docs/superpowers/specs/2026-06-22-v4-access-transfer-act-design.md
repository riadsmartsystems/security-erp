# V4 — Access Transfer Act + Vault UI: Design Spec

**Date:** 2026-06-22  
**Status:** Approved  
**Implements:** `docs/07_build_playbook.md` §V4  
**Gate:** C2 (key-escrow) — реальні Vault-секрети в production лише після H1

---

## 1. Контекст і обмеження

V1–V3 реалізовані: AES-256-GCM крипто, CI isolation lint, hash-chain аудит, MFA step-up (TOTP),
Frappe whitelist API, FastAPI тонкий проксі `/api/v2/vault/`.

DocType `Access Transfer Act` (+ child `Access Transfer Act Entry`) створені в R8.
V4 додає **бізнес-логіку поверх схеми**: генерацію, доставку TTL-посиланням, клієнтське
підтвердження.

**Незмінні обмеження (конституція):**
- Дешифровані дані — тільки в пам'яті під час HTTP response, **ніколи at-rest**
- Жодних секретів у Drive, логах, БД у plaintext
- Токен + OTP — тільки у Redis (TTL 24h), ніколи у MariaDB
- Vault Audit Log — кожна операція (generate / view / acknowledge / revoke)

---

## 2. Схема даних

### 2.1 Нові поля Access Transfer Act

| Поле | Тип Frappe | Призначення |
|---|---|---|
| `delivery_token` | Data, read_only | SHA-256 хеш токена (сам токен — лише у Redis) |
| `delivery_token_expires_at` | Datetime, read_only | Час закінчення TTL |
| `otp_hint` | Data, read_only | Підказка: "6-значний код" (не сам OTP) |
| `link_burned` | Check, default 0, read_only | 1 після acknowledge або revoke |

Наявні поля `generated_by`, `generated_at`, `delivered_at`, `client_acknowledged`,
`acknowledged_at`, `audit_ref` — без змін.

### 2.2 Redis key-schema

```
act:tok:{token_hex}  → JSON {act_name, expires_at}           TTL = 86400 s (24h)
act:otp:{token_hex}  → sha256(otp_plaintext).hexdigest()     TTL = 86400 s (24h)
```

- `token_hex` = `secrets.token_hex(32)` (64 hex-символи)
- `otp` = `f"{secrets.randbelow(1_000_000):06d}"` (рівномірний розподіл)
- Обидва ключі видаляються разом при acknowledge або revoke
- MariaDB зберігає лише `sha256(token_hex)` у полі `delivery_token` (для перевірки revoke при повторній генерації)

---

## 3. Frappe-модуль `security_erp/vault/act.py`

### 3.1 `generate(act_name, vault_session_token)`

```
@frappe.whitelist()
```

1. `_check_mfa_session(vault_session_token, frappe.session.user)`
2. `frappe.has_permission("Access Transfer Act", ptype="write", doc=act_name, throw=True)`
3. Завантажити акт → перевірити `included_entries` не порожній
4. Якщо `delivery_token` вже є і `link_burned == 0` → **revoke** старого:
   - Знайти старий `token_hex` через `act:tok:*` (або зберігати encrypted у Redis окремо — ні, краще шукати через `act_name` в JSON)
   - Альтернатива: зберігати `act:act_to_tok:{act_name}` → `token_hex` (додатковий Redis-ключ для зворотнього lookup)
   - Видалити `act:tok:{old_token}` і `act:otp:{old_token}` з Redis
   - Записати аудит `action="act_revoke"`
5. Згенерувати `token = secrets.token_hex(32)`, `otp = f"{secrets.randbelow(1_000_000):06d}"`
6. Записати Redis:
   - `act:tok:{token}` → `json.dumps({act_name, expires_at})`, TTL=86400
   - `act:otp:{token}` → `sha256(otp)`, TTL=86400
   - `act:act_to_tok:{act_name}` → `token`, TTL=86400 (для revoke lookup)
7. Оновити акт: `delivery_token=sha256(token)`, `delivery_token_expires_at`, `generated_by=frappe.session.user`, `generated_at=now`, `link_burned=0`
8. `append_audit_log("act_generate", vault_entry="", field_touched=act_name, ...)`
9. Повернути `{ok: True, token, otp, link: f"/api/v2/act/public/{token}", expires_at}`

**OTP ніколи не зберігається plaintext** у жодному місці.

### 3.2 `serve(token_hex, otp_code)` — без MFA-gate, публічний

```
@frappe.whitelist(allow_guest=True)
```

1. Прочитати `act:tok:{token_hex}` → `{act_name, expires_at}`; якщо немає → ValidationError "Посилання недійсне або закінчилося"
2. Прочитати `act:otp:{token_hex}` → `otp_hash`
3. `sha256(otp_code) != otp_hash` → PermissionError "Невірний код"
4. `frappe.get_doc("Access Transfer Act", act_name)` → зібрати `vault_entry` зі `included_entries`
5. `key = _load_key()`
6. In-memory decrypt: для кожного Vault Entry → `{field: _decrypt_field(doc.get(field), key) for field in ENC_FIELDS if doc.get(field)}`
7. `append_audit_log("act_view", ...)` — user = акту `generated_by`, ip з request
8. Повернути `{ok: True, act_name, entries: [{vault_entry, label, fields: {login, password, ...}}]}`

**Токен НЕ спалюється після `serve`** — клієнт може переглянути кілька разів до acknowledge.

### 3.3 `acknowledge(token_hex, otp_code)`

```
@frappe.whitelist(allow_guest=True)
```

1. Валідація токена + OTP — аналогічно `serve`
2. Оновити акт: `client_acknowledged=1`, `acknowledged_at=now`, `link_burned=1`
3. Видалити з Redis: `act:tok:`, `act:otp:`, `act:act_to_tok:{act_name}`
4. `append_audit_log("act_acknowledge", ...)`
5. Повернути `{ok: True, acknowledged_at}`

### 3.4 `get_meta(token_hex)` — публічний, без OTP

```
@frappe.whitelist(allow_guest=True)
```

Повертає метадані акту (назва пасспорту, клієнт, дата, кількість записів) без OTP і без decrypt.
Дозволяє клієнту перевірити посилання до введення коду.

---

## 4. FastAPI ендпоінти

### 4.1 Публічний роутер `/api/v2/act/public/` (без JWT)

```python
GET  /api/v2/act/public/{token}              → act.get_meta(token)
POST /api/v2/act/public/{token}/view         body: {otp}  → act.serve(token, otp)
POST /api/v2/act/public/{token}/acknowledge  body: {otp}  → act.acknowledge(token, otp)
```

- Нова Pydantic схема `ActOtpRequest(otp: str)`
- Без `Depends(get_current_user)` — аутентифікація через Redis-токен + OTP всередині Frappe
- Новий хелпер `frappe_guest_post(path, data)` у `app/core/database.py` — POST без `Cookie` header (Frappe Guest whitelist не потребує SID)

### 4.2 Захищений endpoint (JWT required)

```python
POST /api/v2/vault/act/generate   body: {act_name, vault_session_token}
```

- `Depends(get_current_user)` — JWT + Frappe SID (R1)
- Проксі до `security_erp.vault.act.generate`
- Повертає `{token, otp, link}` — менеджер копіює і передає клієнту

---

## 5. ERPNext Desk UI (`access_transfer_act.js`)

### 5.1 Кнопка "Генерувати акт"

- Видима якщо `included_entries` не порожній і є права `write`
- Якщо `delivery_token` вже є і `link_burned == 0` → показати confirm dialog:
  > "Попередній акт анульовано. Клієнт більше не зможе відкрити старе посилання. Продовжити?"
- MFA TOTP dialog → `POST /api/v2/vault/mfa/verify`
- `POST /api/v2/vault/act/generate`
- Result dialog:
  ```
  ┌─────────────────────────────────────────────┐
  │ Акт згенеровано                             │
  │                                             │
  │ Посилання:                                  │
  │ https://riad.fun/api/v2/act/public/{token}  │
  │ [Копіювати]                                 │
  │                                             │
  │ OTP-код для клієнта: 4 8 2 9 1 7            │
  │ ⚠ Передайте окремим каналом (SMS/Viber)     │
  │ ⚠ Після закриття цього вікна код недоступний│
  │                                             │
  │ Дійсно до: 2026-06-23 14:32                 │
  │                              [Закрити]      │
  └─────────────────────────────────────────────┘
  ```
- Reload форми після закриття (оновити `generated_at`, `delivery_token_expires_at`)

### 5.2 Кнопка "Переглянути акт" (desk preview під MFA)

- Тільки для System Manager / Sales Manager
- MFA step-up → `POST /api/v2/vault/entry/decrypt` для кожного Vault Entry в `included_entries`
- Dialog з masked значеннями (`•••••••`) + reveal-кнопка по кліку
- Записує `action="view"` в аудит (через існуючий `decrypt_vault_entry`)

### 5.3 List view колонки

Додати до стандартного list view: `generated_at`, `client_acknowledged`, `link_burned`.

---

## 6. Аудит-дії (нові action types для `append_audit_log`)

| action | Коли |
|---|---|
| `act_generate` | Генерація нового акту (з токеном) |
| `act_revoke` | Анулювання попереднього акту при регенерації |
| `act_view` | Клієнт переглянув дешифровані дані |
| `act_acknowledge` | Клієнт підтвердив отримання |

---

## 7. Безпекові гарантії

| Вимога | Реалізація |
|---|---|
| No at-rest secrets | Decrypt тільки in-memory у Frappe HTTP response |
| Ніколи у Drive | Немає жодного виклику до Drive API |
| One-time TTL | Redis TTL=86400s; спалення при acknowledge або revoke |
| OTP brute-force | 10^6 комбінацій; не додаємо rate-limit у V4 (Redis TTL достатньо для 24h вікна; можна додати в H2) |
| Публічний endpoint без JWT | Аутентифікація через опаковий token (64 hex) + OTP hash — не гірше JWT для one-time use |
| Vault isolation | `act.py` всередині `security_erp/vault/` — CI linter V2 захищає |

---

## 8. DoD (Definition of Done)

1. `act.generate` під MFA повертає `token + otp`, записує аудит `act_generate`
2. `act.serve` з правильним token + otp повертає дешифровані поля in-memory, записує `act_view`
3. `act.acknowledge` спалює Redis-ключі, оновлює `client_acknowledged=1`, записує `act_acknowledge`
4. Регенерація: повторний `act.generate` анулює попередній token (Redis delete) + записує `act_revoke`
5. Публічний endpoint доступний без JWT: `GET /api/v2/act/public/{token}` → метадані
6. ERPNext desk: кнопка "Генерувати акт" → MFA → dialog з link + OTP; confirm при регенерації
7. Vault isolation linter (V2) — зелений після додавання `act.py`
8. BUILD_LOG оновлено; C2/H1 gate відмічено

---

## 9. Gate — C2 (key-escrow)

**Жодних реальних Vault-секретів у production до завершення H1.**  
`act.generate` і `act.serve` технічно готові після V4, але реальні паролі клієнтів
вносяться у Vault Entry лише після:
- H1: key-escrow процедури (майстер-ключ під контролем двох осіб)
- DR-runbook + restore-drill з Vault
