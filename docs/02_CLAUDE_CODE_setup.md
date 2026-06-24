# Налаштування Claude Code для RIAD Smart System (ЕТАПИ 4–5)

> Цей файл — не системний промпт, а **інструкція з налаштування**. Виконується один раз у терміналі Claude Code, у корені проєкту RIAD Smart System, після того як завершено аудит у Claude Project і ухвалено рішення (Варіант A / B / C).

---

## 1. Важливе уточнення щодо "скілів"

`context-engineering-kit` і `superpowers` — це **плагіни Claude Code** (набори команд, агентів-субагентів і skill-файлів), а не текст, який можна вставити в системний промпт чату на claude.ai. Вони працюють лише в Claude Code (CLI/термінал/desktop-агент із доступом до файлової системи проєкту).

Якщо ти працюєш у звичайному чаті Claude Project — ці плагіни не активуються і не потрібні; там працює файл `01_RIAD_CTO_AUDITOR_system_prompt.md`.

---

## 2. Встановлення плагінів

Виконати в Claude Code, у директорії проєкту:

```bash
# Spec-Driven Development — перетворює задачі на специфікації, потім на код
/plugin marketplace add NeoLabHQ/context-engineering-kit
/plugin install sdd@NeoLabHQ/context-engineering-kit

# (опційно, але рекомендовано для ERPNext/Frappe монорепо)
/plugin install ddd@NeoLabHQ/context-engineering-kit
/plugin install reflexion@NeoLabHQ/context-engineering-kit

# Superpowers — методологія: brainstorming → TDD → subagent-driven execution
/plugin marketplace add obra/superpowers-marketplace
/plugin install superpowers@superpowers-marketplace
```

**Навіщо саме ці два, а не один:**

| Плагін | Що дає | Чому потрібен саме для RIAD |
|---|---|---|
| `sdd` (context-engineering-kit) | `/add-task` → `/plan-task` → `/implement-task`, специфікація у форматі arc42, codebase impact analysis перед кожною зміною | Запобігає повторенню сценарію "виправлення породжували нові проблеми" — кожна зміна спершу аналізує вплив на існуючий ERPNext/Frappe код |
| `superpowers` | `brainstorming` (Сократівські питання перед кодом), `writing-plans` (задачі по 2–5 хв), `test-driven-development` (RED-GREEN-REFACTOR), `subagent-driven-development` | Дисциплінує процес так, щоб не накопичувався технічний борг і непротестований код, як у попередній спробі |

---

## 3. CLAUDE.md проєкту — шаблон

Створити (або оновити) `CLAUDE.md` у корені репозиторію. Цей файл автоматично підвантажується Claude Code в кожній сесії.

```markdown
# RIAD Smart System — CLAUDE.md

## Статус проєкту
[Вставити сюди вирок з ЕТАПУ 3 аудиту: обраний варіант A/B/C і коротке обґрунтування]

## Архітектурний дефолт
KISS > Clean Architecture > Microservices.
Перед будь-якою новою функцією — пройти послідовність:
ERPNext "з коробки" → конфігурація → Server Script → Custom DocType → Custom App → окремий сервіс.
Перехід до окремого сервіса — тільки з письмовим обґрунтуванням, чому Frappe-парадигма не підходить.

## Компоненти (статус після аудиту)
- ERPNext: [ЗАЛИШИТИ/ВИПРАВИТИ/ПЕРЕПИСАТИ/ВИДАЛИТИ]
- security_erp: [...]
- FastAPI: [...]
- Flutter: [...]
- Docker: [...]

## Обов'язкові процеси
- Будь-яка нова задача проходить /sdd:add-task → /sdd:plan-task → /sdd:implement-task
- TDD обов'язковий (RED-GREEN-REFACTOR), код без тестів не приймається
- Перед merge — codebase impact analysis (хто ще зачеплений зміною)
- Заборонено додавати новий контейнер/сервіс без явного обґрунтування в специфікації задачі

## Стек
[Технології, версії, шлях розгортання на власному Linux-сервері]
```

---

## 4. Типовий робочий цикл (ЕТАП 4 → 5) для нової задачі

```bash
# 1. Створити чернетку задачі
/add-task "Реалізувати модуль FSM для призначення інженерів на заявки"

# 2. Уточнити вимоги через сократівський діалог (опційно, рекомендовано для нечітких задач)
/brainstorm

# 3. Згенерувати детальну специфікацію (включає codebase impact analysis)
/plan-task
# → переміщує задачу в .specs/tasks/todo/

# Перезапустити сесію Claude Code (очистити контекст)

# 4. Реалізувати з TDD + субагентами
/implement-task @.specs/tasks/todo/fsm-engineer-assignment.feature.md
# → переміщує задачу в .specs/tasks/done/ після завершення
```

Для задач, що зачіпають кілька файлів/модулів одночасно (тобто власне "ЕТАП 4 — Архітектура") — почати з `/propose-hypotheses` (плагін `fpf`, опційно) або просто з `/brainstorm`, щоб уникнути одразу одного "очевидного" рішення без розгляду альтернатив.

---

## 5. Зв'язок з аудитом із Claude Project

Перед першим запуском `/add-task` — скопіювати фінальний вирок ЕТАПУ 3 (з чату-аудиту) у `CLAUDE.md` дослівно, в розділ "Статус проєкту". Це гарантує, що архітектурні рішення в Claude Code не суперечать висновкам аудиту і не повторюють вже відкинуті варіанти.
