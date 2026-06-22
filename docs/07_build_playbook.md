# RIAD / Security ERP Platform — Build Playbook v2 (НАПРЯМ B1)

> **Замінює** попередню версію (яка передбачала green-field). Ця — під реальний код:
> ERPNext v15 + FastAPI-гейтвей `security-api`, вже частково в production на `riad.fun`.
> **Метод не змінився:** 1 пункт = 1 сесія Claude Code = 1 DoD-інваріант.
> **Джерело правди:** `docs/00_reconciliation_audit.md` + `docs/DECISIONS.md` (блок «НАПРЯМ B1»).

---

## 0. Що змінилось проти v1

- **E0 (інфра) — здебільшого вже є.** Traefik, Cloudflare-тунель, MariaDB, Redis, CI, бекап-скрипт
  — стоять. Лишається аудит durability-деталей, не побудова з нуля.
- **Нова фаза R (Reconciliation) — стабілізація перед нарощуванням.** 8 сесій, які закривають
  безпекову дірку (Administrator-обхід) і дата-модельний борг, перш ніж додавати Vault/AI/sync.
- **Vault — окремий модуль у `security_erp` (in-process Frappe), НЕ частина FastAPI.** Це
  ключова відмінність від v1-плану (де Vault мав ізолюватись лише import-linter'ом в одному
  дереві коду) — тепер ізоляція ще й між процесами/контейнерами.
- **Gateway-дисципліна — Pydantic-DTO в `/api/v2/*`**, не `riad.erpnext_gateway` in-process.

---

## 1. Карта сесій

| # | Сесія | Фаза | Передумови | Скл. | Гейт |
|---|---|---|---|---|---|
| R1 | 🔴 Per-user делегування до Frappe (прибрати Administrator-обхід) | R | — | 5 | **блокує все нижче** |
| R2 | Реальні Frappe-ролі замість `_default_role()` хардкоду | R | R1 | 3 | — |
| R3 | Refresh-ротація + reuse-detection + Device Session DocType | R | R1 | 4 | — |
| R4 | Gateway-дисципліна: v2 DTO-шар + лінт «без сирого DocType поза сервіс-шаром» | R | R1 | 3 | — |
| R5 | Durability-аудит: binlog PITR, Redis AOF, шифровані бекапи, restore-drill | R | — | 3 | — |
| R6 | Дата-модель: злиття перетинів (Scenario / AI Estimate / Engineer Visit) | R | R1 | 4 | — |
| R7 | Дата-модель: батч відсутніх (Site Brief…Remote Inspection) | R | R6 | 4 | — |
| R8 | Дата-модель: Vault-неймспейс DocType (без логіки, лише схема) | R | R7 | 3 | — |
| V1 | ✅ Vault-модуль: межі пакета + крипто core (AES-GCM пополе, ключ поза БД) | E6 | R8 | 5 | — |
| V2 | ✅ Ізоляція Vault↔AI (CI-лінт міжпроцесна+імпорти) + hash-chain аудит | E6 | V1 | 5 | — |
| V3 | ✅ MFA step-up + vault read/write API (v2 DTO) | E6 | V2 | 5 | — |
| V4 | ✅ Access Transfer Act + Vault UI | E6 | V3 | 5 | **C2 до прод** |
| A1 | 🔴 AI-адаптер (мультипровайдер) + Circuit Breaker + failover | E5 | R4 | 5 | — |
| A2 | 🔴 Анонімізація fail-closed + людський gate + AI Request Log | E5 | A1 | 5 | — |
| A3 | 🔴 Whisper self-hosted + RQ-задачі | E5 | A2 | 5 | — |
| A4 | 🔴 estimate.confirm→gateway межа + no-code адмінки + AI-деградація UI | E5 | A3 | 5 | — |
| S1 | 🔴 Sync backend (v2): push/pull, union-merge, watermark | E4 | R4 | 5 | — |
| S2 | 🔴 Flutter offline core (Drift) | E4 | S1 | 5 | — |
| S3 | 🔴 Польові флоу Flutter + Drive | E4 | S2 | 5 | row-level до фіналу |
| S4 | Next.js карта-редактор + склад через v2 | E4 | S3 | 5 | — |
| C1 | Калькулятор backend (rate-limit+captcha, детермінований) | E7 | A4 | 3 | — |
| C2 | Публічний сайт: воронка калькулятора | E7 | C1 | 3 | **rate-limit до прод** |
| P1 | Push (FCM) | E8 | S4, A4, V4 | 2 | — |
| SV1 | Сервіс-флоу: Service Request → Warranty Claim + ref на Vault Audit | E8 | P1 | 2 | — |
| H1 | Key-escrow (C2) + DR-runbook + restore-drill з Vault | E9 | V4, C2 | 4 | **ГЕЙТ прод** |
| H2 | Тюнінг (CB/Whisper/пороги) + фінальна готовність | E9 | H1 | 4 | — |

