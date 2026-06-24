# DECISIONS.md — Журнал архітектурних рішень RIAD Smart System

> **Джерело правди для всіх сесій.** Кожна фаза дописує сюди свій блок.
> Claude звіряється з цим файлом на початку кожного чату.
> Тут — ТІЛЬКИ рішення й відкриті питання. Детальні результати фаз — в окремих документах.

---

## Базові рішення (з ТЗ, зафіксовані до старту фаз)
- **БД:** єдина MariaDB (та сама, що в ERPNext). Без окремих СУБД.
- **ERPNext:** backend через API, не UI для кінцевих користувачів.
- **Галузеві сутності:** кастомні DocType у власному Frappe custom app на тому ж сайті.
- **AI:** мультипровайдерний, провайдер-агностичний шар, ланцюг основний → резервний → ручний.
- **Password Vault:** AES-256-GCM пополе, майстер-ключ окремо від БД, TOTP MFA, повний аудит,
  ізоляція від AI на рівні коду.
- **Конфіденційність:** анонімізація PII перед зовнішнім AI; голос — самостійний Whisper.
- **Mobile:** offline-first Flutter (Android пріоритет), ручне вирішення конфліктів синхронізації.
- **Авторизація:** власна JWT RBAC RIAD, що мапиться на ролі Frappe.
- **Файли:** Google Drive API через сервісний акаунт; Vault і паспорти з доступами — ніколи у Drive.
- **Інфраструктура:** власний Linux-сервер (Docker), нічні бекапи, staging + production.
- **Контекст:** ФОП, UAH, Monobank.

---

## Фаза 1 — Фундамент (архітектура + стек) — [дата]
### Прийняті рішення
- RIAD API = whitelisted-методи custom app усередині Frappe; фронтенди (Flutter/Next.js) звертаються по HTTPS з JWT. Доступ до ERPNext — in-process через Frappe ORM, без внутрішнього HTTP-хопу між RIAD і ERPNext. «Через API» = межа фронтенд↔бекенд.
- Whisper розгортається як ОКРЕМИЙ self-hosted контейнер; оркестрація STT — в AI Services Layer, сам рушій поза Frappe-процесом.
- Realtime («Мої задачі сьогодні», статуси) — вбудований Frappe WebSocket (socketio) + Redis pub/sub. Мобільний push (FCM) — у UX-фазу.
- Reverse proxy (Nginx/Traefik) — єдина точка входу + TLS; фронтенди не б'ються напряму в порт Frappe.
- 1 RIAD-користувач = 1 Frappe User з вимкненим desk-доступом (гранулярні права + аудит), не спільний акаунт.
- Майстер-ключ Vault завантажується з джерела поза БД (конфіг сервера) із чітким швом під майбутню заміну на KMS/HashiCorp Vault.
- Карти — OSM/MapLibre основний варіант (без білінгу), Google Maps опційно.
- Стек зафіксовано: Frappe/ERPNext v15 + Python custom app; MariaDB 10.6+; Redis; Frappe RQ-воркери; Next.js+TS PWA (Tailwind+headless, TanStack Query); Flutter (Drift/SQLite, flutter_secure_storage); JWT (PyJWT) + TOTP (pyotp); cryptography (AES-256-GCM); Whisper (faster-whisper); анонімізація — Python NER/правила; Docker Compose + Nginx/Traefik; Google Drive API (service account).
### Відкриті питання
- Тип Frappe User для польових ролей: System User з обмеженням desk чи Website User? (впливає на права/аудит) — Фаза 2/безпека.
- Конкретний механізм зберігання майстер-ключа на старті (env / файл / docker secret / OS keyring) — фаза безпеки.
- Бібліотека анонімізації PII і покриття української мови (Presidio+spaCy vs власні правила; обличчя/документи на фото) — Фаза 3.
- Захист публічного калькулятора від абʼюзу (rate-limit/captcha) — Фаза 3.
- UI-система для «Monobank/Ajax»-вигляду (Tailwind+headless / Mantine / shadcn) — Фаза 4.
- Модель версіонування sync-конфліктів (timestamp vs version vector; гранулярність документ/поле) — Фаза 2/мобільна.
- Чи потрібен окремий BFF на боці Next.js — за замовчуванням ні; перегляд при рості.
### Що це блокує / розблоковує
- Розблоковує Фазу 1.5 (аудит): є цілісна архітектура, яку можна критикувати.
- Розблоковує Фазу 2 (дата-модель): визначені межі custom app, групи DocType, принцип Link-зв'язків зі стандартними ERPNext-документами, in-process ORM.
- Розблоковує Фазу 3 (API+AI): зафіксовано межу JWT/RBAC, місце AI Services Layer і ланцюг failover.
- Блокує старт кодування — за методом спершу завершуємо проєктування (фази 1.5–4).
-

## Фаза 1.5 — Критичний аудит архітектури — _(дата)_
### Резолюції конфліктів Фази 1.5 (рішення власника)
- Конфлікт #1 (Vault-ізоляція) → ВАРІАНТ A прийнято: один custom app + CI-gate
  import-linter + роздільні воркери + ключ лише в людському web-контексті.
  ПОМІТКА: у майбутньому підняти безпеку — шов під Варіант B (виділений Vault-процес)
  та/або KMS/HashiCorp Vault лишається; перенесення дешифрування за процесну межу
  без переписування бізнес-логіки. Статус: відкладене рішення безпеки.
- Конфлікт #2 (offline-Vault) → ПРИЙНЯТО online-only за замовчуванням; нічого не
  кешується в локальний SQLite; винятковий офлайн-кеш (шифрований+TTL+wipe) — майбутня опція.
- РОЗБЛОКОВАНО: розміщення Vault DocType у Фазі 2.
- ЗАЛИШАЄТЬСЯ ВІДКРИТИМ (не блокує Фазу 2): механізм key-escrow майстер-ключа (C2) → фаза безпеки.
-

## Фаза 2 — Дата-модель: сутності, ER-діаграма, DocType — [дата]
### Прийняті рішення
- Розділено: стандартні DocType ERPNext (Lead/Customer/Item/Serial No/Quotation/Sales Order/
  Warranty Claim/Stock/Accounts/User) = джерело правди; кастомні DocType = лише галузева семантика.
  Жодного дублювання фінансів/складу/серійників — тільки Link.
