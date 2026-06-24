# Промти для виправлення багів (Аудит A2-A4/S2-S4)

**Дата:** 2026-06-23
**Джерело:** `docs/audit/fix_plan.md`
**Порядок виконання:** 2.1 → 2.2 → 2.7 → 2.5 → 2.3 → 2.4 → 2.6 → 2.8
**Загальний лог виправлень:** `docs/audit/fix_log.md`

---

## ЗАГАЛЬНІ ВИМОГИ ДЛЯ КОЖНОГО ПРОМТУ

1. **Прочитай базу знань ПЕРЕД початком роботи:**
   - `CLAUDE.md` — конституція проекту (правила якості, архітектура, стек)
   - `docs/audit/fix_plan.md` — план виправлень (знахідки, гіпотези, верифікація)
   - Конкретний `docs/audit/block_N_report.md` для поточного завдання

2. **Одне завдання за раз.** Не починай наступне поки поточне не завершено і не записано в лог.

3. **TDD:** Спочату тест → побачити що падає → написати код → побачити що зеленить.

4. **Один файл за раз.** Написати → перевірити (компілюється, логіка вірна) → наступний.

5. **Запис у `docs/audit/fix_log.md`** після кожного кроку:
   ```
   ## Крок X.Y: [назва]
   **Статус:** ВИКОНАНО / ЧАСТКОВО / ЗАБЛОКОВАНО
   **Змінені файли:** [список]
   **Що зроблено:** [опис]
   **Верифікація:** [результат перевірки]
   **Час:** [хвилин]
   ```

6. **Не генерувати болванку.** Якщо не впевнений у деталях — написати "потребує уточнення".

7. **Перевірка реальності.** Код має враховувати реальну структуру відповіді Frappe REST API.

---

## ПРОМТ 1: Крок 2.1 — Видалити dead code (знахідка 4)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_2_report.md.

ЗАВДАННЯ: Видалити 5 dead code файлів, які ніким не імпортуються.

ФАЙЛИ ДЛЯ ВИДАЛЕННЯ:
- services/security-api/app/services/ai_service.py
- services/security-api/app/services/admin_service.py
- services/security-api/app/services/media_service.py
- services/security-api/app/services/scenario_service.py
- services/security-api/app/schemas/admin.py

КРОКИ:
1. Для КОЖНОГО файлу виконай grep -r "from app.services.{name}" services/security-api/ та grep -r "from app.schemas.admin" services/security-api/ щоб підтвердити 0 імпортів.
2. Якщо grep знаходить імпорти — НЕ ВИДАЛЯЙ цей файл, запиши в лог що файл використовується.
3. Якщо 0 імпортів — видали файл.
4. Після видалення: запусти python -m py_compile на кожному сусідньому файлі щоб переконатись що нічого не зламано.

ВЕРИФІКАЦІЯ:
- grep -r "from app.services.scenario_service" services/ → 0 результатів
- grep -r "from app.services.media_service" services/ → 0 результатів
- grep -r "from app.services.admin_service" services/ → 0 результатів
- grep -r "from app.services.ai_service" services/ → 0 результатів (або є імпорти — тоді не видаляти)
- grep -r "from app.schemas.admin" services/ → 0 результатів
- python -m py_compile на всіх .py файлах в services/security-api/app/ → OK

