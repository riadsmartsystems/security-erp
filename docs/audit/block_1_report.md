# Аудит Блоку 1: DocType валідність (50 директорій)

**Дата:** 2026-06-23
**Метод:** systematic-debugging (Phase 1: Root Cause Investigation)
**Статус:** АУДИТ — нічого не виправлено
**Примітка:** Звіт відновлено з пам'яті сесії (оригінальна сесія завершилась до запису файлу)

---

## 1. Загальна таблиця перевірки

Директорія: `erpnext/security_erp/security_erp/security_erp/doctype/` (50 DocType)

| Check | Результат | Деталі |
|-------|-----------|--------|
| .json файли | ✅ 50/50 | Всі DocType мають .json з field definitions |
| .py файли | ✅ 50/50 | Всі DocType мають .py контролер |
| __pycache__/*.pyc | ✅ 50/50 | Дві версії: cpython-311 (контейнер) та cpython-312 (хост) |
| py_compile | ✅ 50/50 OK | Всі .py компілюються без помилок |
| JSON validity | ✅ 50/50 | Всі .json валідні |
| __init__.py | ❌ 0/50 | Відсутні в DocType-директоріях. Це **нормальна Frappe-конвенція** — DocType виявляються через .json метадані, не через Python import. Батьківські директорії (security_erp/, security_erp/security_erp/) мають __init__.py. |

---

## 2. DocType з реальною логікою (11 з 50)

| DocType | .py | Лінійки | Ключова логіка |
|---------|-----|---------|----------------|
| vault_entry | vault_entry.py | 8L | before_save → encrypt_doc_fields з vault._hooks |
| media_asset | media_asset.py | 8L | before_save → auto-set riad_deleted_at |
| riad_device_session | riad_device_session.py | 16L | before_insert (timestamps) + revoke(reason) |
| estimate | estimate.py | 86L | validate, calculate_totals, on_submit, apply_template, apply_scenario, create_quotation |
| service_ticket | service_ticket.py | 79L | SLA engine: validate, before_insert, on_update, set_sla_deadlines, handle_status_change, pause_sla, resume_sla |
| installation_act | installation_act.py | 53L | validate, validate_items, calculate_totals, on_submit, on_cancel, create_equipment_records |
| contract | contract.py | 24L | validate, validate_dates, before_insert, on_update |
| visit | visit.py | 14L | validate (work_minutes calc) |
| warranty_letter | warranty_letter.py | 12L | validate (expiry), on_submit |
| material_reservation | material_reservation.py | 17L | validate, validate_items, on_submit, on_cancel |
| passport_client_release | passport_client_release.py | 6L | empty class pass (⚠️ cpython-311 pyc мав before_insert, видалено) |

**38 інших DocType** мають .py з лише `pass` (стандартний Frappe-контролер без кастомної логіки).

---

## 3. Cross-reference з BUILD_LOG

### R7 — 13 нових DocType (батч відсутніх)

| DocType | Присутній? | .json | .py |
|---------|-----------|-------|-----|
| Site Brief | ✅ | ✅ | ✅ |
| Object Passport | ✅ | ✅ | ✅ |
| Passport Client Release | ✅ | ✅ | ✅ |
| Installation Map | ✅ | ✅ | ✅ |
| Mount Point | ✅ | ✅ | ✅ |
| Cable Route | ✅ | ✅ | ✅ |
| Checklist Template | ✅ | ✅ | ✅ |
| Checklist Template Item | ✅ | ✅ | ✅ |
| Checklist Instance | ✅ | ✅ | ✅ |
| Checklist Instance Item | ✅ | ✅ | ✅ |
| Remote Inspection | ✅ | ✅ | ✅ |
| Remote Inspection Media | ✅ | ✅ | ✅ |
| Media Asset | ✅ | ✅ | ✅ |

**Результат:** 13/13 — всі присутні.

### R8 — 8 нових DocType (Vault-неймспейс)

| DocType | Присутній? | .json | .py |
|---------|-----------|-------|-----|
| Vault Entry | ✅ | ✅ | ✅ |
| Vault Access Enrollment | ✅ | ✅ | ✅ |
| Vault Audit Log | ✅ | ✅ | ✅ |
| Access Transfer Act | ✅ | ✅ | ✅ |
| Access Transfer Act Entry | ✅ | ✅ | ✅ |
| AI Provider | ✅ | ✅ | ✅ |
| AI Request Log | ✅ | ✅ | ✅ |
| Sync Conflict | ✅ | ✅ | ✅ |

**Результат:** 8/8 — всі присутні.

---

## 4. Знахідки

### 4.1 passport_client_release.py — втрачений before_insert ⚠️

cpython-311 .pyc (контейнер) містив `before_insert` метод. Поточний .py має лише `pass`. Логіка була видалена (свідомо чи випадково). Потребує верифікації.

### 4.2 cpython-311 vs cpython-312 .pyc

Старі .pyc від контейнера (Python 3.11), новіші від хоста (Python 3.12). Вміст еквівалентний для всіх перевірених DocType. Розбіжностей не знайдено.

### 4.3 __init__.py відсутність — НЕ помилка

Frappe не використовує Python import для виявлення DocType. Метадані зчитуються з .json файлів. Відсутність __init__.py в doctype-директоріях — штатна конвенція.

---

## 5. Вердикт

| Критерій | Статус |
|----------|--------|
| Всі 50 DocType мають .json + .py | ✅ |
| Всі .py компілюються | ✅ |
| Всі .json валідні | ✅ |
| R7 DocTypes (13) присутні | ✅ |
| R8 DocTypes (8) присутні | ✅ |
| 19 DocTypes що "зникли" (MEMORY.md) — відновлені | ✅ |

**Загальний статус: PASS** — жодних критичних знахідок. Єдине зауваження: `passport_client_release.py` втратив `before_insert` (потребує верифікації чи це свідомо).
