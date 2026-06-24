# E4 Session 1+2 — Log

## Сесія 1: Payload Format Fix

**Дата:** 2026-06-24
**Статус:** ✓ Виконано

### Змінені файли (Сесія 1)

| # | Файл | Зміни |
|---|------|-------|
| 1 | `riad_mobile/lib/ui/visit/visit_detail_screen.dart` | +`import 'dart:convert'`, `op: 'update'` → `'upsert'`, payload → `{scalars, additive}` |
| 2 | `riad_mobile/lib/ui/media/camera_screen.dart` | +`import 'dart:convert'`, `doctype: 'MediaAsset'` → `'Media Asset'`, `op: 'create'` → `'upsert'`, payload → `{scalars, additive}` |
| 3 | `riad_mobile/lib/ui/voice/voice_note_screen.dart` | +`import 'dart:convert'`, `doctype: 'MediaAsset'` → `'Media Asset'`, `op: 'create'` → `'upsert'`, payload → `{scalars, additive}` |
| 4 | `riad_mobile/lib/ui/checklist/checklist_screen.dart` | +`import 'dart:convert'`, 2 PendingOps → 1, doctype → `'Checklist Instance'`, `op: 'upsert'`, additive `checklist_instance_item` |
| 5 | `riad_mobile/lib/ui/scan/scan_screen.dart` | +`import 'dart:convert'`, `doctype: 'Visit'`, `name: widget.visitUuid`, `op: 'upsert'`, additive `visit_material` |

---

## Сесія 2: Background Sync + Retry

**Дата:** 2026-06-24
**Статус:** ✓ Виконано

### Змінені файли (Сесія 2)

| # | Файл | Зміни |
|---|------|-------|
| 1 | `lib/data/local/database.dart` | +`retryCount`, `nextRetryAt` колонки; +`getFailedPendingOps()`, `getRetryablePendingOps()`, `updatePendingOpRetry()`; виправлено `forTesting(NativeDatabase.memory())`, `watchPendingCount` → `pendingOps.id.count()`, `watchPendingMediaUploadCount` → `pendingMediaUploads.id.count()` |
| 2 | `lib/data/sync/sync_client.dart` | +інжекція `http.Client` (для моків); заміна `http.post` → `_client.post`; фікс `_applyChange` — `riad_version` з top-level change (pre-existing: завжди був 0); фікс `_upsert*` — приймають `riadVersion` параметр; `pushPending()` — try-catch для мережевих помилок (ставить 'failed') |
| 3 | `lib/data/sync/sync_service.dart` | **Новий файл** — `SyncService`: background sync (timer 5хв + connectivity listener), `retryFailedOps()` — exponential backoff (1s→2s→4s→8s→16s, max 5 retries, cap 300s), `syncOnce()` виконує повний цикл: retryFailed → pushPending → pullDelta → uploadPending |
| 4 | `pubspec.yaml` | Видалено `http_mockery` (не існує на pub.dev) |
| 5 | `test/s2/sync_client_test.dart` | +`import 'package:drift/drift.dart' hide isNotNull, isNull`; +`import 'package:drift/native.dart'`; fix `_handleConflict` → `handleConflict`; +інжекція mock client в `SyncClient`; fix `forTesting(NativeDatabase.memory())` |
| 6 | `test/s2/database_test.dart` | +drift imports; fix `forTesting(NativeDatabase.memory())` |
| 7 | `test/s2/sync_service_test.dart` | **Новий файл** — 9 тестів: retry backoff, max retry, not-retryable, syncOnce, connectivity. +`MediaUploadService` залежність |

### Додаткові файли (відсутні в плані, але необхідні)

| # | Файл | Причина |
|---|------|---------|
| 1 | `test/s2/sync_service_test.mocks.dart` | Згенеровано build_runner — моки для http.Client та Connectivity |

### Виправлення під час ревізії (після першого запуску тестів)

| # | Проблема | Знайдено при | Виправлення |
|---|----------|-------------|-------------|
| 1 | `riadVersion` завжди = 0 при pull | Тест `pull_updates_existing` | `_applyChange` читає `riad_version` з top-level `change`, а не з `change['fields']` |
| 2 | `_handleConflict` (приватний) в тесті | Компіляція | Змінено на `handleConflict` (публічний) |
| 3 | `http.post` статичний — mock не перехоплював | Тести падали з Connection refused | Додано інжекцію `http.Client` в `SyncClient` |
| 4 | `retryFailedOps` викликалась ПЕРЕД `pushPending()` | Ревізія логіки | Перенесено ПІСЛЯ — newly failed ops не retry-яться одразу без backoff |
| 5 | `pushPending()` при помилці залишав 'inflight' навічно | Ревізія логіки | Додано try-catch що ставить 'failed' при мережевій помилці |
| 6 | `retryCount` не зберігався при retry | Ревізія | Додано `retryCount`/`nextRetryAt` колонки + методи БД |
| 7 | `RiadDatabase.forTesting()` без аргументу | Тести падали | Змінено на `forTesting(NativeDatabase.memory())` |
| 8 | `watchPendingCount` не компілювався (Drift 2.34) | Тести падали | Змінено `pendingOps.count()` → `pendingOps.id.count()` |
| 9 | `http_mockery` не існує на pub.dev | `flutter pub get` падав | Видалено з pubspec.yaml |
| 10 | `Value` не імпортовано в тестах | Тести падали | Додано `import 'package:drift/drift.dart'` |
| 11 | `uploadPending()` не викликалася в syncOnce() | Порівняння з планом | Додано `MediaUploadService` залежність + виклик `uploadPending()` в `syncOnce()` |

### Логіка retry (фінальна)

```
pushPending() fails → status='failed', nextRetryAt=0, retryCount=0
                         ↓
syncOnce() → pushPending() → pullDelta() → retryFailedOps()
                                                 ↓
                              getRetryablePendingOps() (nextRetryAt <= now)
                                                 ↓
                              retryCount++ → nextRetryAt = now + backoff
                              status='pending'
                                                 ↓
                              Наступний syncOnce() → pushPending() відправляє
```

**Backoff:** 1s → 2s → 4s → 8s → 16s (max 5 retries, cap 300s)

### Тести

| Файл | Тестів | Результат |
|------|--------|-----------|
| sync_client_test.dart | 13 | ✓ All passed |
| sync_service_test.dart | 9 | ✓ All passed |
| database_test.dart | 22 | ✓ All passed |
| **Разом** | **44** | **✓ All passed** |

### Pre-existing помилки (виправлено)

- ~~`visit_workflow_test.dart` — немає drift import~~ → ✓ Виправлено
- ~~UI файли — `Value` не визначено~~ → ✓ Виправлено (drift import додано)

## Наступні кроки

- [x] Сесія 3: Drive bridge + tombstone guard + integration tests → ✓
- [x] Виправити `visit_workflow_test.dart` → ✓
- [x] Виправити UI файли (drift import) → ✓
- [ ] Tombstone guard на всі 13 таблиць (не критично)
