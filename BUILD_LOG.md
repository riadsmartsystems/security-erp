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

## Наступний пункт: R2

**Промт R2:**

```
Прочитай BUILD_LOG.md (R1 виконано).
Реалізуй сесію R2: JWT reuse-detection + refresh token rotation.
Поточні проблеми в app/auth/jwt.py і routes/auth.py:
1. Refresh token не обертається (один і той самий refresh token можна використовувати безліч разів).
2. Немає reuse-detection (якщо refresh token вкрадено і використано зловмисником, легітимний власник не дізнається).
Рішення: при /refresh видавати НОВИЙ refresh token, а старий додавати в Redis blacklist з TTL = jwt_refresh_ttl. Якщо прийшов вже blacklisted refresh token → негайно інвалідувати ВСІ токени цього юзера (blacklist всіх активних access tokens не реально — замість цього видалити frappe:sid:{user_id} з Redis і опціонально зберегти "compromised" прапор).
DoD: повторне використання вже використаного refresh token повертає 401 і інвалідує сесію юзера; нормальний /refresh видає новий refresh token і старий більше не працює; frappe SID зберігається при нормальному refresh.
Онови BUILD_LOG.md і запропонуй промт R3.
```
