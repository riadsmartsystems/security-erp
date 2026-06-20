# STAGE-3-PROGRESS-2026-06-20.md
_Проміжний звіт по гілці `cleanup`. Доповнює STAGE-3-VERIFIED.md фактами,
зібраними напряму з коду 2026-06-20._

## Підтверджений стан репозиторію
- `origin` = `github.com/riadsmartsystems/security-erp.git` (справжній)
- Гілка `cleanup` на GitHub синхронізована з локальною: `393ac4a`
- `master` не зрушив від `e1f1bde` — STAGE-1-VERIFIED/STAGE-2-VERIFIED досі коректні для master
- Незакомічено локально: `README.md`, `docs/go-live-checklist.md` (modified); `CLAUDE.md`, `SESSION-2026-06-20.md`, `security_erp_app/`, `.mimocode/` (untracked)
- ⚠️ Знайдено в історії комітів: `6713798 remove env.backup with secrets` — якщо креди з того файлу досі валідні, потрібна ротація окремо від іншої роботи

## P0 — фінальний статус
| # | Задача | Статус |
|---|---|---|
| 1 | docker-compose.yml: volume-шлях + `build:` через Dockerfile.backend | ✅ Зроблено |
| 2 | .env.example | ❓ Не перевірено |
| 3 | permissions.py: реальна RBAC | ❌ `contract_has_permission(doc, ...)` приймає `doc`, але не передає його в `frappe.has_permission()` — перевірка лише на рівні DocType, не конкретного документа. Функціонально не дає жодного захисту понад стандартний доступ ролі |
| 4 | contract.py: автонумерація | ❓ Не перевірено |
| 5 | estimate.py: apply_template/apply_scenario | ❌ Не зроблено (diff проти e1f1bde порожній) |
| 6 | installation_act.py: реєстрація Equipment | ❌ Не зроблено (diff проти e1f1bde порожній) |
| 7 | events.py: виклик n8n | ❌ Не прибрано. `_notify_n8n()` обгорнута в `try:` (рядок 164), викликається з `ticket_on_update()` і `ticket_after_insert()` — на кожен новий/змінений тікет звертається до `http://n8n:5678`, якого більше немає в compose. Вміст `except` не перевірено повністю |
| 8 | DELETE fsm/cmdb/ai/telegram-service | 🟡 Частково: `services/` містить лише `security-api` (мікросервіси видалені фізично). `configs/n8n/` досі лежить осиротілим. Згадки `telegram-service` у `docker-compose.yml`/`configs/` — не перевірено остаточно |

---

## Промт для нової сесії Claude Code (вставити цілком, без правок)

```
Контекст: STAGE-3-VERIFIED.md визначає скоуп ремонту (Варіант A). Частина
роботи вже зроблена на гілці cleanup (docker-compose.yml виправлено,
fsm/cmdb/ai-service видалені фізично). Нижче — список того, що лишилось,
за фактами з прямої перевірки коду 2026-06-20. Для кожного пункту: спочатку
перевір поточний стан, потім виправ, якщо потрібно. Працюй послідовно,
комiть після кожного логічно завершеного пункту окремим повідомленням.
Не питай підтвердження на кожен крок — звітуй фінальним підсумком наприкінці.

1. erpnext/security_erp/security_erp/permissions.py:
   contract_has_permission(doc, user, permission_type) приймає doc, але не
   передає його у frappe.has_permission() — перевірка лише на рівні
   DocType. Виправити: передати doc=doc у виклик frappe.has_permission(),
   щоб перевірка враховувала конкретний документ.

2. estimate.py (doctype/estimate/estimate.py): перевірити наявність методів
   apply_template() і apply_scenario(). Якщо відсутні — реалізувати:
   apply_template() заповнює items кошторису з полів вибраного
   Estimate Template; apply_scenario() заповнює items на основі обраного
   Security Scenario (security_scenario_item). Додати поля tz_text, lead
   в estimate.json, якщо відсутні.

3. installation_act.py (doctype/installation_act/installation_act.py):
   у on_submit() перевірити реєстрацію Equipment. Якщо відсутня — додати:
   для кожного item з serial_number створити/знайти Equipment doc,
   прив'язати до відповідного object/customer.

4. contract.py: перевірити before_insert() на мертвий код автонумерації
   (патерн на кшталт "if not X: pass"). Якщо є — реалізувати реальну
   автонумерацію відповідно до поточного naming_rule контракту.

5. events.py: прибрати виклики _notify_n8n() з ticket_on_update() і
   ticket_after_insert() та саму функцію _notify_n8n() — n8n видалено з
   docker-compose.yml, хост більше не існує. Логіку publish_realtime()
   у тих самих функціях НЕ чіпати, вона не пов'язана з n8n.

6. Прибрати осиротілі залишки: configs/n8n/ (сервіс видалено, конфіг
   лишився); перевірити docker-compose.yml і configs/ на згадки
   telegram-service і видалити, якщо є.

7. .env.example: перевірити існування і повноту (MYSQL_ROOT_PASSWORD,
   SITE_NAME, ADMIN_PASSWORD, FRAPPE_API_KEY, FRAPPE_API_SECRET,
   REDIS_URL, ANTHROPIC_API_KEY). Створити/доповнити за потреби.

8. security_erp_app/ — порожня untracked директорія зі старою хибною
   назвою. Підтверджено, що ніщо на неї не посилається — видалити.

9. Закомітити все напрацьоване сьогодні (README.md, go-live-checklist.md,
   CLAUDE.md, SESSION-2026-06-20.md) окремими логічними комітами, потім
   кожен P0-фікс вище — окремим комітом. Запушити гілку cleanup.

10. ОКРЕМО ДОПОВІСТИ, не виправляй без мого підтвердження: коміт
    6713798 "remove env.backup with secrets" — чи креди з того файлу
    досі активно використовуються/валідні? Якщо так — потрібна ротація.

Фінальний звіт: що зроблено, що не вдалось і чому, короткий diff-summary
по кожному зміненому файлу.
```