24 сесії (було 28). Скоротилось за рахунок готової інфри (E0) і часткового MVP (E3 вже всередині R6/R7).

---

## 2. Фаза R — Reconciliation (деталі)

### R1 — 🔴 Per-user делегування до Frappe
**Чому перша.** Поки запити йдуть як Administrator, Frappe permission engine не працює.
Будь-яка робота над Vault/правами/полями зверху буде стояти на піску.
**Мета:** `app/core/database.py` — прибрати `_get_sid()` логін як Administrator. Два варіанти
реалізації лишити на технічне рішення Claude Code: (a) кешована Frappe-сесія per-user
(SID-cookie конкретного юзера, з ререлогіном на expiry), або (b) персональний API-ключ
(`token KEY:SECRET`) per Frappe User, видається при створенні юзера.
**DoD:** запит від ролі «монтажник» у Frappe видно як дії цього user (не Administrator) у
Frappe Version log; поле з `permlevel 1` реально приховане для цієї ролі (перевірка двома
ролями); жодного місця в коді, де AI/звичайний CRUD йде як Administrator.
**Доки:** `docs/00_reconciliation_audit.md` (Вісь 2), `docs/DECISIONS.md` (НАПРЯМ B1).
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md (якщо порожній — це перша сесія фази R).
Реалізуй сесію R1 (КРИТИЧНА, безпекова): прибери в app/core/database.py логін до Frappe як
Administrator. Запити мають виконуватись від імені РЕАЛЬНОГО Frappe User поточної сесії —
або через кешовану per-user Frappe-сесію (SID, з ререлогіном на expiry), або через персональний
API-ключ (token KEY:SECRET) per Frappe User. Обери технічно кращий варіант для async httpx-клієнта,
обґрунтуй вибір у BUILD_LOG. Онови app/auth/dependencies.py, щоб user-контекст витікав до database.py.
Звірся з docs/00_reconciliation_audit.md (Вісь 2) і docs/DECISIONS.md (НАПРЯМ B1).
DoD (зупинись тут): дія від ролі "монтажник" видно у Frappe Version log як ЦЕЙ user, не
Administrator; поле permlevel 1 реально приховане для цієї ролі (перевір двома ролями: owner і
service_manager); ЖОДНОГО місця в коді, де звичайний CRUD йде як Administrator.
Онови BUILD_LOG.md і запропонуй промт R2.
```

### R2 — Реальні Frappe-ролі замість хардкоду
**Мета:** прибрати `_default_role()`; роль і права — з реального `User.roles` через щойно
полагоджений per-user доступ (R1). FastAPI-RBAC лишається як швидкий перший фільтр на вході
запиту (early-reject для UX), але **не як джерело правди**.
**DoD:** новий Frappe User з роллю `Технік` логіниться у FastAPI і отримує саме цю роль, без
хардкод-мапи; зміна ролі у Frappe одразу відображається при наступному login/refresh.
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R2: прибери _default_role() у app/routes/auth.py. Роль користувача читай з
реального Frappe User.roles через per-user доступ із R1. FastAPI-RBAC (ROLE_PERMISSIONS)
лишається як ранній фільтр, НЕ як джерело правди. Звірся з docs/00_reconciliation_audit.md (Вісь 2).
DoD (зупинись тут): новий Frappe User з роллю Технік логіниться і отримує саме цю роль без
хардкоду; зміна ролі в Frappe відображається при наступному login/refresh.
Онови BUILD_LOG.md і запропонуй промт R3.
```