- 20 кастомних DocType (custom app): Site Brief, Calculator Submission, Object Passport,
  Passport Client Release, Installation Map(+Mount Point/Cable Route), Scenario(+Scenario Item),
  AI Estimate(+AI Estimate Line), AI Provider, AI Request Log, Remote Inspection, Engineer Visit,
  Checklist Template(+items), Checklist Instance(+items), Media Asset, Vault Entry,
  Vault Access Enrollment, Vault Audit Log, Access Transfer Act, Service Request(+Service Action),
  RIAD Device Session, RIAD Audit Log, Sync Conflict.
- Внутрішня версія паспорта = Object Passport (DocType); клієнтська = детермінований рендер БЕЗ
  Vault-полів, трекається Passport Client Release. Без дублювання.
- Парасоля життєвого циклу = Object Passport (не ERPNext Project; Project — опційний Link на потім).
- Серійні номери — джерело правди ERPNext Serial No; монтаж/Vault/паспорт лише посилаються.
- Гарантія: Service Request → Link на ERPNext Warranty Claim.
- «Історія змін паролів» = Vault Audit Log; сервіс лише посилається (ref), без дешифрованого вмісту.
- Site Brief — окрема НЕперсональна сутність як операціоналізація мінімізації-first (H1):
  у зовнішній AI йде Brief, не паспорт. Сирі фото за замовчуванням не в AI (ai_allowed=0, H2).
- AI Estimate: field-level приховування (permlevel 1) на purchase_rate/profit/margin/total_cost —
  read лише керівник/інженер; ензфорс Frappe permission engine, не UI (H7).
- Vault-крипто: поля *_enc = Long Text (AES-256-GCM, зовнішній ключ), НЕ Frappe Password
  (його ключ у site_config). Шов під виділений Vault-процес/KMS збережено на рівні моделі.
- Vault Audit Log — єдиний глобальний hash-chain (prev_hash/record_hash), append-only,
  без update/delete-прав; опційне зовнішнє append-only сховище як друга лінія (M5).
- Access Transfer Act (H6): генерація on-demand під MFA, запис у Vault Audit Log,
  дешифровані дані матеріалізуються лише в момент доставки (не at-rest), НІКОЛИ у Drive,
  доставка захищеним каналом (TTL-посилання/друк/захищений PDF).
- Sync-метадані на DocType: name = client UUID (ідемпотентність), riad_version (серверна
  монотонна), riad_deleted+riad_deleted_at (tombstone). Адитивні колекції (фото/відмітки/
  серійники/точки) — union-merge за UUID; скаляри — field-level конфлікт → Sync Conflict,
  показ обох версій. Часові мітки пристроїв НЕ використовуються для вирішення. (закриває ВП №6)
- Syncable (offline): Engineer Visit, Checklist Instance, Media Asset, Installation Map(+точки),
  частково Remote Inspection (медіа). Online-only: усе Vault, AI Estimate, фінанси.
- Спец-ролі no-code: RIAD Scenario Admin (Scenario/Checklist Template), RIAD AI Admin (AI Provider/Log).
### Відкриті питання
- Гранулярність «свої об'єкти» монтажника (по customer / по призначенню / по полю команди) — Фаза 3/безпека.
- Geolocation vs план-локальні x/y для точок монтажу без GPS — Фаза 4.
- Очищення Whisper-транскрипту перед AISL (укр. NER слабкий, H1 поширюється) — Фаза 3.
- Реалізація доставки Access Transfer Act (TTL-посилання поза Drive) — Фаза 3/безпека.
- Винятковий офлайн-кеш Vault під наряд (вмикати/політика TTL+wipe) — фаза безпеки/підтвердження бізнесу.
- Зовнішнє append-only сховище аудиту (на старті чи відкладено) — фаза безпеки.
### Що це блокує / розблоковує
- РОЗБЛОКОВУЄ Фазу 3 (API+AI): визначені всі сутності, Link-зв'язки, межі custom app,
  field-level приховування, sync-контракт, Vault-потоки — є на що вішати ендпоінти й AI-адаптери.
- РОЗБЛОКОВУЄ Фазу 4 (UX): відомі екранні сутності й конфліктна модель для відображення.
- НЕ блокує нічого: дата-модель цілісна; відкриті питання — деталі реалізації наступних фаз.
-

## Фаза 3 — API-архітектура + AI-модулі — [дата]
### Прийняті рішення
- Поверхня API = лише whitelisted-методи riad.api.v1.*; авто-REST /api/resource назовні не експонується.
- Токени: access JWT (15 хв) + ротований refresh (у RIAD Device Session, reuse-detection) +
  окрема Vault session (step-up TOTP, 5 хв, Redis, web-worker only).
- JWT лише автентифікує → frappe.set_user → права ензфорсить Frappe permission engine (H7);
  claim roles — інформативний, не авторитетний.
- Уніфікований конверт {ok,data|error{code,message,request_id}}; канонічні коди; SYNC-CONFLICT і
  AI-DEGRADED — бізнес-стани в data (не транспортні помилки). Frappe PermissionError → RIAD-PERM-DENIED.
- Версіонування namespace v1 з вікном депрекації (критично для offline-Flutter).
- Sync-контракт: push(name=UUID, client_base_version, scalars, additive) → union-merge адитивних
  колекцій за _uuid (без конфлікту) / field-level конфлікт скалярів → Sync Conflict (обидві версії) /
  tombstones / ідемпотентність за UUID. Pull = дельта за СЕРВЕРНИМ watermark (opaque token);
  годинник пристрою не бере участі ні в pull, ні в resolve. Vault/AI Estimate/фінанси у pull не йдуть.
- AI: провайдер-адаптер з єдиним інтерфейсом complete()/health_check(); додати провайдера =
  адаптер + рядок AI Provider (no-code); ключі API поза БД. Failover основний→резервний→ручний(Scenario).
- Circuit Breaker — спільний стан у Redis (атомарні переходи, M9); AI Provider.health — кеш для UI.
- Анонімізація: мінімізація-first (Site Brief) — головний рубіж; NER — defense-in-depth; fail-closed;
  людський gate перед відправкою; сирі фото за замовчуванням не в AI (ai_allowed=0); лог лише
  анонімізованого payload (M10).
- Whisper-транскрипт за замовчуванням НЕ авто-в зовнішній AI — для людини; AI-структурування лише
  через інженер-сформований Site Brief (РЕЗОЛЮЦІЯ ВП №3 Фази 2).
- RQ-задачі: transcribe_media, ai_estimate_build(довгі), ai_retry, inspection_report_build;
  Redis-черга з AOF (M2). Whisper — окремий контейнер, concurrency=1, cpu/mem-ліміти (M4).