ЗАПИШИ результат у docs/audit/fix_log.md (створи файл якщо не існує).
```

---

## ПРОМТ 2: Крок 2.2 — Виправити _set_status("error") (знахідка 8)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_3_report.md (§3.3).

ЗАВДАННЯ: Замінити _set_status("error") на _set_status("manual") в transcribe.py.

ФАЙЛ: erpnext/security_erp/security_erp/tasks/transcribe.py

ПРОБЛЕМА: _set_status(doc, "error") — значення "error" не входить до Select options Media Asset.transcription_status (options: none|pending|done|manual). Код використовує db_set (bypasses validation), тому значення записується в БД, але UI-фільтр не показує його коректно.

КРОКИ:
1. Прочитай файл повністю.
2. Знайди всі виклики _set_status(doc, "error") — їх має бути 2 (рядки ~66 та ~85).
3. Заміни кожен на _set_status(doc, "manual").
4. Перевірь що "manual" — існуючий Select option в Media Asset.transcription_status.
5. py_compile на файлі.

ДОДАТКОВО (міграція існуючих записів):
- Запиши в fix_log.md SQL-запит для міграції: UPDATE `tabMedia Asset` SET transcription_status = 'manual' WHERE transcription_status = 'error';
- Цей запит потрібно буде виконати через bench --site erp.localhost mariadb

ВЕРИФІКАЦІЯ:
- grep "error" erpnext/security_erp/security_erp/tasks/transcribe.py → 0 результатів (в контексті _set_status)
- grep '_set_status(doc, "manual")' erpnext/security_erp/security_erp/tasks/transcribe.py → 2 результати
- python -m py_compile erpnext/security_erp/security_erp/tasks/transcribe.py → OK

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ПРОМТ 3: Крок 2.7 — Видалити unused imports (знахідки 11+12)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_2_report.md (§4) та block_4_report.md (§4).

ЗАВДАННЯ: Видалити невикористані імпорти з 2 файлів + 2 додаткових знайдених під час аудиту.

ФАЙЛИ ТА ЗМІНИ:

1. services/security-api/app/routes/banking.py
   - Рядок 2: видалити "import uuid" (не використовується)

2. services/security-api/app/routes/portal.py
   - Рядок 2: видалити "from datetime import datetime, timezone" (не використовується)

3. services/security-api/app/routes/visits.py
   - Рядок 2: видалити "from starlette.requests import Request" (не використовується в жодному handler)

4. services/security-api/app/routes/proxy.py
   - Рядок 7: видалити "from app.auth.permissions import has_permission" (не використовується, proxy використовує _has_access())

5. services/security-api/app/routes/public_api.py
   - Рядок 2: видалити "from datetime import datetime, timezone" (якщо не використовується — перевірити)

КРОКИ:
1. Прочитай кожен файл повністю.
2. Перевірь що імпорт справді не використовується (grep по файлу).
3. Видали рядок.
4. py_compile на файлі після зміни.

ВЕРИФІКАЦІЯ:
- flake8 --select=F401 services/security-api/app/routes/banking.py → 0 помилок
- flake8 --select=F401 services/security-api/app/routes/portal.py → 0 помилок
- flake8 --select=F401 services/security-api/app/routes/visits.py → 0 помилок
- flake8 --select=F401 services/security-api/app/routes/proxy.py → 0 помилок
- flake8 --select=F401 services/security-api/app/routes/public_api.py → 0 помилок
- python -m py_compile на кожному файлі → OK

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ПРОМТ 4: Крок 2.5 — Виправити circular import (знахідка 14)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_2_report.md (§1.2).

ЗАВДАННЯ: Видалити circular import в estimate_service.py.

ФАЙЛ: services/security-api/app/services/estimate_service.py

ПРОБЛЕМА: Рядок 57 — "from app.routes.ai import _build_orchestrator". Service-шар імпортує з routes-шару (порушення R4). Також circular dependency: estimates.py → estimate_service.py → routes/ai.py.

КРОКИ:
1. Прочитай estimate_service.py повністю.
2. Зрозумій де використовується _build_orchestrator в estimate_service.py.
3. Прочитай routes/ai.py щоб зрозуміти що робить _build_orchestrator().
4. ВИРІШЕННЯ: Перенести логіку _build_orchestrator() в estimate_service.py (або в окремий ai_orchestrator_service.py який вже існує). Можливо використати frappe_post для виклику AI через Frappe API замість прямого імпорту оркестратора.
5. Видалити "from app.routes.ai import _build_orchestrator" з estimate_service.py.
6. Переконатись що estimate_service.py не імпортує з app.routes.*.
7. py_compile на файлі.

ВЕРИФІКАЦІЯ:
- grep "from app.routes" services/security-api/app/services/estimate_service.py → 0 результатів
- python -m py_compile services/security-api/app/services/estimate_service.py → OK
- python -m py_compile services/security-api/app/routes/estimates.py → OK (не зламано)

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ПРОМТ 5: Крок 2.3 — Перенести AI-оркестрацію в Frappe-процес (знахідки 1+2+3)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_3_report.md (§2, §6) та docs/audit/block_2_report.md (§1.1).

ЗАВДАННЯ: Замінити прямі імпорти security_erp.* в routes/ai.py на виклик через Frappe API (тонкий проксі, як Vault V3).

ФАЙЛ: services/security-api/app/routes/ai.py

ПРОБЛЕМА:
- Рядки 40-43 (_build_orchestrator): імпортують security_erp.ai.adapters.gemini, security_erp.ai.adapters.stub, security_erp.ai.circuit_breaker, security_erp.ai.orchestrator
- security_erp пакет НЕДОСТУПНИЙ в security-api контейнері (Dockerfile копіює лише services/security-api/)
- POST /api/v2/ai/execute падає з ModuleNotFoundError при виклику

АРХІТЕКТУРНЕ РІШЕННЯ (з fix_plan.md H1):
- routes/ai.py має бути тонким проксі — викликати frappe_post("/api/method/security_erp.ai.api.execute_ai", ...) замість прямого імпорту оркестратора
- ai/api.py вже є @frappe.whitelist() методом у Frappe-процесі
- Проблема asyncio.run() в gevent — окреме завдання (крок 2.4)

КРОКИ:
1. Прочитай routes/ai.py повністю.
2. Прочитай erpnext/security_erp/security_erp/ai/api.py щоб зрозуміти @frappe.whitelist() метод execute_ai.
3. Прочитай app/core/database.py щоб зрозуміти frappe_post().
4. Перепиши routes/ai.py:
   - Видалити _build_orchestrator() з lazy imports security_erp.*
   - Замінити на виклик frappe_post("/api/method/security_erp.ai.api.execute_ai", json={"task": ..., "payload": ..., "params": ...})
   - Обробити відповідь Frappe (структура {"message": ...})
5. Видалити "import redis.asyncio as aioredis" якщо більше не потрібен.
6. py_compile на файлі.

ВАЖЛИВО: Перевір реальну структуру відповіді Frappe API. Дивись як інші роути (наприклад vault.py) викликають frappe_post.

ВЕРИФІКАЦІЯ:
- grep "security_erp" services/security-api/app/routes/ai.py → 0 результатів
- grep "from security_erp" services/security-api/app/routes/ai.py → 0 результатів
- python -m py_compile services/security-api/app/routes/ai.py → OK

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ПРОМТ 6: Крок 2.4 — Sync-варіант оркестратора (знахідка 3)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_3_report.md (§4).

ЗАВДАННЯ: Реалізувати справжній sync-варіант complete_sync() в AI-адаптерах для RQ-контексту.

ФАЙЛИ:
- erpnext/security_erp/security_erp/ai/adapters/base.py
- erpnext/security_erp/security_erp/ai/adapters/gemini.py
- erpnext/security_erp/security_erp/ai/adapters/stub.py
- erpnext/security_erp/security_erp/tasks/ai_estimate.py

ПРОБЛЕМА:
- _run_orchestrator_sync() в ai_estimate.py намагається викликати provider.complete_sync() — не існує
- Fallback на asyncio.run(_timed_call(...)) — не працює в gevent/RQ контексті
- Circuit Breakер не задіяний в RQ-шляху

КРОКИ:
1. Прочитай всі 4 файли повністю.
2. Прочитай ai/adapters/base.py щоб зрозуміти AIResult та AbstractAIAdapter.
3. Додай в base.py: def complete_sync(self, task, payload, params) -> AIResult (abstract method).
4. В gemini.py: реалізуй complete_sync() через httpx.post() (sync, без async).
5. В stub.py: реалізуй complete_sync() — простий sync-варіант (повертає заглушку).
6. В ai_estimate.py: _run_orchestrator_sync() — видалити asyncio.run() fallback, використовувати лише provider.complete_sync().
7. py_compile на кожному файлі.

ВАЖЛИВО: httpx вже є в requirements Frappe-контейнера. Використовуй sync httpx (не async).

ВЕРИФІКАЦІЯ:
- grep "asyncio.run" erpnext/security_erp/security_erp/tasks/ai_estimate.py → 0 результатів
- grep "complete_sync" erpnext/security_erp/security_erp/ai/adapters/base.py → є визначення
- grep "complete_sync" erpnext/security_erp/security_erp/ai/adapters/gemini.py → є реалізація
- python -m py_compile на кожному файлі → OK

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ПРОМТ 7: Крок 2.6 — Відновити passport_client_release.py before_insert (знахідка 9)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_1_report.md (§4.1).

ЗАВДАННЯ: Відновити before_insert метод в passport_client_release.py.

ФАЙЛ: erpnext/security_erp/security_erp/security_erp/doctype/passport_client_release/passport_client_release.py

ПРОБЛЕМА: cpython-311 .pyc (контейнер) мав before_insert метод. Поточний .py має лише pass. Логіка була видалена.

КРОКИ:
1. Прочитай поточний .py файл.
2. Спробуй декомпілювати .pyc файл: python -c "import dis, marshal, struct; ..." або використай uncompyle6/pycdc на __pycache__/passport_client_release.cpython-311.pyc
3. Якщо декомпіляція неможлива — перевірь інші DocType контролери щоб зрозуміти типовий before_insert патерн.
4. Перевірь .json файл DocType щоб зрозуміти поля (name, fields, mandatory).
5. Відновити before_insert якщо є дані що він був потрібен. Якщо ні — запиши в лог що метод був свідомо видалений.
6. py_compile на файлі.

ВАЖЛИВО: Не генеруй болванку. Якщо не можеш відновити реальну логіку — запиши "потребує уточнення" в лог.

ВЕРИФІКАЦІЯ:
- python -m py_compile файл → OK
- Якщо відновлено: grep "before_insert" файл → є метод

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ПРОМТ 8: Крок 2.8 — Виправити CI тестовий pipeline (знахідка 10)

```
Прочитай CLAUDE.md, docs/audit/fix_plan.md та docs/audit/block_5_report.md.