### R3 — Refresh-ротація + reuse-detection + Device Session
**Мета:** наявні JWT (15хв/7дн) підсилити ротацією refresh-токена і **reuse-detection**
(повторне використання вже використаного refresh → примусовий logout усіх сесій пристрою).
Формалізувати «RIAD Device Session» (зараз — лише Redis blacklist) як DocType або еквівалентну
персистентну структуру для аудиту сесій і per-device revoke.
**DoD:** повторне використання старого refresh-токена → явна помилка + примусовий вихід усіх
сесій того пристрою; список активних сесій користувача доступний і відкликається вибірково.
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R3: ротація refresh-токена при кожному /api/v2/auth/refresh; reuse-detection
(повторне використання вже використаного refresh → RIAD-AUTH-REFRESH-REUSE + примусовий logout
усіх сесій пристрою). Формалізуй RIAD Device Session (зараз лише Redis blacklist) — DocType або
персистентна структура з полями device/created/last_seen/revoked, для аудиту і per-device revoke.
Звірся з docs/00_reconciliation_audit.md (Вісь 6).
DoD (зупинись тут): повторний refresh → помилка + примусовий вихід усіх сесій пристрою; список
активних сесій користувача доступний і відкликається вибірково.
Онови BUILD_LOG.md і запропонуй промт R4.
```

### R4 — Gateway-дисципліна (v2 DTO-шар)
**Мета:** формалізувати `/api/v2/*` як єдиний шлях нового коду — типізовані Pydantic DTO,
сервіс-шар між роутом і `database.py` (не прямий `frappe_get/post` з роута). `proxy.py`/v1
лишається задокументованим legacy без розширення. Лінт/перевірка (CI або pre-commit) — нові
DocType-звернення поза сервіс-шаром не проходять рев'ю.
**DoD:** новий ендпоінт неможливо дописати, оминувши сервіс-шар, без явного порушення
структури теки; v1 routes не приймають нових DocType.
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R4: формалізуй app/services/ як обов'язковий шар між роутами /api/v2/* і
app/core/database.py — роути НЕ викликають frappe_get/post напряму, лише через service-класи
з Pydantic DTO на вході/виході. Додай CI-перевірку (лінт-скрипт або pre-commit), що ловить прямі
звернення до database.py з routes/. Задокументуй /api/v1 (proxy.py) як закритий для розширення
legacy. Звірся з docs/00_reconciliation_audit.md (Вісь 4).
DoD (зупинись тут): лінт червоніє, якщо роут v2 обходить сервіс-шар; v1 без нових DocType.
Онови BUILD_LOG.md і запропонуй промт R5.
```

### R5 — Durability-аудит
**Мета:** перевірити (не побудувати з нуля) — MariaDB binlog для PITR, Redis AOF persistence,
`backup.sh` шифрує бекапи at-rest, є робочий restore-drill на staging.
**DoD:** drill «бекап→відновлення» проходить з перевіркою цілісності; прогалини (якщо є)
задокументовані з конкретним планом закриття.
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R5: проведи durability-аудит наявної інфраструктури — чи увімкнено MariaDB binlog
(PITR), чи Redis має AOF persistence, чи backup.sh шифрує бекапи at-rest. Проведи restore-drill на
staging з перевіркою цілісності даних. Звірся з docs/06_risks_scaling_audit.md (M1/M2/M6).
DoD (зупинись тут): drill пройдено з перевіркою цілісності; будь-які прогалини задокументовані в
BUILD_LOG з конкретним планом закриття (навіть якщо закриття — наступна сесія).
Онови BUILD_LOG.md і запропонуй промт R6.
```

### R6 — Дата-модель: злиття перетинів
**Мета:** узгодити три DocType, де є концептуальний збіг, за мапінгом аудиту:
- `security_scenario`/`security_scenario_item` → додати поля `qty_rule`/`qty_factor` (звірити
  з `docs/02_data_model.md` Scenario).
- `estimate`/`estimate_item` → додати `origin` (ai_primary/ai_fallback/manual), `variant`,
  `reviewed_by`, і `permlevel 1` на цінових полях (purchase_rate/profit/margin/total_cost).
- `visit`/`visit_material`/`visit_photo` → додати sync-метадані (`client_uuid` як `name`,
  `riad_version`, `riad_deleted`+`riad_deleted_at`).
**DoD:** усі три міграції чисті; permlevel на estimate реально приховує ціну для ролі
«монтажник» (залежить від R1); sync-поля присутні, але ще без логіки (логіка — S1).
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R6 (злиття перетинів дата-моделі): додай у security_scenario поля qty_rule/
qty_factor; додай у estimate/estimate_item поля origin (ai_primary/ai_fallback/manual), variant,
reviewed_by, і постав permlevel 1 на purchase_rate/profit/margin/total_cost; додай у visit/
visit_material/visit_photo sync-метадані (client_uuid як name, riad_version, riad_deleted+
riad_deleted_at). Звірся з docs/02_data_model.md і docs/00_reconciliation_audit.md (Вісь 3).
DoD (зупинись тут): усі три міграції чисті; permlevel реально приховує ціну для ролі
"монтажник" (перевір через R1 per-user доступ); sync-поля присутні (логіку синку додамо в S1).
Онови BUILD_LOG.md і запропонуй промт R7.
```

### R7 — Дата-модель: батч відсутніх DocType
**Мета:** додати спроєктовані DocType, яких немає взагалі: `Site Brief`, `Object Passport`,
`Passport Client Release`, `Installation Map`(+Mount Point/Cable Route), `Checklist Template`
(+items), `Checklist Instance`(+items), `Remote Inspection`, `Media Asset` (розширює вузький
`visit_photo` — drive_file_id/transcription/ai_allowed/tombstone).
**DoD:** усі DocType батчу мігрують чисто; `Object Passport` Link-ається на наявний
`security_object` (не дублює CMDB); `Media Asset` має поле `ai_allowed` за замовчуванням `0`.
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R7: додай DocType — Site Brief, Object Passport (Link на наявний security_object,
не дублюй CMDB-поля), Passport Client Release, Installation Map (+Mount Point/+Cable Route),
Checklist Template (+items), Checklist Instance (+items), Remote Inspection, Media Asset
(drive_file_id, transcription, ai_allowed default=0, tombstone-поля). Поля за docs/02_data_model.md.
DoD (зупинись тут): усі DocType батчу мігрують чисто; Object Passport лінкується на security_object
без дублювання; Media Asset.ai_allowed=0 за замовчуванням.
Онови BUILD_LOG.md і запропонуй промт R8.
```

### R8 — Дата-модель: Vault-неймспейс (схема, без логіки)
**Мета:** створити DocType для Vault-неймспейсу — **лише схема**, без крипто-логіки (та йде
в V1). `Vault Entry`, `Vault Access Enrollment`, `Vault Audit Log`, `Access Transfer Act`
(окремо від наявного `warranty_letter` — інше призначення), `AI Provider`, `AI Request Log`,
`Sync Conflict`.
**DoD:** усі DocType мігрують чисто; `*_enc`-поля у Vault Entry — `Long Text` (не Frappe
Password); жодної крипто-логіки ще немає (це навмисно — V1 додасть).
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію R8: створи DocType (ЛИШЕ схема, без крипто-логіки) — Vault Entry (*_enc поля як
Long Text, НЕ Frappe Password), Vault Access Enrollment, Vault Audit Log, Access Transfer Act
(окремий від наявного warranty_letter), AI Provider, AI Request Log, Sync Conflict. За
docs/02_data_model.md і docs/00_reconciliation_audit.md (Вісь 3, рядок 18 — конфлікт назв).
DoD (зупинись тут): усі DocType мігрують чисто; *_enc=Long Text; крипто-логіки немає (свідомо,
для V1).
Онови BUILD_LOG.md і запропонуй промт V1.
```

> ✅ Після R8 — стабілізована база: реальні права (R1-R2), персистентні сесії (R3), дисципліна
> gateway (R4), перевірена durability (R5), повна дата-модель (R6-R8). Можна нарощувати Vault/AI/sync.

---

## 3. Фаза V — Vault як окремий модуль (деталі сесій V1–V4)

**Ключова відмінність від v1-плану.** Vault не просто «ізольований код у тому самому дереві
файлів» — він живе **в іншому процесі** (Frappe), ніж AI-сервіси (`security-api`/FastAPI). Це
сильніша гарантія за дизайном (мережева межа, не лише import-заборона), але CI-перевірка має
довести **обидва** рівні: відсутність Vault-коду в `security-api`, і відсутність шляху виклику
з AI-воркерів до Vault-модуля.

### V1 — 🔴 Vault-модуль: межі пакета + крипто core
**Мета:** новий Python-підпакет усередині `security_erp` (наприклад `security_erp/vault/`) —
**фізично окрема тека**, не розкидані файли. AES-256-GCM пополе на `Vault Entry.*_enc`,
майстер-ключ читається поза БД (docker secret/файл `0400`, НЕ env). Дешифрування — лише
всередині `security_erp/vault/`, викликається тільки з Frappe whitelisted-методів (не з FastAPI
напряму, не з RQ-воркерів).
**DoD:** шифрування/дешифрування працює пополе; ключ не в env і не в БД; спроба імпортувати
крипто-функцію Vault із будь-якого файлу поза `security_erp/vault/` — і це видно (готує ґрунт
під V2-лінт).
**📋 промт:**
```
Прочитай CLAUDE.md і BUILD_LOG.md.
Реалізуй сесію V1: створи окремий Python-підпакет security_erp/vault/ (фізично окрема тека).
Крипто-core: AES-256-GCM пополе на Vault Entry.*_enc, майстер-ключ читається ПОЗА БД (docker
secret або файл 0400, НЕ env). Шифрування/дешифрування — функції ЛИШЕ всередині
security_erp/vault/, викликаються тільки з Frappe whitelisted-методів (не з FastAPI напряму,
не з RQ-воркерів). Звірся з docs/02_data_model.md і docs/DECISIONS.md (Вісь 6-Vault).
DoD (зупинись тут): пополе-шифрування зовнішнім ключем працює; ключ не в env і не в БД;
крипто-функції фізично лише в security_erp/vault/.
Онови BUILD_LOG.md і запропонуй промт V2.
```

### V2 — 🔴 Ізоляція Vault↔AI (CI, двошарова) + hash-chain аудит
**Мета:** CI-перевірка на **двох рівнях**: (а) Python-лінт (import-linter або еквівалент) —
заборона імпорту `security_erp/vault/*` з будь-якого AI-related модуля `security_erp` чи
`security-api`; (б) мережевий рівень — `security-api`/AI-воркери не мають мережевого доступу
до Vault-функцій (вони і так недосяжні ззовні Frappe-процесу, але задокументувати явно).
`Vault Audit Log` — hash-chain (prev_hash/record_hash, append-only, без update/delete-прав).
**DoD:** CI червоніє при спробі імпорту Vault-коду з AI-шляху; кожен read/write Vault-поля →
запис у hash-chain; зміна запису ламає верифікацію ланцюга.
**📋 промт:**
```
Прочитай CLAUDE.md, BUILD_LOG.md.
Реалізуй сесію V2: CI-лінт (import-linter або еквівалент для Python) — заборона імпорту
security_erp/vault/* з AI-related модулів security_erp і з services/security-api/. Задокументуй
у README/CLAUDE.md, що AI-воркери (RQ) і security-api взагалі не мають мережевого шляху до
Vault-функцій (вони існують лише в Frappe-процесі). Vault Audit Log — hash-chain
(prev_hash/record_hash, append-only, без update/delete-прав на DocType). Звірся з
docs/015_architecture_audit.md (C1/M5) якщо є в docs/, інакше з docs/DECISIONS.md (Вісь 6-Vault).
DoD (зупинись тут): CI червоніє при імпорті Vault-коду з AI-шляху; кожен read/write → hash-chain
запис; зміна запису ламає верифікацію.
Онови BUILD_LOG.md і запропонуй промт V3.
```

### V3 — 🔴 MFA step-up + vault read/write API
**Мета:** TOTP MFA step-up сесія (5хв, Redis), Frappe whitelisted-методи
`vault.entry.read/upsert` під свіжою MFA-сесією, виставлені назовні через `/api/v2/vault/*`
у FastAPI **як тонкий проксі** (FastAPI не дешифрує, лише передає виклик до Frappe-методу
від імені делегованого user — і отримує вже готовий результат).
**DoD:** дешифрування вимагає свіжої MFA-сесії; FastAPI-шар не містить дешифрованих секретів
довше часу запиту-відповіді (не кешує); кожен read/write — в аудиті.
**📋 промт:**
```
Прочитай CLAUDE.md, BUILD_LOG.md.
Реалізуй сесію V3: TOTP MFA step-up сесія (5хв, Redis) у security_erp/vault/. Frappe whitelisted-
методи vault.entry.read/upsert під свіжою MFA-сесією. У FastAPI /api/v2/vault/* — тонкий проксі:
викликає Frappe-метод від імені делегованого user (з R1), НЕ дешифрує і не кешує секрети сам.
Звірся з docs/03_api_ai_architecture.md (Vault step-up) і docs/DECISIONS.md (НАПРЯМ B1).
DoD (зупинись тут): дешифрування вимагає свіжої MFA-сесії; FastAPI не кешує дешифровані секрети;
кожен read/write — у Vault Audit Log.
Онови BUILD_LOG.md і запропонуй промт V4.
```

### V4 — ✅ Access Transfer Act + Vault UI · ⚠️ гейт C2 до прод
**Мета:** `act.generate/delivery.link/acknowledge` — on-demand під MFA, дешифровані дані лише
в пам'яті на доставку (не at-rest), ніколи у Drive, одноразове TTL-посилання. UI (Next.js,
коли з'явиться, або тимчасово — ERPNext desk-форма з обмеженим доступом) — список+перегляд під
MFA, маскування, «записано в аудит».
**DoD:** Акт без at-rest-секретів, ніколи у Drive, TTL-посилання.
**Гейт:** жодних реальних Vault-секретів у production до key-escrow процедури (H1).
**📋 промт:**
```
Прочитай CLAUDE.md, BUILD_LOG.md.
Реалізуй сесію V4: Access Transfer Act — act.generate/delivery.link/acknowledge, on-demand під
MFA, дешифровані дані ЛИШЕ в пам'яті на доставку (не at-rest), НІКОЛИ у Drive, одноразове
TTL-посилання. UI під MFA (Next.js якщо вже є з S4/паралельно, інакше тимчасова ERPNext-форма з
обмеженим доступом) — список+перегляд, маскування значень, "записано в аудит".
DoD (зупинись тут): Акт без at-rest-секретів, ніколи у Drive, доставка TTL-посиланням.
ВАЖЛИВО: познач у BUILD_LOG — key-escrow (C2) і далі реальні Vault-секрети в прод лише після H1.
Онови BUILD_LOG.md і запропонуй промт A1 (якщо Vault-трек завершується тут) або наступний за
обраним порядком (див. §5 цього документа).
```

---

## 4. Фази A (AI), S (Sync), C (Калькулятор), P (Push), SV (Сервіс), H (Гартування)

Зміст сесій A1–A4, S1–S4, C1–C2, P1, SV1, H1–H2 концептуально **той самий**, що в v1-плані
(Пункти 15–28), з трьома відмінностями, які застосовуй у кожній сесії цих фаз:

1. **Усі нові ендпоінти йдуть через `/api/v2/*` з DTO-шаром** (R4), не `riad.api.v1.*` in-process.
2. **Усі звернення до Frappe — від делегованого user** (R1), ніколи Administrator.
3. **Жодна з цих фаз не торкається `security_erp/vault/`** — якщо AI чи sync-сесія відчуває
   потребу прочитати щось із Vault (наприклад, «показати збережений пароль доступу під час
   виїзду») — це робиться **виключно** через `/api/v2/vault/*` (V3) під MFA того самого
   технічного юзера, ніколи прямим імпортом.

При відкритті сесій A1–H2 використовуй формулювання промтів з **v1-плану** (попередня версія
`docs/07_build_playbook.md`, якщо збережена в BUILD_LOG як референс, або переформулюй за
зразком R-сесій вище), додаючи на початку кожного промту цей абзац:

```
ВАЖЛИВО (НАПРЯМ B1): нові ендпоінти — лише /api/v2/* з Pydantic DTO через сервіс-шар (R4).
Звернення до Frappe — від делегованого user (R1), НІКОЛИ Administrator. Якщо потрібен доступ
до Vault — лише через /api/v2/vault/* (V3) під MFA, ніколи прямий імпорт security_erp/vault/.
```

---

## 5. Порядок

**Обов'язково послідовно:** R1 → R8 (фундамент, кожна наступна спирається на права з R1).

**Після R8 — рекомендований порядок** (як і в v1, логіка та сама: спершу безпековий вузол із
запасом часу, потім вузол на критичному шляху):
V1→V4 (Vault) → A1→A4 (AI, розблоковує калькулятор) → S1→S4 (offline) → C1→C2 (калькулятор) →
P1 → SV1 → H1→H2.

**З окремими руками:** V-трек залежить лише від R8, тож може йти паралельно з A/S-треками.

## 6. Жорсткі гейти

| Гейт | Блокує | Закривається |
|---|---|---|
| Per-user делегування (R1) | **Усе нарощування** (R2 і далі) | R1, перша сесія |
| Key-escrow майстер-ключа (C2) | Реальні Vault-секрети в production | Проєктування V1-V4; операціоналізація H1 |
| Rate-limit калькулятора | Вихід калькулятора в production | C1 (дефолт) → H2 (фінальні пороги) |
| Гранулярність «свої об'єкти» | Row-level у польових флоу | Рішення до S3 |

## 7. Чек-перед-стартом

- [ ] `docs/00_reconciliation_audit.md`, `docs/DECISIONS.md` (з блоком «НАПРЯМ B1»), цей
      `docs/07_build_playbook.md` — у репо.
- [ ] `CLAUDE.md` (v2, під B1) — у корені.
- [ ] `BUILD_LOG.md` створено (порожній до R1).
- [ ] Усвідомлено: **R1 — перша сесія, без винятків.** Усе інше чекає на неї.
