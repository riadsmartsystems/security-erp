# E4 Session 3 + Pre-existing fixes — Фінальний стан

**Дата:** 2026-06-24
**Статус:** ✓ Виконано

## Змінені файли (Сесія 3)

| # | Файл | Зміни |
|---|------|-------|
| 1 | `services/security-api/app/services/sync_service.py` | +`encode_watermark = _encode_watermark` (публічний alias для тестів) |
| 2 | `riad_mobile/lib/data/sync/media_upload_service.dart` | +`import 'dart:convert'`; +створення PendingOp після успішного upload (drive bridge) |
| 3 | `riad_mobile/lib/data/local/database.dart` | +`isTombstoned(clientUuid)` — перевіряє riadDeleted для Visit/ChecklistInstance/InstallationMap |
| 4 | `riad_mobile/lib/ui/scan/scan_screen.dart` | +виклик `isTombstoned(widget.visitUuid)` перед створенням material — блокує resurrection |
| 5 | `tests/s1/test_s1_sync_integration.py` | **Новий файл** — 2 тести: push→conflict→resolve→pull cycle + encode_watermark alias |

## Виправлення pre-existing помилок

| # | Файл | Що виправлено |
|---|------|---------------|
| 1 | `riad_mobile/lib/ui/visit/visit_detail_screen.dart` | +`import 'package:drift/drift.dart' hide isNotNull, isNull` |
| 2 | `riad_mobile/lib/ui/media/camera_screen.dart` | +drift import |
| 3 | `riad_mobile/lib/ui/voice/voice_note_screen.dart` | +drift import |
| 4 | `riad_mobile/lib/ui/checklist/checklist_screen.dart` | +drift import |
| 5 | `riad_mobile/lib/ui/scan/scan_screen.dart` | +drift import |
| 6 | `riad_mobile/test/s3/visit_workflow_test.dart` | +drift import, +Value() для nullable полів (mediaType, tag, localPath, serialNo, visitDate), виправлено const Value() для змінних |

## Деталі змін

### Drive bridge (media_upload_service.dart)
Після успішного upload файлу на сервер та отримання `drive_file_id`, тепер створюється PendingOp з `{scalars: {drive_file_id: ...}, additive: {}}` — це дозволяє синхронізувати drive_file_id на інші пристрої.

### Tombstone guard (database.dart + scan_screen.dart)
`isTombstoned()` перевіряє чи запис має `riadDeleted=true` в будь-якій з 3 таблиць (Visits, ChecklistInstances, InstallationMaps). Викликається в `scan_screen.dart` перед додаванням material — якщо visitUuid належить видаленому запису, відображається SnackBar з попередженням.

### Integration test
Тестує повний цикл: push (створює conflict) → resolve (обирає client value) → pull (отримує оновлений запис). Без приватних методів, без крихких лічильників.

## Тести (фінальні)

| Набір | Тестів | Результат |
|-------|--------|-----------|
| tests/s1/test_s1_sync.py | 9 | ✓ All passed |
| tests/s1/test_s1_sync_integration.py | 2 | ✓ All passed |
| test/s2/sync_client_test.dart | 13 | ✓ All passed |
| test/s2/sync_service_test.dart | 9 | ✓ All passed |
| test/s2/database_test.dart | 22 | ✓ All passed |
| test/s3/visit_workflow_test.dart | 8 | ✓ All passed |
| **Разом** | **63** | **✓ All passed** |

## Що залишилось (не критичне)

- Tombstone guard покриває лише 3 з 13 таблиць (Visit/Material/Photo/Asset не захищені)