- Антикорупційний gateway (riad.erpnext_gateway) — єдина точка доступу до стандартних DocType;
  RIAD-DTO замість сирих Frappe-доків; CI-лінт на згадки ERPNext-DocType поза gateway; ізолює
  v15→v16. Межа потоку: estimate.confirm (status=підтверджено + reviewed_by) → gateway.create_quotation.
- Калькулятор: captcha + rate-limit per-IP (Redis token-bucket) + детермінований Scenario без live-AI;
  graceful-захоплення ліда; source_ip permlevel 1.
- Vault step-up MFA: дешифрування web-only під свіжою Vault-сесією; кожен доступ → Vault Audit Log
  (hash-chain). Access Transfer Act: on-demand під MFA, дані лише в памʼяті на доставку (не at-rest),
  доставка — одноразове TTL-посилання з самого сайту (НЕ Drive)/друк/захищений PDF.
### Відкриті питання
- Captcha-провайдер + конкретні пороги rate-limit (калькулятор/логін) — Фаза 4/безпека.
- Параметри Circuit Breaker під реальний трафік — підбір на staging.
- Формат/TTL одноразового посилання Акту + політика повторної генерації — фаза безпеки.
- Гранулярність «свої обʼєкти» монтажника (customer/призначення/команда) — рішення перед кодуванням API.
- Поріг синхронний vs RQ для estimate.build — підбір за латентністю.
- Бібліотека/покриття укр. NER (defense-in-depth) — не блокує (дефолт = мінімізація-first).
### Що це блокує / розблоковує
- РОЗБЛОКОВУЄ Фазу 4 (UX): визначені API-контракти, sync-протокол (включно з відображенням
  конфліктів), AI-потоки й деградації, MFA-потік Vault, перелік станів для екранів.
- РОЗБЛОКОВУЄ Фази 5–6: є контракти для оцінки складності й аналізу ризиків.
- НЕ блокує: відкриті питання — деталі реалізації/тюнінгу наступних фаз.
-

## Фаза 4 — UX-карта екранів — [дата]
### Прийняті рішення
- Три навігаційні моделі: Flutter = bottom-nav (Задачі/Обʼєкти/Vault/Синк) + FAB швидких дій;
  Next.js PWA = бічна навігація, що рендериться за ФАКТИЧНИМИ ролями (claim roles — лише підказка меню);
  публічний сайт = лінійна воронка калькулятора.
- Головний екран = realtime «Мої задачі сьогодні» (socketio+Redis) з offline-fallback на кешований
  список + лічильник pending; швидкі кнопки (лід/прорахунок/огляд/виїзд/сервіс) за правами.
- ВП №2 Фази 2 ЗАКРИТО (geolocation vs x/y): план приміщення → нормовані x/y ∈ [0..1] поверх
  base_plan_media (без GPS); територія → geo поверх OSM/MapLibre; гібрид → два шари; система
  координат точки визначається map_kind.
- Field-level у UX = рендер з відданого сервером (H7): немає поля в DTO → немає елемента в UI;
  «список монтажу» монтажника НЕ містить цін у джерелі даних (не приховування CSS); монтажник
  не має пунктів Кошториси/Аналітика/Vault-write/Акти в навігації.
- УТОЧНЕННЯ (не конфлікт): «кошторис із прихованою маржею для монтажника» з ТЗ-завдання
  реалізується як відсутність доступу монтажника до AI Estimate (RBAC Фази 2) + похідний
  ціно-вільний «Список монтажу»; permlevel 1 (purchase/profit/margin) — другий рубіж.
- AI-деградація = інформативний чип (зелений осн./жовтий рез./сірий ручний) + інлайн-банер,
  НІКОЛИ модалка чи блок дій; кнопка «Згенерувати» → «Обрати сценарій»; origin кошторису
  (AI-осн/AI-рез/ручний-сценарій) показано на чернетці. RIAD-AI-DEGRADED і RIAD-

- Каталог станів UI зафіксовано: AI-деградація, sync (applied/merged/conflict/tombstoned/
  ignored_duplicate), транскрипція/огляд (очікує/готово/ручний), MFA-required, та помилки
  (AUTH-INVALID→refresh/логін, REFRESH-REUSE→примусовий вихід, PERM-DENIED→відсутній пункт,
  VALIDATION→інлайн, RATELIMIT→мʼякий банер зі збереженням введеного, NOTFOUND, INTERNAL, offline).
- Captcha калькулятора: UX-рекомендація Cloudflare Turnstile (мінімальна фрикція); пороги — фаза безпеки.
### Відкриті питання
- Гранулярність «свої обʼєкти» монтажника (customer / призначення / команда) — рішення перед
  кодуванням API; UX готовий під будь-який варіант (списки рендеряться з відданого Frappe). НЕ вирішено мовчки.
- Конкретні пороги rate-limit (калькулятор/логін) + фінальний captcha-провайдер — фаза безпеки.
- Формат/TTL одноразового посилання Акту + політика повторної генерації — фаза безпеки.
- Винятковий офлайн-кеш Vault під наряд (H4) — якщо бізнес підтвердить, потрібен UX «викачати під
  наряд» з видимим TTL/wipe; наразі online-only.
- Фінальні дизайн-токени (палітра, типографічна шкала, конкретні компоненти) — етап дизайну/прототипу.
### Що це блокує / розблоковує
- РОЗБЛОКОВУЄ Фазу 5 (план + оцінка складності): визначені всі екрани, флоу, навігація, стани й
  UI-стек — є повний обсяг робіт для оцінки по поверхнях і модулях.
- РОЗБЛОКОВУЄ Фазу 6 (ризики): видимі UX-залежності (offline-конфлікти, Vault online-only,
  AI-деградація) для аналізу ризиків.
- НЕ блокує нічого: відкриті питання — тюнінг безпеки/дизайну, не архітектура.
-

## Фаза 5 — План розробки + оцінка складності — [дата]
### Прийняті рішення
- Декомпозиція на 10 етапів E0–E9 (вертикальні зрізи, не шари): E0 інфра/DevOps →
  E1 custom app+20 DocType+RBAC+gateway(read) → E2 auth+API-каркас →
  E3 MVP-зріз (Лід→Site Brief→Паспорт, online) → E4 offline-sync+Flutter →
  E5 AISL+анонімізація+Whisper+Builder→ERPNext → E6 Vault+MFA+hash-chain+Акт →
  E7 публічний калькулятор → E8 push(FCM)+сервіс → E9 безпека+DR.