ЗАВДАННЯ: Виправити CI pipeline щоб тести реально запускались.

ФАЙЛ: .github/workflows/ci.yml

ПРОБЛЕМА: 67 тестів падають з ModuleNotFoundError на хості. CI не встановлює pip-залежності (fastapi, pydantic, httpx, python-jose, redis, pydantic_settings). CI фактично робить лише syntax check.

КРОКИ:
1. Прочитай .github/workflows/ci.yml повністю.
2. Прочитай tests/security-api/test_models.py щоб зрозуміти які залежності потрібні.
3. Додай крок "Install test dependencies" перед кроком запуску тестів:
   - name: Install test dependencies
     run: pip install fastapi pydantic httpx python-jose[cryptography] redis pydantic_settings
4. Альтернатива (краще): запускати тести всередині Docker-контейнера security-api:
   - docker compose exec security-api python -m pytest tests/
5. py_compile на ci.yml (якщо yaml валідація потрібна).

ВЕРИФІКАЦІЯ:
- grep "pip install" .github/workflows/ci.yml → є встановлення залежностей
- python tests/security-api/test_models.py на хості з встановленими залежностями → тести проходять (або хоча бы запускаються)

ЗАПИШИ результат у docs/audit/fix_log.md.
```

---

## ЗАГАЛЬНИЙ ШАБЛОН ЛОГУ (fix_log.md)

Створити `docs/audit/fix_log.md` з наступною структурою:

```markdown
# Лог виправлень за аудитом A2-A4/S2-S4

**Дата початку:** 2026-06-23
**Джерело:** docs/audit/fix_plan.md
**Статус:** В ПРОЦЕСІ

---

## Крок 2.1: Видалити dead code
**Статус:** [ОЧІКУЄ / ВИКОНАНО / ЧАСТКОВО]
**Змінені файли:** [список]
**Що зроблено:** [опис]
**Верифікація:** [результат]
**Час:** [хвилин]

---

## Крок 2.2: Виправити _set_status("error")
...

---

## Крок 2.7: Видалити unused imports
...

---

## Крок 2.5: Виправити circular import
...

---

## Крок 2.3: Перенести AI-оркестрацію в Frappe-процес
...

---

## Крок 2.4: Sync-варіант оркестратора
...

---

## Крок 2.6: Відновити passport_client_release.py
...

---

## Крок 2.8: Виправити CI тестовий pipeline
...

---

## Відкладено: Крок 2.9 — doctypes.py рефакторинг
**Причина:** Великий обсяг (23 маршрути). Потребує окремої сесії.
```
