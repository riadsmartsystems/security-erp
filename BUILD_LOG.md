# BUILD_LOG — RIAD Security ERP

## Фаза R (стабілізація безпеки)

---

### R1 — Per-user Frappe delegation (КРИТИЧНА, безпекова) ✅ DONE

**Дата:** 2026-06-22  
**Статус:** DoD виконано

#### Технічне рішення

Обраний механізм: **кешована Frappe SID per user у Redis** (не per-user API keys).

Обґрунтування:
- `frappe_login()` вже повертає SID — нульова Frappe-конфіг
- Не зберігаємо паролі ніде (SID — ефемерний делегований credential)
- При expiry → 401 FRAPPE_SESSION_EXPIRED → клієнт re-логіниться → новий SID
- API-ключі вимагають ручного admin-створення per-user в Frappe (проблема масштабу)

Redis key schema: `frappe:sid:{user_id}`, TTL = `FRAPPE_SESSION_TTL` (default 21600 = 6h).

#### Змінені файли

| Файл | Що змінено |
|------|------------|
| `app/core/config.py` | Додано `frappe_session_ttl`, прибрано `frappe_username/frappe_password` |
| `app/core/database.py` | Повністю видалено `_get_sid()`, `_sid` glob, Admin-login. `frappe_get/post/put/delete` тепер вимагають `sid=` |
| `app/auth/dependencies.py` | `CurrentUser` отримав `frappe_sid: str`; `get_current_user` читає `frappe:sid:{user_id}` з Redis; 401 FRAPPE_SESSION_EXPIRED якщо відсутній |
| `app/routes/auth.py` | `/login`: зберігає SID у Redis + fetchує реальні ролі з Frappe (замість `_default_role()`); `/logout`: видаляє SID; `/refresh`: читає SID з Redis; всі маршрути використовують `current_user.frappe_sid` |
| `app/routes/doctypes.py` | `get_settings(sid)` тепер приймає SID; всі `frappe_*` з `sid=current_user.frappe_sid`; виправлено 4 баги `json=payload` → `data=payload` |
| `app/routes/visits.py` | Всі `frappe_*` з `sid=current_user.frappe_sid` |
| `app/routes/proxy.py` | Замінено фіксований `Authorization: token` на `cookies={"sid": current_user.frappe_sid}`; імпортовано `FRAPPE_HOST` з database.py |
| `app/services/ai_service.py` | `generate_estimate(ta, sid)` та `_catalog(ta, sid)` приймають SID |
| `app/services/scenario_service.py` | Всі методи отримали `sid` параметр |

#### DoD перевірка

1. ✅ **AST-перевірка**: усі `frappe_*` виклики мають `sid=` — нуль винятків  
2. ✅ **Redis isolation**: Administrator SID ≠ joker@riad.fun SID (різні ключі і значення)  
3. ✅ **Frappe identity**: `frappe.auth.get_logged_user` повертає правильного юзера для кожного SID  
4. ✅ **Row-level perms**: Administrator бачить 3 юзерів, joker@riad.fun (без ролей) — лише себе  
5. ✅ **Permlevel enforcement**: joker@riad.fun отримує `PermissionError` на Note (permlevel=1 для Desk User); Administrator читає без проблем  
6. ✅ **Version log**: Note (name=6fkrll1hqv), створена через FastAPI → Administrator SID → Frappe записав `owner=Administrator, modified_by=Administrator` (не системний сервіс)  
7. ✅ **Синтаксис**: `py_compile` всіх змінених файлів — OK  
8. ✅ **Build**: Docker image `security-api-test` будується без помилок; сервіс стартує  

#### Примітки

- `proxy.py` (v1 legacy): тепер використовує `current_user.frappe_sid` замість фіксованого API key. Config-поля `frappe_api_key/frappe_api_secret` збережено але не використовуються в бізнес-CRUD.
- Frappe `session_expiry` (site config) має бути >= `frappe_session_ttl`; за замовчуванням Frappe = 6h = 21600s ✓
- Реальний permlevel-1 custom field у Security ERP doctypes ще не створено — всі поточні custom fields мають permlevel=0. Тест проведено на стандартному `Note` DocType з permlevel=1 для `Desk User`. У подальших сесіях при додаванні чутливих полів (salary, vault-посилання) використовувати permlevel≥1.

---

### R2 — Реальні Frappe-ролі замість хардкоду ✅ DONE

**Дата:** 2026-06-22  
**Статус:** DoD виконано

#### Технічне рішення

Зберігаємо **raw Frappe roles** (`frappe_roles: list[str]`) у JWT access token поряд з маппованою FastAPI-роллю (`role`).

- `_extract_frappe_roles(user_data)` — витягує чистий список імен ролей з Frappe User.roles
- `_map_frappe_role_from_names(role_names)` — маппінг Frappe → FastAPI Role enum (ранній фільтр, не джерело правди). Додані: `Технік`→`engineer`, `Бухгалтер`→`accountant`, `Склад`→`warehouse`, `Директор`→`director`
- `CurrentUser.frappe_roles: list` — raw ролі з JWT, доступні всередині обробника
- `/me` endpoint повертає обидва поля: `role` (FastAPI RBAC) та `frappe_roles` (справжні Frappe ролі)
- `/login` та `/refresh` re-fetchують Frappe User.roles при кожному виклику → зміна ролі в Frappe відображається при наступному login/refresh

#### Змінені файли

| Файл | Що змінено |
|------|------------|
| `app/auth/jwt.py` | `create_access_token` отримав параметр `frappe_roles: Optional[list] = None`; зберігається у payload |
| `app/auth/dependencies.py` | `CurrentUser` отримав `frappe_roles: list`; `get_current_user` читає `frappe_roles` з JWT payload |
| `app/routes/auth.py` | `_extract_frappe_roles()` — окрема функція; login/refresh передають raw roles у JWT; `/me` повертає `frappe_roles`; маппінг розширено українськими назвами ролей |

#### DoD перевірка

1. ✅ **Новий Frappe User з роллю `Технік`** логіниться → JWT: `role: "engineer"`, `frappe_roles: ["Технік"]`
2. ✅ **`/me`** повертає `frappe_roles: ["Технік"]` — саме ця роль, без хардкоду
3. ✅ **Зміна ролі** `Технік` → `Sales Manager` у Frappe → `/refresh` → JWT: `role: "sales_manager"`, `frappe_roles: ["Sales Manager"]`
4. ✅ **Синтаксис**: `py_compile` всіх змінених файлів — OK
5. ✅ **Build**: Docker image `security-api-r2-test` збирається без помилок; сервіс стартує

#### Примітки

- FastAPI RBAC (`Role` enum + `ROLE_PERMISSIONS`) лишається раннім фільтром, **не джерелом правди** (DECISIONS.md B1)
- Frappe permission engine (permlevel, row-level User Permission) — авторитетний ензфорсер через per-user SID (R1)
- `frappe_roles` у JWT може застаріти між login/refresh, але це прийнятно — RBAC early-reject лише для очевидно неавторизованих запитів

---

---

### R3 — Refresh-ротація + reuse-detection + Device Session ✅ DONE

**Дата:** 2026-06-22  
**Статус:** DoD виконано

#### Технічне рішення

Схема токенів:
- Кожен refresh token тепер містить `jti` (UUID4, унікальний ID токена) і `did` (stable device ID — однаковий для всіх ротацій однієї сесії).
- При `/refresh`: стара `jti` вноситься в Redis blacklist (TTL = залишок терміну дії токена), видається новий refresh token з новим `jti` і тим самим `did`.
- Reuse detected: якщо `jti` вже в blacklist → видаляємо Redis-сесію пристрою + Frappe SID → 401 `RIAD-AUTH-REFRESH-REUSE`.
- Легітимний RT2 після reuse-detection теж відхиляється (сесія пристрою видалена) → SESSION_REVOKED.

Redis key schema:
```
rt:bl:{jti}                   → user_id  (TTL = remaining token lifetime)
rt:sess:{user_id}:{device_id} → JSON {jti, created, last_seen, ip_address}  (TTL = jwt_refresh_ttl)
rt:devices:{user_id}          → SET of active device_ids
```

RIAD Device Session формалізовано як Frappe DocType (`security_erp/doctype/riad_device_session/`) з полями user, device_id, created_at, last_seen_at, revoked, revoke_reason, ip_address, jti. Основне зберігання — Redis (швидкий auth-path); DocType — для майбутнього admin-аудиту в Frappe Desk.

#### Змінені файли

| Файл | Що змінено |
|------|------------|
| `app/auth/jwt.py` | `create_refresh_token` отримав `device_id` param; додано `jti` (uuid4) і `did` до payload |
| `app/routes/auth.py` | `/login`: створює Redis-сесію; `/refresh`: rotation + reuse-detection; `/logout`: опціональний RT body; нові: `GET /sessions`, `DELETE /sessions/{device_id}` |
| `app/schemas/auth.py` | Доданий `LogoutRequest` (optional refresh_token) |
| `security_erp/doctype/riad_device_session/` | Новий DocType: riad_device_session.json, .py, __init__.py |

#### DoD перевірка

1. ✅ **Reuse detection**: повторне використання RT1 після ротації → `{"code":"RIAD-AUTH-REFRESH-REUSE"}` + device session revoked
2. ✅ **RT2 блокується**: після reuse-detection RT2 (легітимний, ще не використаний) повертає `{"code":"SESSION_REVOKED"}` — обидва боки (атакуючий і власник) виходять
3. ✅ **Нормальна ротація**: `/refresh` → новий RT2 з новим `jti`, старий RT1 більше не працює
4. ✅ **Frappe SID зберігається при нормальному refresh** — SID видаляється лише при reuse або явному logout
5. ✅ **GET /sessions**: список активних сесій юзера (device_id, created, last_seen, ip_address)
6. ✅ **DELETE /sessions/{device_id}**: вибіркове відкликання без інвалідації інших сесій
7. ✅ **Синтаксис**: `py_compile` всіх змінених файлів — OK
8. ✅ **Build**: Docker image `security-api-r3-test` збирається, сервіс стартує

#### Примітки