- Спинний хребет послідовний: E0→E1→E2→E3. Критичний шлях: E0→E1→E2→E3→E5→E7→E9.
- Складність за відносною шкалою 1–5. Вузли складності 5: E4 (offline-sync H3),
  E5 (AI-failover M9 + анонімізація fail-closed H1/H2), E6 (Vault-крипто+ізоляція C1/H6).
  Складність 4: E1 (адаптер M3), E2 (межа JWT↔Frappe H7), E9 (key-escrow+DR).
- MVP-кістяк = E0+E1+E2+E3 (демо онлайн до важких вузлів — рання валідація архітектури).
- E6 (Vault) залежить лише від E2 → виноситься з критичного шляху на паралель.
  E4 і E5 контрактно незалежні (перетин лише: E4 дає Drive-ID медіа, E5 — транскрипцію).
- Керований порядок важких вузлів за обмеженого паралелізму: E6 рано-паралельно →
  E5 (на крит. шляху) → E4 (найскладніший польовий, не блокує E7).
- DoD кожного етапу = перевірюваний інваріант контракту (не «зроблено»):
  напр. E4 — повторний push ідемпотентний + скаляр-конфлікт без тихого перезапису;
  E6 — import-linter доводить відсутність шляху Vault→AI; E5 — кошторис у ERPNext лише з reviewed_by.
- Прив'язка відкритих питань безпеки до етапів (КОЛИ закрити, не ЯК):
  key-escrow C2 → гейт перед production E6, операціоналізація E9;
  пороги rate-limit+captcha → дефолт E7, фінал E9;
  офлайн-кеш Vault H4 → рішення бізнесу до старту E6 (дефолт online-only).
### Відкриті питання
- Розмір/структура команди (ФОП → ймовірно обмежений паралелізм) — впливає на КАЛЕНДАР і
  реальну паралель E6‖E4/E5, НЕ на оцінки складності. → планування ресурсів / Фаза 6.
- Поріг «синхронно vs RQ» для estimate.build — підбір за латентністю на staging (E5).
- Гранулярність row-level «свої об'єкти» монтажника — зафіксувати до фінального row-level у E4.
### Що це блокує / розблоковує
- РОЗБЛОКОВУЄ Фазу 6 (ризики+масштабування+аудит): є етапи, залежності, критичний шлях,
  концентрація ризику (E4/E5/E6) і прив'язка безпекових питань — основа для матриці ризиків.
- НЕ блокує: відкриті питання — календарні/ресурсні уточнення, не архітектура.
-

### Фаза 6 — Ризики + масштабування + фінальний аудит — [дата]
### Прийняті рішення
- Реєстр ризиків зафіксовано: кожен вузол аудиту (C1, C2, H1–H7, M1–M10, L1–L3) має
  ймовірність×вплив, тригери, ранню ознаку, мітигацію і ЕТАП-ВЛАСНИКА (де матеріалізується/
  закривається). Ризик без етапу-власника не допускається.
- Два свідомо прийнятих залишкових ризики (не пропуски): C1 → «code-level» = механічно
  ензфорсена конвенція (Варіант A, import-linter gate), не фізичний бар'єр, шов під Варіант B/KMS
  збережено; M7 → транскордонне зберігання медіа (anon ≠ data-residency) у реєстрі під майбутню
  відповідність.
- Один гейт ПЕРЕД PRODUCTION (не перед стартом): key-escrow C2 — жодних реальних Vault-секретів
  у прод без escrow-процедури (проєктування на старті E6, операціоналізація E9).
- Ризики строків концентруються на E4/E5/E6 (усі складність 5); фактичну тривалість визначає
  найповільніший із трьох, не довжина ланцюга. Стримування: ранній MVP-кістяк E0–E3 + винос E6
  на паралель + DoD-інваріанти. Календарна величина залежить від розміру команди (див. ВП).
- Масштабування: throughput БД — НЕ вузьке місце. Реальний тиск — обсяг медіа, пропускна
  здатність Whisper/воркерів, доступність-SPOF одного сервера (M1), вартість AI. План виносу:
  Whisper на окрему машину (кандидат №1) → HA read-репліка MariaDB → binlog PITR (RPO≈0, вже E0).
  Усі кроки — горизонтальний винос компонентів, БЕЗ зміни парадигми «один Frappe-сайт + custom app».
- Аудит готовності: 10/10 принципів конституції задоволені проєктно (5 і 6 — зі свідомо прийнятими
  трактуваннями C1/M7); усі резолюції аудиту Фази 1.5 прив'язані до етапів.
- Definition of Ready для E0 зафіксовано: обов'язкові пункти (10 принципів, резолюції 1.5,
  узгоджені документи 01–05+ТЗ, рішення Конфліктів #1/#2, наявне розгортання ERPNext v15,
  прийнятий реєстр ризиків) — усі ✅ на момент завершення Фази 6.
### Відкриті питання
- Розмір/структура команди → визначає календар і реальну паралель E6‖E4/E5 (не архітектуру).
  Потрібне для планування строків; НЕ блокує E0.
- Механізм key-escrow C2 (де/як резерв ключа окремо від бекапу БД) → гейт перед прод E6.
- Гранулярність «свої об'єкти» монтажника → перед row-level у E4.
- Рішення про винятковий офлайн-кеш Vault (H4) → рішення бізнесу до старту E6 (дефолт online-only).
- Пороги rate-limit + captcha-провайдер → дефолт E7, фінал E9.
- Поріг estimate.build синхронно vs RQ → staging під час E5.
- Зовнішнє append-only сховище аудиту (M5, друга лінія) → рішення E9.
- M7: які класи медіа взагалі мусять покидати периметр → перегляд у фазі безпеки.
### Що це блокує / розблоковує
- РОЗБЛОКОВУЄ старт кодування з E0: проєктування завершене, усі ризики мають етап-власника,
  DoR-обов'язкові пункти ✅, блокерів для E0 немає.
- НЕ блокує E0 жодне відкрите питання — усі прив'язані до пізніших гейтів (E4/E5/E6/E7/E9).
- ЗАВЕРШУЄ фазу проєктування. Наступний крок — не нова фаза проєктування, а реалізація E0
  за планом Фази 5.
-

## Узгодження з наявним кодом (Security ERP Platform) — НАПРЯМ B — [дата]
### Контекст
Аудит docs/00_reconciliation_audit.md показав на диску систему з іншою архітектурою.
Власник обрав B — лишити FastAPI-гейтвей, оновити дизайн під нього.
### Прийняті рішення (переглядають фіксації Фаз 1 і 3)
- ВІСЬ 1 (API): RIAD API = окремий FastAPI-сервіс (security-api) перед Frappe. Скасовує рішення
  Фази 1 «in-process без HTTP-хопу». Свідомо приймаємо два процеси і дві транзакційні межі.
- ВІСЬ 2 (права/БЕЗПЕКА): FastAPI автентифікується до Frappe ВІД ІМЕНІ РЕАЛЬНОГО КОРИСТУВАЧА,
  НЕ від Administrator. Frappe permission engine — авторитетний ензфорсер (permlevel, row-level).
  RBAC-словник FastAPI = грубий перший фільтр, не джерело правди. «Admin на все» скасовано. (зберігає H7)
- ВІСЬ 3 (дата-модель): union — 11 наявних доменних DocType + 15 відсутніх спроєктованих +
  узгодження 3 перетинів. Розширює Фазу 2 (було «20 DocType»).
- ВІСЬ 4 (gateway): антикорупційний шар = типізовані /api/v2/* (RIAD-DTO). Catch-all /api/v1/* депрекується.
- ВІСЬ 5 (AI): прямий anthropic-виклик обгортається провайдер-агностичним адаптером + Circuit Breaker
  (Redis) + анонімізацією fail-closed. Сирий текст у зовнішній AI — заборонено.
- ВІСЬ 6 (відсутнє): Vault, анонімізація, мультипровайдер+failover, Whisper, offline-sync, Next.js PWA,
  RIAD Device Session, калькулятор — будуються за дизайном, інтегруються до FastAPI.
- ВІСЬ 6-Vault (ІЗОЛЯЦІЯ): крипто-ядро Vault НЕ в процесі з AI-клієнтом. Дефолт — Vault як in-process
  Frappe-модуль/воркер. Скасовує припущення «весь шар у FastAPI». (зберігає принцип 5 / C1)
- ВІСЬ 7 (namespace): app лишається security_erp; «RIAD» — бренд; API = FastAPI /api/v2/*.
### Відкриті питання
- Механізм per-user авторизації до Frappe: кешована сесія per-user (реком.) vs per-user API-ключі → E2.
- Розміщення Vault: in-process Frappe-модуль (реком.) vs окремий Vault-сервіс → E6.
- Сага/ідемпотентність для мультизаписів через HTTP-межу (estimate.confirm, sync.push, Vault write+audit).
### Що розблоковує / блокує
- Розблоковує: переписати 28-пунктовий план під B.
- Блокує до фіксу: будь-яка робота з правами/Vault/AI поверх «admin-на-все» — спершу вісь 2.
## Узгодження з наявним кодом (Security ERP Platform) — НАПРЯМ B1 — [дата]
### Контекст
Аудит docs/00_reconciliation_audit.md. Власник: B1 (FastAPI лишається, per-user делегування,
а не Administrator-обхід; B2 відхилено через дублювання моделі безпеки і ризик витоку).

### Прийняті рішення (переглядають фіксації Фаз 1 і 3)
- ВІСЬ 1 (API): RIAD API = FastAPI-гейтвей (security-api) перед Frappe. Скасовує рішення
  Фази 1 «in-process без HTTP-хопу». Свідомо приймаємо два процеси, дві транзакційні межі.
- ВІСЬ 2 (права/БЕЗПЕКА) — B1: FastAPI автентифікується до Frappe ВІД ІМЕНІ РЕАЛЬНОГО
  КОРИСТУВАЧА (делегована сесія або персональний API-ключ), НЕ від Administrator.
  Frappe permission engine лишається авторитетним ензфорсером (permlevel, row-level
  через User Permission). FastAPI-RBAC (`ROLE_PERMISSIONS`) — грубий перший фільтр,
  не джерело правди. B2 (переписати модель прав у Python) — відхилено: дублювання
  безпекової моделі ERPNext + ризик розсинхрону = ризик витоку. Роль при логіні —
  з реального Frappe User.roles, без хардкоду `_default_role()`.
- ВІСЬ 3 (дата-модель): union — 11 наявних доменних DocType + 15 відсутніх спроєктованих +
  узгодження 3 перетинів (security_scenario→Scenario; estimate→AI Estimate з origin/
  reviewed_by/permlevel; visit→Engineer Visit з sync-метаданими). Розширює Фазу 2.
  `warranty_letter` ≠ `Access Transfer Act` (різне призначення, конфлікт назв) — Access
  Transfer Act створюється окремо в Vault-неймспейсі.
- ВІСЬ 4 (gateway): /api/v1 (proxy.py) лишається задокументованим legacy (X-Deprecated).
  Увесь новий код — типізовані /api/v2/* з Pydantic-DTO як ACL-шар (антикорупційний адаптер
  у дусі дизайну, реалізований через HTTP, не in-process).
- ВІСЬ 5 (AI): прямий anthropic-виклик обгортається провайдер-агностичним адаптером +
  Circuit Breaker (Redis) + анонімізацією fail-closed. Сирий текст ТЗ напряму в AI — заборонено.
- ВІСЬ 6 (Vault — ІЗОЛЯЦІЯ, ключове рішення): Password Vault виноситься з AI-контуру.
  Реалізується як ОКРЕМИЙ МОДУЛЬ ERPNext/Frappe (in-process, поза FastAPI-AI-процесом) з
  власним шифруванням (AES-256-GCM пополе, ключ поза БД), власним hash-chain аудитом і
  контролем доступу (MFA). AI-сервіси та RQ/AI-воркери НЕ МАЮТЬ доступу до секретів,
  логінів, паролів і ключового контексту об'єктів — ні мережево, ні на рівні імпортів.
  CI import-linter (чи еквівалент для Python-модулів security-api) доводить відсутність шляху.
- ВІСЬ 6 (інше відсутнє): анонімізація, мультипровайдер+failover, Whisper, offline-sync,
  Next.js PWA, RIAD Device Session (формалізувати — Redis blacklist є, DocType-еквівалент
  додати), калькулятор — будуються за дизайном, інтегруються через FastAPI v2 + per-user
  делегування до Frappe.
- ВІСЬ 7 (namespace): app лишається `security_erp` (прод уже на riad.fun, рейнеймінг —
  зайвий ризик); «RIAD» — бренд/UI-назва, не код-namespace.

### Відкриті питання
- Точний механізм per-user делегування: кешована Frappe-сесія per-user vs персональні
  API-ключі (`token KEY:SECRET`) per user → вирішується технічно в сесії R1.
- Розміщення меж Vault-модуля всередині security_erp app: окремий Python-підпакет
  з власним hooks-ізоляцією → сесія R-Vault-1.
- Сага/ідемпотентність для багатокрокових операцій через HTTP-межу (estimate.confirm,
  sync.push, Vault write+audit) — технічне рішення в E2/E6-сесіях.

### Що це розблоковує / блокує
- Розблоковує: переписаний build playbook під B1 (стабілізація наявного → нарощування).
- Блокує до фіксу: будь-яка робота з Vault/AI/правами — спершу R1 (per-user делегування).



## V4 — Access Transfer Act + Vault UI — 2026-06-22

### Прийняті рішення
- `act.generate` (під MFA) → Redis: `act:tok:{token}` + `act:otp:{sha256}` + `act:act_to_tok:{act_name}`, TTL=86400s; MariaDB зберігає лише `sha256(token)`.
- Регенерація з відкритим попереднім актом: revoke через `act:act_to_tok:{act_name}` → atomic delete; якщо ключ вже протух — graceful skip (токен вже інвалідний сам по собі).
- `act.serve` не спалює токен — клієнт може переглянути кілька разів до acknowledge.
- `act.acknowledge` → atomic delete трьох Redis-ключів + `link_burned=1` + `client_acknowledged=1`.
- Публічні ендпоінти `/api/v2/act/public/*` — без JWT; аутентифікація через opaque token (64 hex) + OTP hash. OTP brute-force: прийнятий ризик — token_hex 64 символи = 256-bit primary secret; OTP = second factor. Rate-limit відкладено до H2.
- `get_meta` повертає whitelist-поля (act_name, passport, customer, generated_at, expires_at, entry_count, link_burned) — без delivery_token, generated_by, audit_ref.
- `Vault Audit Log.action` розширено: додано `act_revoke`, `act_view`, `act_acknowledge` до Select-поля (bench migrate).
- `access_transfer_act.js` (ERPNext desk): confirm dialog при регенерації; OTP показується лише в момент генерації і більше недоступний.
- Gate C2 задокументовано в BUILD_LOG: реальні Vault-секрети в production — лише після H1 (key-escrow + DR-runbook).
- CI vault isolation linter (V2) зелений після додавання `act.py`.

### Відкриті питання
- Rate-limit публічного OTP-ендпоінту — H2 (прийнятий trade-off, задокументовано).
- H1 key-escrow процедура — блокує реальні секрети в prod.

### Що це блокує / розблоковує
- ✅ ЗАВЕРШУЄ V-трек (V1→V4).
- РОЗБЛОКОВУЄ P1 (Push) — V4 є передумовою.
- НЕ блокує A1 (AI-трек) — він залежить від R4, який виконано.
- ЗАБЛОКОВАНО: реальні паролі в Vault до H1.

---

## FIX-5 — R4 Rate Limit + R2 Ukrainian Roles + CI — 2026-06-23

### Прийняті рішення

- **R4 (rate limiting)**: `check_rate_limit` (sliding window, Redis sorted set) підключений до обох ендпоінтів через `_enforce_rate_limit()`: `/login` — ключ `rl:login:{client_ip}`, max=5/window=900; `/refresh` — ключ `rl:refresh:{user_id}`, max=30/window=900. Ліміти прийнято як дефолт E7; фінальне тюнінгування — E9 (DECISIONS ВП Фаза 4, закрито за замовчуванням). Prefix `rl:` у ключах — namespace-конвенція для rate-limit ключів у Redis (відрізняє від `rt:`, `frappe:`, `act:`).
- **R2 (українські ролі)**: всі 4 назви (`Технік`/`Директор`/`Бухгалтер`/`Склад`) вже були присутні в `_map_frappe_role_from_names()`. Пріоритет ролей: System Manager > Service Manager > Sales Manager > Projects Manager > HR Manager > Engineer/Технік > Директор > Бухгалтер > Склад > viewer. Директор навмисно нижче Engineer — якщо директор також технік, пріоритет у технічної ролі (бізнес-рішення за замовчуванням; змінити переставивши рядки якщо потрібно).
- **CI gate стратегія**: замість тестів з реальним Redis — grep gate (перевіряє наявність виклику в коді) + unit тест (мокує `check_rate_limit` → перевіряє логіку `_enforce_rate_limit`). Це дозволяє CI-кроку проходити без запущеного Redis. Реальний інтеграційний тест — staging/E9.
- **`prometheus-client` в requirements-test.txt**: виправлена pre-existing відсутня залежність. Пакет потрібен `app/main.py` (metrics endpoint); без нього r3 tearDown crashував при `from app.main import app`.

### Відкриті питання

- Фінальні пороги rate-limit (login/refresh) — E9 (staging tuning, не блокує).
- Реальний інтеграційний тест rate-limit (реальний Redis, 6 запитів підряд) — staging/E9.

### Що це блокує / розблоковує

- ✅ ЗАКРИВАЄ 🟡 HIGH FIX-5 (R4+R2+CI з BUILD_LOG/FIX_PLAN).
- РОЗБЛОКОВУЄ FIX-6 (gateway discipline refactor) — FIX-5 не має залежностей від нього.
- НЕ блокує нічого: усі зміни точкові, незалежні.

---

## FIX-3 — AI Estimate DocType: R6-поля + permlevel=1 — 2026-06-23

### Прийняті рішення

- **DocType rename**: `"Estimate"` → `"AI Estimate"` (виконує DECISIONS B1 Вісь 3); дитячий `"Estimate Item"` → `"AI Estimate Item"`. Фізичні файли збережено на місці; `controller` поле зафіксовує Python шлях.
- **permlevel=1** встановлено на полях чутливих даних: `reviewed_by`, `reviewed_at`, `total_cost`, `total_margin` (AI Estimate); `purchase_rate`, `profit`, `margin_pct` (AI Estimate Item). Ензфорс через Frappe permission engine (H7, DECISIONS B1 Вісь 2).
- **permlevel=1 grants**: System Manager + Sales Manager → read/write permlevel=1. Service Manager (монтажник) — лише permlevel=0 (read). Реалізує «кошторис з прихованою маржею».
- **Нові поля**: `origin` (manual/ai/imported), `variant`, `line_source` (manual/catalog/ai) — permlevel=0; доступні всім ролям.
- **calculate_totals()** розширено: обчислює `total_cost`, `total_margin`, `item.profit`, `item.margin_pct` на підставі `purchase_rate`. Дані з'являються лише якщо `purchase_rate` заповнено.
- **TDD**: 16 pytest тестів написано ДО змін (RED → GREEN); тести перевіряють JSON-схему без Frappe runtime.

### Відкриті питання

- `bench migrate` потребує running ERPNext container — виконати після деплою.
- Runtime permlevel verification (`GET /api/resource/AI Estimate/{name}` від Service Manager) — після `bench migrate`.
- `tabEstimate` та `tabEstimate Item` залишаться як orphan таблиці після rename; очистити при наступному DB maintenance.

### Що це блокує / розблоковує

- ✅ ЗАКРИВАЄ 🔴 CRITICAL FIX-3 (R6 estimate fields+permlevel).
- РОЗБЛОКОВУЄ FIX-4 (A3/A4 AI task fixes) — поля `origin`, `reviewed_by` тепер існують.
- НЕ блокує нічого: відкриті питання — операційні (migrate/verify), не архітектурні.

---

## FIX-4 — A3/A4 AI Task Bugs: enqueue_ai_estimate + is_enabled + transcription_status — 2026-06-23

### Прийняті рішення

- **Bug A (enqueue_ai_estimate):** `enqueue_ai_estimate` реалізовано як `@frappe.whitelist()` обгортка над `frappe.enqueue("...run_ai_estimate", ...)`. `site_brief` і `variant` приймаються для API-сумісності (estimate_service.py передає їх), але не пересилаються до `run_ai_estimate` — той читає дані безпосередньо з Frappe DocType. Патерн: whitelist entrypoint → RQ job (роздільна відповідальність).
- **Bug B (is_enabled):** фільтр `{"is_active": 1}` → `{"is_enabled": 1}` відповідно до `ai_provider.json`. `import redis` перенесено в тіло `_get_redis_sync()` (lazy import) — redis недоступний у CI/тест-оточенні поза Docker.
- **Bug C (transcription_status):** опції уніфіковано з семантикою станів pipeline: `pending` (черга/retry) → `processing` (активна робота) → `done` або `failed`. Видалено `"none"` і `"manual"` — не є станами транскрипції. `transcribe.py` оновлено: `"manual"` → `"failed"`, початковий `"pending"` → `"processing"`. Вимагає `bench migrate` після деплою.
- **TDD:** 14 тестів написано ДО змін (RED), зелені після (GREEN). Існуючий `test_a3_tasks.py` виправлено: redis mock + `whitelist` ідентичний декоратор, `TestAIEstimateBuild` → тестує реальний API (`run_ai_estimate` / `enqueue_ai_estimate`).

### Відкриті питання

- `bench migrate` для `media_asset.json` changes — виконати після деплою.

### Що це блокує / розблоковує

- ✅ ЗАКРИВАЄ 🔴 CRITICAL FIX-4 (A3/A4 AI task runtime crashes).
- РОЗБЛОКОВУЄ FIX-5 (R4 rate limit + R2 roles + CI) — немає залежностей від FIX-4.
- НЕ блокує нічого: всі зміни точкові, незалежні від інших трек.

---

## FIX-6 — Gateway discipline: visits + warehouse service layer — 2026-06-23

### Прийняті рішення

- **Ітерація 1 (visits + warehouse):** Логіку `visits.py` винесено у `app/services/visit_service.py`; логіку `warehouse.py` — у `app/services/warehouse_service.py`. Маршрути викликають сервіс, сервіс викликає `frappe_*` з `sid=` (B1 per-user делегування). Нуль прямих `frappe_get/post/put` у routes після рефакторингу.
- **Сервісний контракт:** `start_visit`, `finish_visit`, `add_material`, `upload_photo` — keyword-only args + `sid: str`. `list_serials`, `list_stock`, `stock_detail` — аналогічно. Повертають plain dict; FastAPI конвертує у response_model автоматично.
- **Error mapping:** `_map_frappe_error` (httpx → HTTPException) залишено в route-шарі — це HTTP-концерн, не бізнес-логіка.
- **`_unwrap` helper** переміщено в `warehouse_service.py` — тепер private функція сервісу.
- **Gateway discipline test:** `tests/fix6/test_fix6_gateway_discipline.py` — 9 тестів (4 visit, 3 warehouse, 2 grep-gate). Grep-gate: `assertNotIn("frappe_get/post/put", route_content)` — CI-доказ дисципліни без live Frappe.
- **s4 patch target update:** `TestWarehouseSerials` і `TestWarehouseStock` у `tests/s4/test_s4_gateway.py` перепатчено з `app.routes.warehouse.frappe_get` → `app.services.warehouse_service.frappe_get`.
- **TDD:** 9 тестів написано ДО впровадження (9 FAIL), сервіси реалізовано → 7 GREEN, потім route refactor → 9/9 GREEN.

- **Ітерація 2 (maps + media + ai_admin):** `maps.py` → `map_service.py` (union-merge логіка + mode validation → `ValueError`); `media.py` → `media_service.py`; `ai_admin.py` → `ai_admin_service.py`. Контракт той самий: keyword-only `sid: str`, plain dict/str повернення, HTTP-шар у route.
- **map_service.add_mount_point** кидає `ValueError` (не HTTPException) для mode-validation — route перехоплює і конвертує у 422. Це правильне розділення: сервіс не знає HTTP.
- **media_service.upsert_media_asset** try/except на GET: будь-який Exception (404 або network) → POST (create). Зберігає існуючу семантику з route.
- **ai_admin_service:** роль-check (`_require_ai_admin`) залишено в route — це авторизаційний HTTP-концерн, не бізнес-логіка сервісу.
- **s4 patch targets for maps:** `app.routes.maps.frappe_get/put` → `app.services.map_service.frappe_get/put`.
- **TDD дотримано:** 15 нових тестів написано ДО реалізації (15 FAIL RED), сервіси + route refactor → 31/31 GREEN.

### Наступні ітерації FIX-6

~~Ітерація 3 (фінальний CI-лінт)~~ → ВИКОНАНО (Ітерація 3).

### Відкриті питання FIX-6 (ЗАКРИТО)

- `act.py` / `vault.py` — не чіпаємо (vault ізоляція, окремий трек) — ✅ CONFIRMED: excluded із перевірки
- `ai.py` — verified: лише 1 `frappe_post` до whitelist → `[OK]` у check_gateway_discipline.py

### Що це блокує / розблоковує

- ✅ ЗАКРИВАЄ 🟡 HIGH FIX-6 Ітерація 1 (visits + warehouse gateway discipline).
- ✅ ЗАКРИВАЄ FIX-6 Ітерація 2 (maps + media + ai_admin gateway discipline).
- ✅ ЗАКРИВАЄ FIX-6 Ітерація 3 (CI-лінт `check_gateway_discipline.py`).
- ✅ **FIX-6 ПОВНІСТЮ ЗАКРИТО** — всі route файли або перенесені на service-шар,
  або задокументовані як excluded/KNOWN_PENDING; regression guard активний у CI.
- РОЗБЛОКОВУЄ **FIX-7** (serial.py + scenarios.py рефакторинг) — не блокує нічого іншого.
- НЕ блокує нічого: рефакторинг точковий, поведінка API незмінна.

---

## FIX-7 — Gateway discipline: serial.py + scenarios.py (PENDING)

### Контекст

FIX-6 Ітерація 3 задокументувала `serial.py` і `scenarios.py` як `KNOWN_PENDING`.
`check_gateway_discipline.py` репортить їх як `[TODO]` і НЕ блокує CI зараз.

### Що потрібно зробити

- **serial.py** (`/api/v2/serial/record`) → `app/services/serial_service.py`
  - 1 виклик: `frappe_post("/api/method/security_erp.serial_scan.record_serial_scan", data=data, sid=sid)`
  - Зазначення: це вже thin proxy до Frappe @whitelist (аналогічно `ai.py`). Можливо, FIX-7 лише підтвердить виключення замість рефакторингу.
- **scenarios.py** (`/api/v2/scenarios/*`) → `app/services/scenario_service.py`
  - 4+ виклики: frappe_get/post/put для CRUD Scenario + Scenario Item

### Що блокує

- Нічого — FIX-7 не є критичним; `check_gateway_discipline.py` слідкує за регресіями.

### Відкриті питання

- `serial.py` — `frappe_post` до @whitelist: чи виключити аналогічно `ai.py` або рефакторити?
  Рішення до старту FIX-7.

---

## FIX-2 — Vault крипто-ядро переписано з нуля — 2026-06-23

### Контекст
Аудит показав: source files `_key.py`, `_crypto.py`, `_hooks.py`, `api.py`, `audit.py`, `mfa.py` відсутні
(є лише `.pyc`). `vault_entry.py:7` → `ImportError` → система крашить при кожному `VaultEntry.save()`.

### Прийняті рішення (підтверджують і конкретизують Фазу 2 / Вісь 6)
- Усі зафіксовані рішення DECISIONS.md дотримано без змін.
- **Wire format шифрування:** `"v1:{base64_nonce}:{base64_ct}:{base64_tag}"` — версійований префікс `v1:`, 12-byte nonce (GCM standard), 16-byte auth tag (AESGCM authed encryption).
- **Sentinel `v1:`** дозволяє детектувати зашифровані значення через `_is_encrypted()` без спроби декрипту.
- **`get_master_key()`** приймає hex (64 символи) або base64 (44 символи) — зручніший ввід без зміни безпеки.
- **`append_audit_log(action, vault_entry, field_touched, user, session_id, ip, passport)`** — повна сигнатура для `act.py` та `api.py`; `log_action(action, doc_name, user, meta)` — спрощений публічний wrapper.
- **hash-chain**: `record_hash = sha256("\x00".join([prev_hash, action, user, ts, vault_entry, field_touched]))` — роздільник `\x00` запобігає length-extension атакам між полями.
- **`verify_chain(limit)`** — окрема функція для аудиторів/DR (не в hot path).
- **`vault_mfa_verify`** — @frappe.whitelist, перевіряє TOTP, створює Redis vault-session (TTL=300s), повертає токен.
- **`vault_set`** встановлює `ve.flags.ignore_before_save = True` коли значення вже зашифровані — уникає подвійного шифрування при API-виклику.
- **CI gate**: `V2 Vault isolation lint` + `V2 Vault crypto tests` (36 pytest) додані в `ci.yml`.

### Відкриті питання
- H1 key-escrow: реальні Vault-секрети в prod заблоковані до key-escrow процедури (Gate C2, незмінно).
- Rate-limit OTP-ендпоінту act — H2 (з V4, незмінно).

### Що це блокує / розблоковує
- ✅ ЗАКРИВАЄ 🔴 CRITICAL "System crash при VaultEntry.save()" (FIX-2 з FIX_PLAN.md).
- РОЗБЛОКОВУЄ FIX-4 (A3/A4 AI task fixes) — runtime Vault доступний.
- ЗАБЛОКОВАНО (без змін): реальні prod-секрети до H1.

---

## FIX-7 — R5 Durability: MariaDB binlog + Redis AOF + backup pipeline — 2026-06-23

### Прийняті рішення

- **MariaDB binlog (R5-FIX-1):** `configs/mariadb.cnf` розширено — `log_bin=ON`, `binlog_format=ROW`, `sync_binlog=1`, `expire_logs_days=7`, `max_binlog_size=100M`. Рестарт контейнера застосував зміни. PITR тепер активний: `mariadb-bin.000001` на диску.
- **Redis AOF (R5-FIX-2):** Створено `configs/redis.conf` (`appendonly yes`, `appendfsync everysec`). `docker-compose.yml` — redis-сервіс отримав volume-mount конфігу та `command: redis-server ...`. Рекреація (`docker compose up -d redis`) — AOF активний, `appendonlydir/` існує.
- **Backup pipeline (R5-FIX-4/5):** Виправлено у попередній сесії — правильне ім'я контейнера, `--databases`, env-завантаження. Cron активний. Ручна копія (перша дія FIX-7): 3.2MB, exit 0.
- **R5-FIX-3 (GPG):** Відкладено — потребує GPG-ключа та key management. Архітектура зафіксована (R5 BUILD_LOG). Реалізувати разом з H1/C2 gate (key-escrow процедура).
- **`docker compose restart` vs `up -d`:** Урок — `restart` не рекреює контейнер, не застосовує нові volumes/команди. Для змін docker-compose.yml потрібен `docker compose up -d <service>`.

### Відкриті питання

- R5-FIX-3: GPG-шифрування бекапів — при налаштуванні key management (вʼязано з H1/C2).
- mysqlbinlog PITR drill — перевірити відновлення на конкретну точку в часі (staging/E9).

### Що це блокує / розблоковує

- ✅ ЗАКРИВАЄ 🔴 CRITICAL R5-FIX-4 (backup pipeline зламаний).
- ✅ ЗАКРИВАЄ 🟡 HIGH R5-FIX-1 (binlog) та R5-FIX-2 (Redis AOF).
- ✅ ЗАКРИВАЄ FIX-7 (FIX_PLAN.md).
- ЗАЛИШАЄТЬСЯ ВІДКРИТИМ: R5-FIX-3 (GPG), PITR drill.