- Backward-compat: старі refresh tokens (без `jti`/`did`) відхиляються з `TOKEN_UPGRADE_REQUIRED` — юзери мають перелогінитись після деплою.
- `LogoutRequest.refresh_token` опціональний — logout без RT body продовжує працювати (видаляє Frappe SID, але не blacklistить RT).
- DocType `RIAD Device Session` в Frappe поки не синхронізований (`bench migrate` потрібен) — Redis auth-path від цього не залежить.
- Frappe SID видаляється при reuse для ВСІХ сесій user (спільний ключ `frappe:sid:{user_id}`). Після R5 (multi-device Frappe SID) це треба переглянути.

---

---

### R4 — Rate limiting для auth endpoints ✅ DONE

**Дата:** 2026-06-22  
**Статус:** DoD виконано

#### Технічне рішення

Sliding window rate limit через Redis sorted set (ZREMRANGEBYSCORE + ZADD + ZCARD + EXPIRE в pipeline).

- `/login`: max 5 спроб на IP за 900s (15 хв). Ключ: `rl:login:{ip}`
- `/refresh`: max 30 спроб на user_id за 900s (15 хв). Ключ: `rl:refresh:{user_id}`
- При перевищенні → 429 з `Retry-After` header (розраховується за найстарішим записом у вікні)
- Response body: `{"detail": {"code": "RATE_LIMIT_EXCEEDED", "message": "..."}}`
- Rate limit для `/refresh` перевіряється після отримання `user_id` з токена, але до валідації підпису/blacklist

Sliding window логіка:
1. `ZREMRANGEBYSCORE key -inf (now - window)` — видалити застарілі записи
2. `ZADD key {uuid: now}` — додати поточний запит
3. `ZCARD key` — поточна кількість у вікні
4. `EXPIRE key window` — TTL для авто-очищення ключа
5. Якщо count > max_attempts → знайти `ZRANGE key 0 0 WITHSCORES` → `Retry-After = oldest_ts + window - now`

#### Змінені файли

| Файл | Що змінено |
|------|------------|
| `app/core/rate_limit.py` | Новий файл: `check_rate_limit(redis, key, max, window)` — sliding window via sorted set |
| `app/core/config.py` | Додано: `rate_limit_login_max=5`, `rate_limit_login_window=900`, `rate_limit_refresh_max=30`, `rate_limit_refresh_window=900` |
| `app/routes/auth.py` | `/login`: rate limit по IP до `frappe_login()`; `/refresh`: rate limit по user_id після парсингу токена; import `check_rate_limit`; видалено дублікат `ip =` |

#### DoD перевірка

1. ✅ **Login rate limit**: 6 curl-запитів → запити 1-5 проходять (HTTP 500, Frappe недоступний), 6-й → HTTP 429
2. ✅ **Retry-After header**: `retry-after: 891` (≈ 15 хв залишку вікна)
3. ✅ **Response body**: `{"detail":{"code":"RATE_LIMIT_EXCEEDED","message":"Too many requests..."}}`
4. ✅ **Redis key**: `rl:login:172.24.0.1` — ZCARD=7, TTL≈889s
5. ✅ **Refresh rate limit**: 31 запит → запити 1-30 проходять, 31-й → HTTP 429
6. ✅ **Per-user_id ключ**: `rl:refresh:bulk@riad.fun` — ZCARD=31
7. ✅ **Синтаксис**: `py_compile` всіх змінених файлів — OK
8. ✅ **Build**: Docker image `security-api-r4-test` збирається без помилок

#### Примітки

- Для `/login`: rate limit перевіряється ДО виклику Frappe, тому навіть невалідні credentials рахуються у вікні (захист від enumeration)
- Для `/refresh`: якщо user_id не вдається витягти з токена (nil), rate limit пропускається — 401 надходить від валідації JWT
- `rate_limit_default` і `rate_limit_window` в config залишаються (legacy, не використовуються в auth)
- Після R5 (multi-device Frappe SID) перевірити: `/refresh` rate limit не заважає легітимним мульти-девайс сценаріям (30/15хв × N девайсів)

---

---

### R6 — Дата-модель: злиття перетинів ✅ DONE

**Дата:** 2026-06-22  
**Статус:** DoD виконано

#### Технічне рішення

Три міграції схеми кастомних DocType — розширення наявних полями з дата-моделі (docs/02_data_model.md §4.6, §4.7, §4.11) відповідно до union-підходу B1.

**1. `security_scenario_item`** — додано:
- `qty_rule (Select: fixed/per_camera/per_100m2/per_point, default: fixed)`
- `qty_factor (Float, default: 1.0)` — множник для qty_rule (крім fixed)

**2. `estimate`** — додано:
- `origin (Select: ai_primary/ai_fallback/manual, default: manual)`
- `variant (Select: budget/optimal/premium)`
- `reviewed_by (Link → User)`
- `reviewed_at (Datetime, read_only)`
- `total_cost (Currency, permlevel 1, read_only)`
- `total_margin (Currency, permlevel 1, read_only)`

`estimate` permissions оновлено: System Manager та Sales Manager отримали `permlevel=1` рядки з `read=1, write=1`; Service Manager залишається лише `permlevel=0`.

**3. `estimate_item`** — додано:
- `purchase_rate (Currency, permlevel 1)` — закупівельна ціна
- `profit (Currency, permlevel 1, read_only)` — прибуток по позиції
- `margin_pct (Percent, permlevel 1, read_only)` — відсоток маржі
- `line_source (Select: ai/scenario/manual, default: manual)` — походження позиції

`estimate_item` permissions аналогічно оновлено з permlevel 1 рядками.

**4. `visit`** — додано sync-метадані:
- `client_uuid (Data, read_only)` — UUID згенерований клієнтом (майбутнє: autoname в S1)
- `riad_version (Int, default: 0, read_only)` — серверна монотонна версія
- `riad_deleted (Check, default: 0)` — tombstone
- `riad_deleted_at (Datetime, read_only)` — час видалення

**5. `visit_material`** — ті самі 4 sync-поля

**6. `visit_photo`** — ті самі 4 sync-поля

#### Змінені файли

| Файл | Що змінено |
|------|------------|
| `doctype/security_scenario_item/security_scenario_item.json` | qty_rule, qty_factor |
| `doctype/estimate/estimate.json` | origin, variant, reviewed_by, reviewed_at, total_cost (L1), total_margin (L1); перmlevel 1 DocPerm rows |
| `doctype/estimate_item/estimate_item.json` | purchase_rate (L1), profit (L1), margin_pct (L1), line_source; permlevel 1 DocPerm rows |
| `doctype/visit/visit.json` | client_uuid, riad_version, riad_deleted, riad_deleted_at |
| `doctype/visit_material/visit_material.json` | client_uuid, riad_version, riad_deleted, riad_deleted_at |
| `doctype/visit_photo/visit_photo.json` | client_uuid, riad_version, riad_deleted, riad_deleted_at |

#### DoD перевірка

1. ✅ **security_scenario_item**: колонки `qty_rule (varchar 140, default 'fixed')` і `qty_factor (decimal 21,9, default 1.0)` — присутні в MariaDB після `bench migrate`
2. ✅ **estimate**: колонки `origin, variant, reviewed_by, reviewed_at, total_cost, total_margin` — присутні в MariaDB
3. ✅ **estimate_item**: колонки `purchase_rate, profit, margin_pct, line_source` — присутні в MariaDB
4. ✅ **permlevel реально приховує ціну** для ролі без permlevel 1:
   - `joker@riad.fun` (Service Manager): GET /api/resource/Estimate/EST-R6-TEST → `total_cost: 0.0`, `total_margin: 0.0` (DB має 8500/4200 — Frappe нулює)
   - `Administrator` (System Manager, permlevel 1): `total_cost: 8500.0`, `total_margin: 4200.0` — реальні значення
5. ✅ **visit/visit_material/visit_photo sync-поля**: `client_uuid, riad_version (int, default 0), riad_deleted (int, default 0), riad_deleted_at` — присутні в MariaDB для всіх трьох таблиць
6. ✅ **bench migrate**: `Updating DocTypes for security_erp` — 100% без помилок (окрема нерелевантна помилка фікстур `Stock Entry.project` — pre-existing конфлікт, не пов'язаний з R6)

#### Примітки

- `visit` залишається `istable: 1` (дочірня таблиця `service_ticket.visits`) — перетворення на standalone документ з `autoname: field:client_uuid` відкладено до S1 (синк-логіка). Поле `client_uuid` додано як Data field для майбутньої ідемпотентності.
- Frappe permlevel enforcement: `get_doc` через ORM повертає реальні значення (немає фільтрації на цьому рівні); фільтрація відбувається в REST API `/api/resource/` layer (Frappe нулює значення полів, для яких у ролі немає permlevel read).
- Фраза "монтажник" в умовах DoD — роль без permlevel 1 (Service Manager у наявній конфігурації). Коли буде роль `Монтажник` у Frappe, вона за замовчуванням отримає лише permlevel 0 доступ до Estimate.
- `qty_rule` значення обрані як програмні енуми (fixed/per_camera/per_100m2/per_point) замість Ukrainian labels для сумісності з майбутнім кодом обчислень.
- `origin` і `line_source` аналогічно — програмні енуми (ai_primary/ai_fallback/manual, ai/scenario/manual).

---

### R7 — Дата-модель: батч відсутніх DocType ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

Батч 13 нових DocType (12 + 1 допоміжний child для Remote Inspection). Усі мігрували в MariaDB через `bench migrate` без нових помилок (pre-existing `Stock Entry.project` — відомий конфлікт з R6, не стосується цих змін).

**Підхід до `Object Passport`:** лінкується на наявний `Security Object` (CMDB) через поле `security_object (Link → Security Object)`. Поля `customer`, `address`, `gps`, `object_type` — НЕ дублюються (залишаються на `Security Object`). Паспорт додає лише lifecycle-статус, `site_brief`, `installation_map`, `warranty_summary`, `internal_notes`.

#### Створені DocType

| DocType | Тип | Ключові особливості |
|---|---|---|
| `Site Brief` | Standalone | Неперсональний опис для AI; без PII; Link на Lead (опційно) |
| `Object Passport` | Standalone | `security_object (Link → Security Object)`; lifecycle status; без CMDB-дублів |
| `Passport Client Release` | Standalone | Трекінг генерації; `excludes_credentials` = 1 завжди |
| `Installation Map` | Standalone | `passport (Link → Object Passport)`; child: Mount Points + Cable Routes |
| `Mount Point` | Child (istable=1) | `point_uuid` (union-merge ключ); type/label/x/y/status/item/serial_no/photo |
| `Cable Route` | Child (istable=1) | `route_uuid` (union-merge ключ); from/to point UUID; JSON path |
| `Checklist Template` | Standalone | `template_items` (child Checklist Template Item); no-code адмін |
| `Checklist Template Item` | Child (istable=1) | seq/text/requires_photo/requires_serial/requires_value |
| `Checklist Instance` | Standalone | `template + passport`; sync-поля (riad_version/riad_deleted/riad_deleted_at); offline-first |
| `Checklist Instance Item` | Child (istable=1) | `item_uuid` (union-merge ключ); checked_by/photo/value/serial_no |
| `Remote Inspection` | Standalone | passport/lead/engineer; ai_report + manual_report; inspection_media (child) |
| `Remote Inspection Media` | Child (istable=1) | media (Link → Media Asset) + kind |
| `Media Asset` | Standalone | `drive_file_id`, `transcription (Long Text)`, `ai_allowed (Check, default=0)`, tombstone (`riad_deleted/riad_deleted_at`), `riad_version`, `client_uuid`; autoname=hash |

#### DoD перевірка

1. ✅ **Всі 13 таблиць мігрували чисто** — MariaDB підтвердив наявність `tabSite Brief`, `tabObject Passport`, `tabPassport Client Release`, `tabInstallation Map`, `tabMount Point`, `tabCable Route`, `tabChecklist Template`, `tabChecklist Template Item`, `tabChecklist Instance`, `tabChecklist Instance Item`, `tabRemote Inspection`, `tabRemote Inspection Media`, `tabMedia Asset`
2. ✅ **Object Passport лінкується на security_object** — колонка `security_object varchar(140) MUL` присутня; CMDB-поля (customer/address/gps) НЕ дублюються
3. ✅ **Media Asset.ai_allowed = 0 за замовчуванням** — MariaDB: `ai_allowed int(1) NOT NULL DEFAULT 0`
4. ✅ **Media Asset.transcription** — `longtext`, присутнє
5. ✅ **Media Asset.drive_file_id** — `varchar(140)`, присутнє
6. ✅ **Media Asset tombstone** — `riad_deleted int(1) NOT NULL DEFAULT 0`, `riad_deleted_at datetime(6)`
7. ✅ **Синтаксис**: `py_compile` всіх 13 .py файлів — OK
8. ✅ **bench migrate**: `Queued rebuilding of search index for erp.localhost` (завершено); єдина помилка — pre-existing `Stock Entry.project` (відома з R6, не стосується R7)

#### Примітки

- `Checklist Instance.visit` поки лінкується на `Service Ticket` (existing DocType) через поле-замінник з description. Коли буде standalone `Engineer Visit`, цей Link оновлюється.
- `Mount Point.photo (Link → Media Asset)` і `Checklist Instance Item.photo (Link → Media Asset)` — зворотні посилання на Media Asset; `Media Asset.parent_doctype/parent_name` (Dynamic Link) — зворотній зв'язок для пошуку.
- `Remote Inspection Media` — окремий child DocType (не через Dynamic Link на Media Asset) для типобезпечного child-table в Frappe.
- Tombstone-логіка в `MediaAsset.before_save()`: автоматично заповнює `riad_deleted_at` при першому встановленні `riad_deleted=1`.

---

---

### R8 — Дата-модель: Vault-неймспейс (схема, без логіки) ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

Створено 8 нових DocType (7 standalone + 1 child) для Vault-неймспейсу, AI-конфігу та Sync-конфліктів. **Крипто-логіки немає — свідомо (V1 додасть).** Всі `*_enc`-поля — `Long Text` (longtext в MariaDB), не Frappe Password.

Конфлікт назв вирішено (аудит Вісь 3, рядок 18): `warranty_letter` — гарантійний лист клієнту (залишено без змін); `Access Transfer Act` — новий DocType для акту передачі доступів Vault (інше призначення, окремий модуль).

#### Створені DocType

| DocType | Тип | Autoname | Ключові особливості |
|---|---|---|---|
| `Vault Entry` | Standalone | `VAULT-.######` | `*_enc` поля (login/password/ip/domain/ddns/serial/notes) → `Long Text, permlevel 1`; Link на Object Passport/Customer/Serial No; ізольовано від AI структурно |
| `Vault Access Enrollment` | Standalone | `VENROLL-.######` | `totp_secret_enc (Long Text, permlevel 1)`; Link → User; self-access через `if_owner` |
| `Vault Audit Log` | Standalone | `VAUDIT-.######` | Hash-chain: `seq (Int)`, `prev_hash/record_hash (Data)`, `action (Select)`; read-only для всіх, create тільки System Manager; append-only семантика |
| `Access Transfer Act` | Standalone | `ACT-.######` | Child `included_entries (Table → Access Transfer Act Entry)` — лише посилання, не дешифровані значення; Link → Vault Audit Log |
| `Access Transfer Act Entry` | Child (istable=1) | hash | `vault_entry (Link → Vault Entry)` — лише ref |
| `AI Provider` | Standalone | `field:provider_name` | `priority (Int)`, `health_status (Select)`, `is_enabled`; ключі API — НЕ тут (у secrets) |
| `AI Request Log` | Standalone | `AILOG-.######` | `anonymized_payload (Long Text)`; Link → AI Provider; **жодного Link на Vault** (структурно заборонено) |
| `Sync Conflict` | Standalone | `SCONF-.######` | `conflict_doctype/docname/conflict_field` (уникнено конфлікту з Frappe-зарезервованим `doctype`); `server_value/client_value (Long Text)`; `chosen (Select: server/client)` |

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `doctype/vault_entry/` | Новий: vault_entry.json, .py, __init__.py |
| `doctype/vault_access_enrollment/` | Новий: vault_access_enrollment.json, .py, __init__.py |
| `doctype/vault_audit_log/` | Новий: vault_audit_log.json, .py, __init__.py |
| `doctype/access_transfer_act/` | Новий: access_transfer_act.json, .py, __init__.py |
| `doctype/access_transfer_act_entry/` | Новий: access_transfer_act_entry.json, .py, __init__.py |
| `doctype/ai_provider/` | Новий: ai_provider.json, .py, __init__.py |
| `doctype/ai_request_log/` | Новий: ai_request_log.json, .py, __init__.py |
| `doctype/sync_conflict/` | Новий: sync_conflict.json, .py, __init__.py |

#### DoD перевірка

1. ✅ **Всі 8 таблиць мігрували чисто** — MariaDB підтвердив: `tabVault Entry`, `tabVault Access Enrollment`, `tabVault Audit Log`, `tabAccess Transfer Act`, `tabAccess Transfer Act Entry`, `tabAI Provider`, `tabAI Request Log`, `tabSync Conflict`
2. ✅ **`*_enc` поля = Long Text** — MariaDB: `login_enc/password_enc/ip_enc/domain_enc/ddns_enc/serial_enc/notes_enc` → `longtext` (не Frappe Password)
3. ✅ **Крипто-логіки немає** — `.py` файли містять лише базовий `Document(pass)` — жодного шифрування (свідомо, для V1)
4. ✅ **Синтаксис** — `py_compile` всіх 8 .py файлів → OK
5. ✅ **bench migrate** — `Queued rebuilding of search index for erp.localhost`; pre-existing помилка `Stock Entry.project` — відома з R6, не стосується R8
6. ✅ **Access Transfer Act ≠ warranty_letter** — окремий DocType `access_transfer_act` (акт Vault); `warranty_letter` залишено без змін (гарантійний лист клієнту — інше призначення)
7. ✅ **AI Request Log без Link на Vault** — структурна ізоляція Vault↔AI: у `ai_request_log.json` немає жодного Link на Vault Entry/Vault Audit Log

#### Примітки

- `Vault Audit Log`: `seq` — звичайний `Int (read_only)`, заповнюється сервісом Vault при insert (V1). Autoname `VAUDIT-.######` для Frappe-сумісності; `seq` — окремий монотонний лічильник поза Frappe naming.
- `AI Provider.provider_name` — унікальний, `autoname: field:provider_name` (зручний key).
- `Sync Conflict`: поле `conflict_doctype (Data)` замість `doctype` (Frappe reserved); `conflict_field` замість `field` (потенційно ambiguous).
- `Vault Access Enrollment.user` — `unique: 1` → один enrollment на користувача.

---

### V2 — Vault ізоляція (CI двошарова) + hash-chain аудит ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

**Шар 1 — Python AST-лінт (import boundary):**

Новий скрипт `tests/vault_isolation/check_vault_isolation.py` (лише stdlib `ast` + `pathlib`) сканує 7 заборонених шляхів:
- `services/security-api/` — увесь FastAPI-сервіс (окремий процес)
- `doctype/ai_provider/`, `doctype/ai_request_log/`, `doctype/estimate/`, `doctype/remote_inspection/`, `doctype/site_brief/` — AI-related DocType
- `tasks/` — RQ-воркери / планувальники

При знаходженні будь-якого `import security_erp.vault.*` або `from .vault import ...` в цих шляхах → виходить з кодом 1. CI крок `V2 Vault isolation lint` у `.github/workflows/ci.yml` червоніє.

**Шар 2 — мережева ізоляція (задокументовано в CLAUDE.md):**

Vault-функції decrypt/encrypt — in-process Frappe; `@frappe.whitelist()` закритий для RQ/воркер-контексту. `security-api` — окремий Python-процес, vault не встановлений там як пакет. Детальна таблиця ізоляції в розділі «Vault — мережева ізоляція» CLAUDE.md.

**Hash-chain аудит — `security_erp/vault/audit.py`:**

| Функція | Призначення |
|---------|-------------|
| `append_audit_log(action, *, vault_entry, field_touched, user, session_id, ip, passport)` | Записує один рядок у `Vault Audit Log` з `seq`, `prev_hash`, `record_hash` |
| `verify_audit_chain()` | Re-compute SHA-256 для кожного запису, перевіряє `prev_hash` chain |

Hash-формула: `SHA256("{seq}|{timestamp}|{action}|{vault_entry}|{user}|{field_touched}|{prev_hash}")`.
Перший запис: `prev_hash = "0" * 64` (genesis).
`SELECT ... FOR UPDATE` на останньому рядку → серіалізує seq-присвоєння під конкурентним навантаженням.

**Інтеграція audit log:**

| Де викликається | Коли | action |
|---|---|---|
| `vault/api.py:decrypt_vault_entry()` | кожен decrypt | `view` |
| `vault/api.py:encrypt_vault_field()` | кожен API re-encrypt | `update` |
| `vault_entry.py:after_insert()` | створення Vault Entry | `create` |
| `vault_entry.py:on_update()` | оновлення Vault Entry | `update` |

**Whitelist верифікатора:**

`vault/api.py:verify_vault_chain()` — `@frappe.whitelist()`, `frappe.only_for("System Manager")`.
Повертає `{"ok": True}` або `{"ok": False, "broken": [{name, seq, reason}, ...]}`.

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `security_erp/vault/audit.py` | Новий: `append_audit_log()`, `verify_audit_chain()`, `_canonical()` |
| `security_erp/vault/api.py` | Додано: audit-виклики в `decrypt_vault_entry` і `encrypt_vault_field`; новий whitelist `verify_vault_chain()` |
| `doctype/vault_entry/vault_entry.py` | Додано: `after_insert()` → `create`, `on_update()` → `update` |
| `tests/vault_isolation/check_vault_isolation.py` | Новий: AST import boundary checker (stdlib only) |
| `.github/workflows/ci.yml` | Новий крок: `V2 Vault isolation lint` |
| `CLAUDE.md` | Новий розділ: «Vault — мережева ізоляція» з таблицею та посиланням на CI |

#### DoD перевірка

1. ✅ **CI червоніє при vault-імпорті з AI-шляху**: синтетичний `from security_erp.vault._crypto import _decrypt_field` у `ai_provider.py` → exit code 1, точне повідомлення з файлом і рядком
2. ✅ **CI зеленіє на чистому коді**: `check_vault_isolation.py` → `OK: 37 files scanned across 7 restricted paths`
3. ✅ **Синтаксис усіх 92 файлів security_erp** — OK (включаючи новий `audit.py`)
4. ✅ **Hash-chain математика**: 3 симульовані записи; tamper record 1 → інший hash → chain break на record 2 detected
5. ✅ **append_audit_log**: кожен decrypt/encrypt/create/update → новий запис (after_insert + on_update + api calls)
6. ✅ **verify_audit_chain**: re-compute + prev_hash linkage; змінений запис ламає перевірку
7. ✅ **Мережева ізоляція задокументована**: таблиця в CLAUDE.md; два неможливих шляхи (security-api окремий процес; RQ→whitelist закритий)
8. ✅ **Vault Audit Log permissions**: лише `System Manager` має `create`; жодного `write`/`delete` ні для кого → append-only з боку Frappe ACL

#### Примітки

- `FOR UPDATE` у `append_audit_log` потребує InnoDB (MariaDB за замовчуванням — ✓). У тестовому середовищі без транзакцій (SQLite) — fallback до звичайного SELECT.
- Audit log записується після успішного decrypt/encrypt — якщо Frappe-операція впаде до виклику `append_audit_log`, запис не створиться. Прийнятно: аудитуємо лише завершені операції.
- `after_insert` + `on_update` у `vault_entry.py` дублюють частину інформації, яка вже є в `api.py` (encrypt_vault_field). Це свідомо: before_save encrypt і whitelist-encrypt — різні потоки, кожен має свій audit trail.
- Відносні vault-імпорти (`from .vault import ...`) сканер теж ловить — на випадок рефакторингу всередині security_erp пакету.

---

### V1 — Vault-модуль: межі пакета + крипто core ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

Новий Python-підпакет `security_erp/vault/` (фізично окрема тека) з чотирма модулями:

| Модуль | Призначення |
|--------|-------------|
| `_key.py` | Завантаження 32-байтного майстер-ключа з `VAULT_KEY_PATHS` (Docker secret `/run/secrets/vault_master_key` або файл `/etc/riad/vault.key`). Перевірка прав 0400. НЕ читає env. |
| `_crypto.py` | AES-256-GCM пополе: `_encrypt_field(plaintext, key) → str`, `_decrypt_field(stored, key) → str`. Формат: `v1:<base64url(nonce12 \|\| ciphertext+gcm_tag)>`. Унікальний nonce per-call (`os.urandom(12)`). |
| `_hooks.py` | `encrypt_doc_fields(doc)` — encrypt перед save, не-whitelist, викликається з `VaultEntry.before_save()`. Безпечно для воркер-контексту (лише encrypt). |
| `api.py` | `@frappe.whitelist()` методи: `decrypt_vault_entry(name, fields)`, `encrypt_vault_field(name, field, plaintext)`. Доступні лише з HTTP-контексту Frappe. |

`__init__.py` — публічно доступні лише `VaultKeyError` та `VAULT_KEY_PATHS`.

#### Підпис зберіганого поля

```
v1:<base64url(12b_nonce + AES-256-GCM_ciphertext_with_16b_tag)>
```

Префікс `v1:` дозволяє майбутню міграцію алгоритму без зупинки сервісу.

#### Docker secret

`docker-compose.yml`:
- Верхньорівневий блок `secrets: vault_master_key: file: ./configs/vault_master_key`
- Секрет монтується у всі Frappe-сервіси (через `x-erpnext-common` anchor) як `/run/secrets/vault_master_key`
- `configs/vault_master_key.example` — інструкція генерації (`openssl rand -hex 32 > configs/vault_master_key && chmod 0400`)
- Реальний ключ додати в `.gitignore`

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `security_erp/vault/__init__.py` | Новий: re-exports VaultKeyError, VAULT_KEY_PATHS |
| `security_erp/vault/_key.py` | Новий: key loader (file/Docker secret, 0400 check) |
| `security_erp/vault/_crypto.py` | Новий: AES-256-GCM _encrypt_field/_decrypt_field/_is_encrypted |
| `security_erp/vault/_hooks.py` | Новий: encrypt_doc_fields, ENC_FIELDS |
| `security_erp/vault/api.py` | Новий: @frappe.whitelist() decrypt_vault_entry, encrypt_vault_field |
| `doctype/vault_entry/vault_entry.py` | before_save() → encrypt_doc_fields |
| `requirements.txt` | Додано `cryptography>=42.0.0` |
| `docker-compose.yml` | secrets секція + vault_master_key mount |
| `configs/vault_master_key.example` | Новий: інструкція генерації ключа |

#### DoD перевірка

1. ✅ **Пополе-шифрування/дешифрування**: всі 7 полів `*_enc` + UTF-8 + порожнє поле — roundtrip OK
2. ✅ **Nonce-унікальність**: два encrypt одного значення → різний ciphertext; обидва decrypt коректно
3. ✅ **AEAD-цілісність**: неправильний ключ → `InvalidTag` (не тихий fail)
4. ✅ **Idempotency**: вже-зашифроване поле при повторному save не подвійно-шифрується (`v1:` guard)
5. ✅ **Ключ НЕ в env**: жодної ENV-змінної з "VAULT"+"KEY" у середовищі
6. ✅ **Ключ НЕ в БД**: завантажується лише з файлової системи (file 0400 або Docker secret)
7. ✅ **Крипто-функції фізично лише в `security_erp/vault/`**: `__file__` підтверджено
8. ✅ **Синтаксис**: `py_compile` всіх 6 файлів — OK

#### Примітки

- `api.py` свідомо імпортує `frappe` на рівні модуля — це стандарт Frappe; `_hooks.py` виокремлено без цього import для тестованості поза контейнером.
- Decrypt whitelisted-методи потребують `permlevel 1` read на `Vault Entry` (задано в R8).
- RQ-воркери отримують ключ через secret-mount (потрібно для `before_save` encrypt), але `@frappe.whitelist()` декоратор Frappe фізично закриває decrypt від не-HTTP контексту.
- Реальний ключ ще не згенеровано — потрібно зробити перед першим збереженням Vault Entry в production.
- Key-escrow гейт (C2) — перед реальними Vault-секретами в production (H1).

---

### R5 — Durability-аудит ✅ DONE

**Дата:** 2026-06-22  
**Статус:** DoD виконано — drill пройдено з перевіркою цілісності; прогалини задокументовані з конкретним планом закриття

---

#### Аудит результати

##### 1. MariaDB binlog (PITR) — ❌ ВИМКНЕНО

```
log_bin = OFF
```

`configs/mariadb.cnf` містить лише charset, collation та InnoDB-параметри — жодного `log_bin`. PITR відсутній.

**RPO без PITR:** дорівнює часу з моменту останнього справного бекапу.

**План закриття (R5-FIX-1):** додати до `configs/mariadb.cnf`:
```ini
[mysqld]
log_bin            = /var/lib/mysql/mariadb-bin
binlog_format      = ROW
expire_logs_days   = 7
max_binlog_size    = 100M
```
Перезапуск MariaDB. Після ввімкнення — mysqlbinlog-drill на точку в часі.

---

##### 2. Redis AOF persistence — ❌ ВИМКНЕНО

```
appendonly   = no
appendfsync  = everysec (не активно, бо AOF off)
save         = 3600 1 / 300 100 / 60 10000  (тільки RDB snapshot)
```

Лише RDB-снепшоти. При краші Redis між снепшотами втрачаються:
- Frappe SID per user (`frappe:sid:*`) → примусовий ре-логін усіх
- Refresh token blacklist (`rt:bl:*`) → потенційне повторне використання
- Device sessions (`rt:sess:*`, `rt:devices:*`) → втрата активних сесій
- Rate limit windows (`rl:login:*`, `rl:refresh:*`) → обнулення лічильників
- Circuit Breaker state

**Plan закриття (R5-FIX-2):** додати в docker-compose.yml для redis-сервісу:
```yaml
redis:
  image: redis:7-alpine
  restart: unless-stopped
  volumes:
    - redis_data:/data
    - ./configs/redis.conf:/usr/local/etc/redis/redis.conf:ro
  command: redis-server /usr/local/etc/redis/redis.conf
```

Файл `configs/redis.conf`:
```
appendonly yes
appendfsync everysec
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

---

##### 3. Шифрування бекапів at-rest — ❌ ВІДСУТНЄ

`scripts/backup-mariadb.sh` використовує лише `gzip` — SQL-дамп зберігається в plain-text під архівом. Жодного GPG, AES, або іншого шифрування.

**Ризик:** компрометація диска → витік усієї БД (PII клієнтів, структури об'єктів, паролі у хеші).

**План закриття (R5-FIX-3):** додати GPG-шифрування до `backup-mariadb.sh`:
```bash
# Після mysqldump | gzip:
gpg --recipient "${BACKUP_GPG_RECIPIENT}" --encrypt --output "${BACKUP_FILE}.gpg" "${BACKUP_FILE}"
rm "${BACKUP_FILE}"
```
Або `openssl enc -aes-256-cbc -pbkdf2` якщо GPG-keyring недоступний. Ключ розшифрування — у docker secret або окремому файлі з доступом 0400.

---

##### 4. Бекап-пайплайн — 🔴 ЗЛАМАНИЙ з 18 червня (5 днів!)

**Аналіз `cron.log`:**

| Дата | Помилка | Причина |
|------|---------|---------|
| 18 червня | `Access denied for user 'root'@'localhost' (using password: NO)` | `MARIADB_ROOT_PASSWORD` порожній у cron-оточенні |
| 19-22 червня | `Error response from daemon: No such container: mariadb` | Контейнер має ім'я `riadcrm-mariadb-1`, скрипт використовує `mariadb` |

**Останній справний бекап:** 2026-06-16 (3.3 MB).  
**Поточний RPO:** ~6 днів (критично!).

**План закриття (R5-FIX-4):**
1. Виправити ім'я контейнера в `backup-mariadb.sh`:
   ```bash
   CONTAINER_NAME="${MARIADB_CONTAINER:-riadcrm-mariadb-1}"
   docker exec "$CONTAINER_NAME" mysqldump ...
   ```
2. Забезпечити доступність env-змінних у cron:
   ```cron
   0 2 * * * cd /home/joker/RIAD\ CRM && set -a && . .env && set +a && bash scripts/backup-mariadb.sh daily >> backups/automated/cron.log 2>&1
   ```
3. Додати перевірку non-zero розміру файлу та сповіщення про помилку (email/webhook).

---

##### 5. Restore drill — ⚠️ ПРОЙДЕНО з виявленою прогалиною

**Вхідні дані:** `mariadb_daily_20260616_020001.sql.gz` (3.3 MB, останній справний бекап).

**Процедура drill:**
1. Запущено тимчасовий `mariadb:10.6` (`mariadb-restore-drill`, `MYSQL_ROOT_PASSWORD=drill_test_2026`)
2. Вручну створено базу: `CREATE DATABASE _73c82ec6d255ebe3 CHARACTER SET utf8mb4 ...`
3. `zcat backup.sql.gz | mysql -u root ... _73c82ec6d255ebe3` → Exit code: 0
4. Перевірка цілісності:

```
total_tables: 725
security_erp_doctypes: 25
users: joker@riad.fun (enabled)
tabSingles[System Settings]: коректно
```

**Виявлена прогалина:** Дамп створюється без `--databases` прапора → не містить `CREATE DATABASE` та `USE` директив. Відновлення потребує **ручного** кроку створення БД перед імпортом. Без документованої процедури в умовах інциденту — ризик помилки.

**Plan закриття (R5-FIX-5):** Додати `--databases` до `mysqldump` в `backup-mariadb.sh`:
```bash
mysqldump ... --databases _73c82ec6d255ebe3 | gzip > "$BACKUP_FILE"
```
Або задокументувати процедуру відновлення в `docs/DR_runbook.md`:
```bash
# Крок 1: Знайти ім'я БД з дампу
zcat backup.sql.gz | head -5  # Database: _73c82ec6d255ebe3
# Крок 2: Створити БД
docker exec mariadb mysql -uroot -p -e "CREATE DATABASE \`_73c82ec6d255ebe3\` ..."
# Крок 3: Відновити
zcat backup.sql.gz | docker exec -i mariadb mysql -uroot -p _73c82ec6d255ebe3
```

---

#### Зведена таблиця прогалин

| # | Прогалина | Ризик | Пріоритет | План |
|---|-----------|-------|-----------|------|
| R5-FIX-1 | binlog вимкнено (немає PITR) | RPO = час між справними бекапами | HIGH | Увімкнути в mariadb.cnf |
| R5-FIX-2 | Redis AOF вимкнено | Втрата auth-стану при рестарті | HIGH | redis.conf + AOF |
| R5-FIX-3 | Бекапи не зашифровані | Витік PII при компрометації диска | HIGH | GPG/openssl в backup script |
| R5-FIX-4 | Бекап-пайплайн зламаний 5 днів | RPO = 6 днів зараз (критично!) | **CRITICAL** | Виправити ім'я контейнера + cron env |
| R5-FIX-5 | Restore потребує ручного кроку | Помилка в умовах інциденту | MEDIUM | --databases або DR runbook |

**Примітка щодо staging:** окремого staging-середовища немає — drill проводився у тимчасовому Docker-контейнері (адекватна заміна для цього рівня зрілості проєкту).

#### DoD перевірка

1. ✅ **Drill «бекап→відновлення» пройдено:** дамп від 16.06 відновлено, 725 таблиць, 25 Security ERP DocType, дані цілі
2. ✅ **MariaDB binlog:** перевірено (`log_bin=OFF`), прогалина задокументована (R5-FIX-1) з конкретним конфіг-патчем
3. ✅ **Redis AOF:** перевірено (`appendonly=no`), прогалина задокументована (R5-FIX-2) з конкретним redis.conf
4. ✅ **Шифрування бекапів:** перевірено (відсутнє), прогалина задокументована (R5-FIX-3) з конкретним патчем скрипту
5. ✅ **Бекап-пайплайн:** знайдена критична зламана пайплайн (R5-FIX-4), задокументована з двоступеневим фіксом
6. ✅ **Процедура відновлення:** виявлена прогалина (R5-FIX-5), задокументована

**Примітка:** Реалізація R5-FIX-1..5 — наступна сесія R6.

---

### V3 — MFA step-up + Vault read/write API ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

**Схема MFA step-up сесії (Redis):**

| Ключ | Значення | TTL |
|------|----------|-----|
| `riad_vault_mfa:{session_token}` | user_id (рядок) | 300 s (5 хв) |

`session_token` = `secrets.token_hex(32)` (64 hex-символи, непередбачуваний).
Зберігається у Frappe Redis (via `frappe.cache().set_value(..., expires_in_sec=300)`).

**Нові Frappe-модулі:**

| Модуль | Метод | Призначення |
|--------|-------|-------------|
| `vault/mfa.py` | `enroll_totp()` | @whitelist: генерує TOTP-секрет, шифрує у Vault Access Enrollment, повертає `provisioning_uri` |
| `vault/mfa.py` | `verify_step_up(code)` | @whitelist: верифікує TOTP, створює MFA-сесію у Redis, повертає `vault_session_token` (+ audit mfa_fail при помилці) |
| `vault/mfa.py` | `_check_mfa_session(token, user)` | internal: перевіряє Redis-сесію, кидає PermissionError якщо відсутня/не та |

**Оновлені Frappe-методи:**

| Метод | Зміна |
|-------|-------|
| `vault/api.py:decrypt_vault_entry` | додано `vault_session_token` — перший крок: `_check_mfa_session()` |
| `vault/api.py:encrypt_vault_field` | додано `vault_session_token` — MFA-gate для key-rotation API |
| `vault/api.py:upsert_vault_entry` | новий @whitelist: create/update Vault Entry з шифруванням *_enc полів; MFA-gate |

**FastAPI тонкий проксі (`/api/v2/vault/`):**

| Endpoint | → Frappe метод |
|----------|---------------|
| `POST /api/v2/vault/mfa/enroll` | `vault.mfa.enroll_totp` |
| `POST /api/v2/vault/mfa/verify` | `vault.mfa.verify_step_up` |
| `POST /api/v2/vault/entry/decrypt` | `vault.api.decrypt_vault_entry` |
| `POST /api/v2/vault/entry/upsert` | `vault.api.upsert_vault_entry` |
| `GET /api/v2/vault/audit/verify` | `vault.api.verify_vault_chain` |

FastAPI використовує `frappe_post(path, data={...}, sid=current_user.frappe_sid)` — тобто делегована сесія R1. Decrypted secrets ніколи не зберігаються у FastAPI-процесі довше часу одного HTTP response.

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `security_erp/vault/mfa.py` | Новий: enroll_totp, verify_step_up, _check_mfa_session |
| `security_erp/vault/api.py` | Оновлено: MFA-gate у decrypt/encrypt_vault_field; новий upsert_vault_entry |
| `security_erp/requirements.txt` | Додано: `pyotp>=2.9.0` |
| `services/security-api/app/schemas/vault.py` | Новий: Pydantic схеми MfaVerifyRequest, VaultDecryptRequest, VaultUpsertRequest |
| `services/security-api/app/routes/vault.py` | Новий: тонкий проксі /api/v2/vault/* |
| `services/security-api/app/core/config.py` | Додано: `vault_mfa_ttl = 300` |
| `services/security-api/app/main.py` | Додано: `vault_router` |

#### DoD перевірка

1. ✅ **Дешифрування вимагає свіжої MFA-сесії**: `_check_mfa_session()` — перша перевірка у `decrypt_vault_entry()`; без `vault_session_token` → PermissionError ще до читання БД
2. ✅ **FastAPI не кешує дешифровані секрети**: маршрути vault.py лише проксіюють запит/відповідь; decrypted dict повертається з Frappe і одразу іде клієнту — FastAPI не зберігає і не логує значення
3. ✅ **Кожен read/write — у Vault Audit Log**: `decrypt_vault_entry` → `append_audit_log("view")`; `upsert_vault_entry` → VaultEntry.after_insert/on_update hooks → `append_audit_log("create"/"update")`; `mfa_fail` → `append_audit_log("mfa_fail")`
4. ✅ **Vault isolation linter (V2)**: `check_vault_isolation.py` — `OK: 39 files scanned across 7 restricted paths` (vault/mfa.py та vault/api.py — всередині vault/, не в restricted paths)
5. ✅ **Синтаксис**: `py_compile` усіх 7 змінених файлів — OK

#### Примітки

- `frappe.cache().set_value(key, val, expires_in_sec=300)` — Frappe v15 RedisWrapper, site-prefixed key, підтримує TTL через Redis SET EX.
- `enroll_totp()` може викликатись повторно для ротації TOTP-секрету — перезаписує `totp_secret_enc` у наявному enrollment.
- `upsert_vault_entry` не викликає `append_audit_log` вручну — DocType hooks (after_insert/on_update) вже пишуть у аудит; подвоєння свідомо уникнуто.
- `encrypt_vault_field` (key-rotation API) тепер також потребує MFA — симетрично з decrypt.
- pyotp `valid_window=1` дозволяє ±30s drift годинника між клієнтом і сервером (стандарт TOTP RFC 6238).
- FastAPI `vault_mfa_ttl=300` у config.py — для документування; фактичне TTL задається в Frappe `vault/mfa.py:_MFA_TTL`.
- Перед першим `enroll_totp()` для користувача System Manager повинен створити `Vault Access Enrollment` запис у Frappe Desk.

---

### V4 — Access Transfer Act + Vault UI ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

Схема доставки: `act.generate` (MFA-gate) → Redis `act:tok:{token}` + `act:otp:{token}` (TTL=86400s) → менеджер надсилає link + OTP клієнту окремим каналом → клієнт відкриває `act.html` → вводить OTP → `act.serve` розшифровує in-memory → клієнт натискає "Підтверджую" → `act.acknowledge` спалює всі Redis-ключі.

| Компонент | Деталі |
|---|---|
| `security_erp/vault/act.py` | 4 @whitelist методи: generate/get_meta/serve/acknowledge |
| Redis keys | `act:tok:`, `act:otp:`, `act:act_to_tok:` — TTL=86400s |
| MariaDB | Лише `sha256(token)` у `delivery_token` — non-reversible |
| FastAPI | `/api/v2/act/public/{token}` (без JWT) + `/api/v2/vault/act/generate` (JWT) |
| Публічна сторінка | `act.html` — vanilla JS, reveal-кнопки, acknowledge |
| Desk UI | `access_transfer_act.js` — кнопки "Генерувати акт" + "Переглянути акт" під MFA |

#### Revoke-on-regenerate edge case
При `delivery_token` ≠ '' і `link_burned == 0` → lookup `act:act_to_tok:{act_name}` у Redis:
- Є: delete old keys + audit `act_revoke`
- Немає (TTL вийшов): silent skip (акт вже протух)

#### DoD перевірка

1. ✅ `vault_audit_log.json` — нові action: `act_revoke`, `act_view`, `act_acknowledge`; bench migrate — OK
2. ✅ `access_transfer_act.json` — поля `delivery_token`, `delivery_token_expires_at`, `otp_hint`, `link_burned`; bench migrate — OK
3. ✅ `act.generate` під MFA → token + otp + audit `act_generate`
4. ✅ `act.serve` з правильним token + otp → розшифровані поля in-memory + audit `act_view`
5. ✅ `act.acknowledge` → `link_burned=1` + Redis keys deleted + audit `act_acknowledge`
6. ✅ Регенерація: revoke старого token + confirm dialog у desk
7. ✅ Публічний endpoint `GET /api/v2/act/public/{token}` — без JWT
8. ✅ `act.html` — metadata → OTP → reveal → acknowledge
9. ✅ Desk buttons — "Генерувати акт" (MFA + dialog з OTP) + "Переглянути акт" (MFA + masked)
10. ✅ Vault isolation linter V2 — зелений (`act.py` в `vault/`, не в restricted paths)
11. ✅ `tests/vault/test_act_pure.py` — 10 тестів пройдено

#### ВАЖЛИВО — Гейт C2
🔴 Реальні Vault-секрети в production — ЛИШЕ після H1 (key-escrow процедура).
V4 технічно готовий. `act.generate` і `act.serve` працюють. Але наповнення
Vault Entry реальними паролями клієнтів — заморожено до:
- H1: key-escrow (майстер-ключ під контролем двох осіб)
- DR-runbook + restore-drill з Vault

---

### A1 — Провайдер-агностичний AI-адаптерний шар + Circuit Breaker + failover ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

**Абстрактний адаптер (`security_erp/ai/adapters/base.py`):**

| Компонент | Призначення |
|---|---|
| `AbstractAIAdapter` | ABC: `name()`, `complete(task, payload, params)`, `health_check()` |
| `AIResult` | dataclass: status, content, tokens, latency_ms, raw_meta, provider |
| `timed_call()` | async wrapper, автоматично засікає latency_ms |
| Task-константи | `TASK_PROJECT_BUILDER`, `TASK_INSPECTION_REPORT` |

**Реальні адаптери:**

| Адаптер | Файл | Ключ API | Примітки |
|---|---|---|---|
| `GeminiAdapter` | `adapters/gemini.py` | `GEMINI_API_KEY` env | gemini-2.0-flash, good UKR text support |
| `StubAdapter` | `adapters/stub.py` | N/A | Завжди повертає "ok" з stub-відповіддю |

Ключі API — ЛИШЕ з `os.environ`, ніколи з БД або frappe.conf.

**Circuit Breaker (`security_erp/ai/circuit_breaker.py`, Redis-based):**

| Параметр | Значення |
|---|---|
| Key schema | `cb:provider:{name}` |
| Fields | `state`, `failures`, `opened_at`, `last_change` |
| failure_threshold | 5 послідовних помилок → state: open |
| open_timeout | 60s → state: half_open (пробний виклик) |
| Atomic transitions | Lua-скрипт (single EVAL) |

Стани: `closed` → `open` (5 fails) → `half_open` (60s elapsed) → `closed` (success) / `open` (failure).

**Оркестратор failover (`security_erp/ai/orchestrator.py`):**

- Завантажує провайдерів за порядком (injectable list)
- Для кожного: `should_skip()` (CB check) → `timed_call(complete())` → success/failure
- Успіх → `record_success` → повертає `{status, content, origin}`
- Помилка/таймаут → `record_failure` → наступний провайдер
- Всі вичерпано → `{status: "manual", reason: "all_providers_open"}`
- Таймаут: 30s per provider

**API endpoint (`services/security-api/app/routes/ai.py`):**

| Endpoint | Призначення |
|---|---|
| `GET /api/v2/ai/health` | Стан CB для всіх активних провайдерів. Без JWT. |

Response: `{"providers": [{"name": "gemini", "state": "closed", "failures": 0}, ...]}`

**CI AI↔Vault isolation lint:**

Новий скрипт `tests/ai_isolation/check_ai_isolation.py` — AST-сканер (stdlib only).
Шляхи що скануються: `erpnext/security_erp/security_erp/ai/`, `services/security-api/`.
Заборонені імпорти: `security_erp.vault.*`, `from .vault import ...`.
CI крок: `A1 AI-Vault isolation lint` у `.github/workflows/ci.yml`.

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `security_erp/ai/__init__.py` | Новий: package init |
| `security_erp/ai/adapters/__init__.py` | Новий: package init |
| `security_erp/ai/adapters/base.py` | Новий: AbstractAIAdapter, AIResult, timed_call, task constants |
| `security_erp/ai/adapters/gemini.py` | Новий: GeminiAdapter (httpx, GEMINI_API_KEY env) |
| `security_erp/ai/adapters/stub.py` | Новий: StubAdapter (always ok/degraded) |
| `security_erp/ai/circuit_breaker.py` | Новий: CircuitBreaker (Redis Lua, async), CBState, CB_FAILURE_THRESHOLD=5, CB_OPEN_TIMEOUT=60 |
| `security_erp/ai/orchestrator.py` | Новий: AIOrchestrator (failover loop, 30s timeout) |
| `services/security-api/app/routes/ai.py` | Новий: GET /api/v2/ai/health (no JWT) |
| `services/security-api/app/main.py` | Оновлено: `ai_router` added |
| `tests/ai/test_a1_circuit_breaker.py` | Новий: 6 async unittest tests |
| `tests/ai_isolation/check_ai_isolation.py` | Новий: AST import boundary checker |
| `.github/workflows/ci.yml` | Новий крок: A1 AI-Vault isolation lint |

#### DoD перевірка

1. ✅ **pytest 6 тестів** — всі pass:
   - `test_primary_fails_5_times_cb_opens_failover_to_secondary` — 4 pre-loaded + 1 from orchestrator → CB open → secondary used
   - `test_secondary_also_fails_failover_to_tertiary` — both primary+secondary open → tertiary succeeds
   - `test_secondary_not_called_after_cb_open` — counter proves secondary.complete() NOT called when CB open
   - `test_all_open_returns_manual` — all 3 open → `{status: "manual"}`
   - `test_cb_half_open_success_closes` — half_open + success → closed, failures=0
   - `test_cb_half_open_failure_reopens` — half_open + failure → open again
2. ✅ **GET /api/v2/ai/health** — повертає стан CB для кожного провайдера
3. ✅ **AI↔Vault isolation lint** — `OK: 34 files scanned across 2 restricted paths — no vault imports`
4. ✅ **Синтаксис** — `py_compile` всіх 12 файлів — OK
5. ✅ **Ключі API** — `GEMINI_API_KEY` лише з `os.environ`, жодного хардкоду в коді/тестах/логах

#### Примітки

- `CircuitBreaker` — async (redis.asyncio), Lua-скрипт для atomic state transitions
- `timed_call()` — замість декоратора, зручніше для orchestrator (явний виклик)
- Gemini adapter використовує httpx (вже у requirements), не google-generativeai SDK — менше залежностей
- Stub adapter — для тестування failover без реального API; health="degraded" за замовчуванням
- `should_skip()` — probe + timeout check в одному виклику; half_open → один пробний виклик дозволений
- AI Provider DocType (R8) — джерело провайдерів для UI; orchestrator наразі використовує injectable list
- `sync_provider_health()` — background sync CB→Frappe DocType відкладено до A2 (потрібен scheduler hook)

---

### A2 — AI Request Log + sync_provider_health + AI Execute endpoint ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

**AI Request Log (сервіс-шар):**

Після кожного `orchestrator.execute()` логуємо в `AI Request Log` DocType через Frappe REST POST `/api/resource/AI Request Log` з делегованим SID (R1).

| Поле | Значення |
|------|----------|
| `anonymized_payload` | `{task, payload_keys (sorted), text_lengths}` — жодних raw значень |
| `provider` | Link → AI Provider (назва провайдера, що відповів) |
| `latency_ms` | Час виконання запиту |
| `tokens` | Кількість токенів у відповіді |
| `status` | `ok` / `error` / `manual` |
| `error_message` | Обрізане до 500 символів повідомлення про помилку |

`_anonymize_payload(task, payload)` — повертає лише тип задачі, ключі payload (відсортовані) та довжини текстових значень. Raw текст, API ключі та інші секрети ніколи не потрапляють в лог.

**sync_provider_health (Redis → Frappe):**

| CB state (Redis) | AI Provider.health (Frappe) |
|---|---|
| `closed` | `healthy` |
| `half_open` | `degraded` |
| `open` | `down` |

Джерело правди — Redis (CB state). Frappe `AI Provider.health_status` — кеш для UI.
Оновлюється лише при зміні стану (PUT `/api/resource/AI Provider/{name}`).

**AI Execute endpoint:**

| Endpoint | Призначення |
|---|---|
| `POST /api/v2/ai/execute` | JWT required. Pydantic DTO: `AIExecuteRequest(task, payload, params)`. Orchestrator failover + AI Request Log write. |
| `GET /api/v2/ai/providers` | Без JWT. `[{name, health, priority}]` для `is_enabled=1`. Health із Redis CB, не з Frappe. |

**Pydantic DTO:**

```python
class AIExecuteRequest(BaseModel):
    task: str          # 1-100 chars
    payload: dict      # task-specific data
    params: dict | None # optional model/temperature overrides

class AIExecuteResponse(BaseModel):
    status: str        # ok / error / manual
    content: str       # AI response text
    tokens: int
    latency_ms: float
    origin: str        # provider name that answered
    raw_meta: dict     # model info, usage metadata
```

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `services/security-api/app/schemas/ai.py` | Новий: AIExecuteRequest, AIExecuteResponse, AIProviderInfo |
| `services/security-api/app/services/ai_orchestrator_service.py` | Новий: _anonymize_payload, write_ai_request_log, sync_provider_health |
| `services/security-api/app/routes/ai.py` | Оновлено: POST /execute, GET /providers, оновлений GET /health |
| `tests/ai/test_a2_ai_service.py` | Новий: 11 unit-тестів (mock Frappe, mock Redis) |
| `.github/workflows/ci.yml` | Оновлено: py_compile нових файлів + A2 test step |

#### DoD перевірка

1. ✅ **POST /api/v2/ai/execute** з `task="project_builder"` → orchestrator → AIResult з origin
2. ✅ **AI Request Log** створюється після кожного execute (`anonymized_payload` містить task type, не raw текст)
3. ✅ **sync_provider_health()** оновлює `AI Provider.health` з CB state (`closed`→`healthy`, `open`→`down`)
4. ✅ **GET /api/v2/ai/providers** повертає `[{name, health, priority}]` для `is_enabled=1`
5. ✅ **11 тестів проходять** (mock Frappe, mock Redis, mock adapters)
6. ✅ **API ключі** не з'являються в коді, тестах або логах
7. ✅ **AI↔Vault isolation lint** — `OK: 39 files scanned`
8. ✅ **Синтаксис**: `py_compile` усіх змінених файлів — OK

#### Примітки

- `ai_orchestrator_service.py` працює в FastAPI-процесі (security-api), а orchestrator + adapters — з `security_erp` пакету. Обидва доступні в одному Docker-образі.
- `_build_orchestrator()` виконує lazy-import для уникнення циклічних залежностей та для сумісності з тестовим mocking.
- `write_ai_request_log()` — best-effort: помилка запису логу не ламає execute endpoint.
- `_anonymize_payload()` зберігає лише ключі та довжини текстів — жодних raw payload значень у Frappe.
- `GET /api/v2/ai/providers` використовує Redis CB як джерело health, а Frappe — лише для списку enabled провайдерів та priority.

---

### A3 — Whisper self-hosted + RQ-задачі ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

**Whisper self-hosted контейнер (`services/whisper/`):**

| Компонент | Деталі |
|---|---|
| `main.py` | FastAPI: `POST /transcribe` (multipart audio → JSON), `GET /health` |
| Модель | faster-whisper medium (CPU, int8), конфігурується через ENV |
| Concurrency | `asyncio.Lock` — один запит за раз (M4) |
| Dockerfile | python:3.12-slim + ffmpeg, uvicorn 1 worker |
| Ліміти | `deploy.resources.limits`: 4GB RAM, 2 CPU |
| Healthcheck | `curl -sf http://localhost:8000/health`, start_period=180s |

**RQ-задача `transcribe_media` (`security_erp/tasks/transcribe.py`):**

| Крок | Деталі |
|---|---|
| Тригер | `after_insert` hook на Media Asset (якщо media_type містить "audio"/"voice") |
| Завантаження | GET audio з `drive_file_id` (URL) |
| Транскрипція | POST multipart → Whisper `/transcribe` |
| Запис | `Media Asset.transcription = text`, `transcription_status = "done"` |
| Деградація | `transcription_status ∈ {pending, done, error, manual}` для UI (A4) |
| Whisper down | status="pending" (audio збережено, можна повторити або ввести вручну) |

**RQ-задача `ai_estimate_build` (`security_erp/tasks/ai_estimate.py`):**

| Крок | Деталі |
|---|---|
| Тригер | `enqueue_ai_estimate(estimate_name, site_brief, variant)` |
| Оркестрація | Sync-обгортка `_run_orchestrator_sync()` — послідовний failover через провайдерів |
| Запис | AI Request Log (анонімізований payload, як у A2) |
| Estimate | `origin = ai_primary/ai_fallback/manual` залежно від результату |
| Ai Result | JSON content → `Estimate.ai_result` |

**Docker Compose:**

| Сервіс | Мережа | Залежність | Ліміти |
|---|---|---|---|
| `whisper` | erpnet (default) | — | mem=4g, cpus=2.0 |

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `services/whisper/main.py` | Новий: FastAPI /transcribe + /health, concurrency=1 |
| `services/whisper/Dockerfile` | Новий: python:3.12-slim + ffmpeg + faster-whisper |
| `services/whisper/requirements.txt` | Новий: fastapi, uvicorn, faster-whisper, python-multipart |
| `security_erp/tasks/transcribe.py` | Новий: transcribe_media RQ task + on_media_asset_insert hook |
| `security_erp/tasks/ai_estimate.py` | Новий: ai_estimate_build RQ task + _run_orchestrator_sync |
| `security_erp/hooks.py` | Оновлено: doc_events["Media Asset"] after_insert → enqueue transcribe |
| `docker-compose.yml` | Оновлено: whisper сервіс (build, limits, healthcheck) |
| `tests/a3/test_a3_tasks.py` | Новий: 10 unit-тестів (mock Whisper, mock orchestrator) |
| `tests/a3/__init__.py` | Новий: package init |
| `tests/ai_isolation/check_ai_isolation.py` | Оновлено: SCAN_PATHS += tasks, whisper |
| `.github/workflows/ci.yml` | Оновлено: A3 test step + py_compile нових файлів |

#### DoD перевірка

1. ✅ **Whisper-контейнер**: `POST /transcribe` → `{text, language, duration}`; `GET /health` → `{status, model, device}`
2. ✅ **RQ-задача transcribe_media**: audio → Whisper → `Media Asset.transcription` + `transcription_status`
3. ✅ **RQ-задача ai_estimate_build**: `_run_orchestrator_sync()` → AI Request Log + `Estimate.origin`
4. ✅ **concurrency=1** на Whisper (asyncio.Lock), CPU/mem ліміти в docker-compose (4g/2cpu)
5. ✅ **10 тестів проходять** (mock Whisper endpoint, mock orchestrator, mock Frappe)
6. ✅ **AI↔Vault isolation lint** — зелений (`OK: 46 files scanned across 4 restricted paths`)
7. ✅ **Vault isolation lint** — зелений (`OK: 36 files scanned across 7 restricted paths`)
8. ✅ **Синтаксис**: `py_compile` всіх змінених файлів — OK

#### Примітки

- `transcribe_status` поле на Media Asset — нове, не в DocType JSON (R7). Додати як Custom Field або через `bench migrate` при наступній сесії. `_set_status()` має try/except graceful degradation.
- `_run_orchestrator_sync()` — спрощена sync-обгортка без Circuit Breaker (Redis sync client недоступний в RQ-контексті). CB працює в синхронному FastAPI-шляху (A2). Для RQ-контексту — послідовний failover без CB.
- Whisper `start_period=180s` — модель medium потребує ~2-3 хвилини на завантаження при першому старті.
- `enqueue_after_insert` не використовується (не Frappe-хук) — натомість `doc_events["Media Asset"]["after_insert"]`.
- `on_media_asset_insert` фільтрує за `media_type` — тільки audio/voice автоматично ставляться в чергу.

---

### A4 — Estimate lifecycle + no-code адмінки + AI-деградація UI ✅ DONE

**Дата:** 2026-06-22
**Статус:** DoD виконано

#### Технічне рішення

**1. Estimate Lifecycle (3 endpoints):**

| Endpoint | Метод | Контракт |
|---|---|---|
| `POST /api/v2/estimates/build` | JWT | Pydantic DTO `{site_brief_name, variant}`. Створює Estimate (status=Draft, origin=manual). Якщо orchestrator <5s → sync; якщо ≥5s → RQ `enqueue_ai_estimate()`. Записує AI Request Log. |
| `POST /api/v2/estimates/{name}/review` | JWT | Pydantic DTO `{decision: approved\|rejected}`. Встановлює reviewed_by, reviewed_at. Валідація: origin≠manual AND ai_result≠empty. |
| `POST /api/v2/estimates/{name}/confirm` | JWT | Жорстка межа: status=Approved AND reviewed_by присутній. Викликає `Estimate.create_quotation()` через gateway. Повертає `{quotation_name}`. |

**2. Media Transcription (2 endpoints):**

| Endpoint | Метод | Контракт |
|---|---|---|
| `POST /api/v2/media/{name}/transcribe` | JWT | RQ enqueue → `transcribe_media` (A3). Повертає `{status: "queued"}`. |
| `POST /api/v2/media/{name}/transcription` | JWT | Pydantic DTO `{text}`. Ручний ввід транскрипції (деградація). Записує text + transcription_status="manual". |

**3. No-code Адмінки:**

| Група | Роль-gate | Ендпоінти |
|---|---|---|
| `/api/v2/scenarios/*` | `RIAD Scenario Admin` або `System Manager` | GET list, GET {name}+items, POST upsert, POST {name}/items upsert |
| `/api/v2/ai-admin/*` | `RIAD AI Admin` або `System Manager` | GET providers, POST providers upsert, GET request-logs (пагінація) |

Роль-gate через `frappe_roles` у JWT (R2): `CurrentUser.has_frappe_role(role_name)`.

**4. AI Деградація UI:**

| Endpoint | Контракт |
|---|---|
| `GET /api/v2/ai/degradation` | `{level, providers, message}`. Level: `primary` (≥1 closed), `fallback` (≥1 half_open), `manual` (all open). |

**5. frappe_roles в JWT (R2 реалізація):**

- `create_access_token()` отримав `frappe_roles` параметр
- `CurrentUser.frappe_roles: list` + `has_frappe_role(role_name)` метод
- Login/refresh витягують raw ролі з Frappe User.roles
- `/me` повертає `frappe_roles`

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `app/auth/jwt.py` | `create_access_token` — додано `frappe_roles` param |
| `app/auth/dependencies.py` | `CurrentUser` — додано `frappe_roles`, `has_frappe_role()` |
| `app/routes/auth.py` | `_extract_frappe_roles()`; login/refresh передають roles; `/me` повертає `frappe_roles` |
| `app/schemas/estimate.py` | Новий: EstimateBuildRequest/Response, EstimateReviewRequest/Response, EstimateConfirmResponse |
| `app/schemas/media.py` | Новий: TranscriptionManualRequest, TranscriptionResponse |
| `app/schemas/scenario.py` | Новий: ScenarioUpsertRequest, ScenarioItemUpsertRequest, ScenarioResponse, ScenarioListResponse |
| `app/schemas/ai_admin.py` | Новий: AIProviderUpsertRequest, AIProviderResponse, AIRequestLogEntry, AIRequestLogListResponse, AIDegradationResponse |
| `app/schemas/ai.py` | Додано: AIDegradationResponse |
| `app/services/estimate_service.py` | Новий: build_estimate (sync/RQ), review_estimate, confirm_estimate |
| `app/routes/estimates.py` | Новий: /api/v2/estimates/* (build, review, confirm) |
| `app/routes/media.py` | Новий: /api/v2/media/* (transcribe, transcription) |
| `app/routes/scenarios.py` | Новий: /api/v2/scenarios/* CRUD + role gate |
| `app/routes/ai_admin.py` | Новий: /api/v2/ai-admin/* providers + request-logs + role gate |
| `app/routes/ai.py` | Додано: GET /api/v2/ai/degradation |
| `app/main.py` | Зареєстровані нові роутери (scenarios/ai_admin перед doctypes для уникнення конфлікту) |
| `app/core/config.py` | `extra = "ignore"` у Settings.Config (для .env змінних поза моделлю) |
| `tests/a4/test_a4_session.py` | Новий: 27 unit-тестів |

#### DoD перевірка

1. ✅ **estimate.build** → Estimate DocType створено (sync або RQ) + AI Request Log записано
2. ✅ **estimate.review** → reviewed_by, status змінено (approved→Approved, rejected→Rejected)
3. ✅ **estimate.confirm** → Quotation через Est.create_quotation() (validated: status=Approved, reviewed_by)
4. ✅ **POST /api/v2/media/{name}/transcribe** → RQ enqueue
5. ✅ **POST /api/v2/media/{name}/transcription** → manual text записано, status="manual"
6. ✅ **/api/v2/scenarios/** CRUD + role gate (RIAD Scenario Admin)
7. ✅ **/api/v2/ai-admin/** providers + request_log.list + role gate (RIAD AI Admin)
8. ✅ **GET /api/v2/ai/degradation** → {level, providers} з правильним рівнем за CB state
9. ✅ **27 тестів проходять**
10. ✅ **AI↔Vault isolation lint** — зелений (`OK: 58 files scanned across 4 restricted paths`)
11. ✅ **Синтаксис**: `py_compile` усіх змінених файлів — OK

#### Примітки

- `scenarios_router` зареєстрований ПЕРЕД `doctypes_router` у main.py — інакше legacy `/api/v2/scenarios` з doctypes.py перехоплює запити (doctypes prefix = `/api/v2`).
- `doctypes.py` містить legacy `/scenarios` routes (без role-gate). Нові routes з scenarios.py перехоплюють їх раніше.
- `estimate_confirm` викликає `Estimate.create_quotation()` whitelist-метод напряму через Frappe REST API. Це тимчасово поки `erpnext_gateway` не створено (S1/major refactor).
- `Settings.Config.extra = "ignore"` — потрібно для тестів у середовищі з .env файлом що містить змінні поза моделлю Settings.
- `docker-compose.yml` — виправлено дублікат сервісу `whisper` (large-v3 vs medium).

---

### S1 — Sync backend (v2): push/pull/resolve ✅ DONE

**Дата:** 2026-06-23
**Статус:** DoD виконано

#### Технічне рішення

Sync backend реалізований як три FastAPI endpoints у `app/routes/sync.py` з бізнес-логікою у `app/services/sync_service.py`. Всі виклики до Frappe — через делегований SID (R1).

**Крок 0 — Конвертація `visit` DocType:**
- `visit.json`: `istable: 0`, `autoname: "field:client_uuid"`, додано sync поля (client_uuid, riad_version, riad_deleted, riad_deleted_at), `service_ticket (Link)`, `visit_type (Select)`, `summary (Small Text)`.
- `service_ticket.json`: прибрано `visits (Table → Visit)` — несумісно з `istable: 0`.
- `visit_material.json` / `visit_photo.json`: додано sync поля (client_uuid, riad_version, riad_deleted, riad_deleted_at).
- `bench migrate` — OK.

**ADDITIVE_COLLECTIONS:**

```python
{
    "Visit": {
        "visit_material": {"frappe_field": "materials", "uuid_field": "client_uuid"},
        "visit_photo": {"frappe_field": "photos", "uuid_field": "client_uuid"},
    },
    "Checklist Instance": {
        "checklist_instance_item": {"frappe_field": "instance_items", "uuid_field": "item_uuid"},
    },
    "Installation Map": {
        "mount_point": {"frappe_field": "mount_points", "uuid_field": "point_uuid"},
        "cable_route": {"frappe_field": "cable_routes", "uuid_field": "route_uuid"},
    },
}
```

**Watermark:** `base64(json({"ts": "ISO timestamp"}))` — непрозорий для клієнта; декодується лише на сервері.

**Конфлікт:** `client_base_version < server_version` AND `client_value != server_value` → POST до `Sync Conflict` DocType. Неконфліктні скаляри застосовуються. `riad_version + 1`.

**Tombstone:** `op=delete` → PUT `{riad_deleted: 1, riad_deleted_at: now, riad_version: +1}`.

**Ідемпотентність:** create з `client_base_version=0`, документ вже існує на v1, всі скаляри збігаються → `ignored_duplicate`. Additive rows: якщо `_uuid` вже є → `already_present`.

#### Змінені/створені файли

| Файл | Дія |
|------|-----|
| `doctype/visit/visit.json` | Конвертовано: istable=0, autoname=field:client_uuid, sync поля, visit_type, summary |
| `doctype/visit/visit.py` | Оновлено validate() з guard |
| `doctype/visit_material/visit_material.json` | Додано sync поля |
| `doctype/visit_photo/visit_photo.json` | Додано sync поля |
| `doctype/service_ticket/service_ticket.json` | Прибрано visits Table field |
| `app/schemas/sync.py` | Новий: всі Pydantic sync DTO |
| `app/services/sync_service.py` | Новий: pull_changes, push_batch, resolve_conflict + ADDITIVE_COLLECTIONS |
| `app/routes/sync.py` | Новий: POST /api/v2/sync/pull, /push, /resolve |
| `app/main.py` | Додано sync_router |
| `tests/s1/__init__.py` | Новий |
| `tests/s1/test_s1_sync.py` | Новий: 9 unit тестів (8+1 split) |
| `.github/workflows/ci.yml` | Новий крок S1 + py_compile |

#### DoD перевірка

1. ✅ **pull + push + resolve endpoints**: POST /api/v2/sync/{pull,push,resolve} — зареєстровані, JWT-захищені
2. ✅ **Union-merge additive collections**: visit_material/visit_photo by client_uuid; checklist_instance_item by item_uuid; mount_point/cable_route by point_uuid/route_uuid
3. ✅ **Scalar conflict → Sync Conflict DocType**: POST /api/resource/Sync Conflict з полями conflict_doctype, conflict_docname, conflict_field
4. ✅ **Tombstones**: op=delete → riad_deleted=1 + riad_deleted_at + version+1
5. ✅ **Ідемпотентність push**: ignored_duplicate для дублікат create; already_present для дублікат additive rows
6. ✅ **9 тестів проходять**: pull/create/update/conflict/tombstone/idempotent/union-merge/resolve
7. ✅ **AI↔Vault isolation lint**: зелений
8. ✅ **Синтаксис**: py_compile всіх нових файлів — OK
9. ✅ **Visit DocType конвертовано**: istable=0, autoname=field:client_uuid, bench migrate — OK

---

