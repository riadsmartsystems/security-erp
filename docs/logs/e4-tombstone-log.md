# E4 Tombstone Guard — Розширення на 9 таблиць

**Дата:** 2026-06-24
**Статус:** ✓ Виконано

## Змінені файли

| # | Файл | Зміни |
|---|------|-------|
| 1 | `riad_mobile/lib/data/local/database.dart` | `isTombstoned()` розширено з 3 до 9 таблиць |
| 2 | `riad_mobile/test/s2/database_test.dart` | +9 тестів isTombstoned (parent + child + nonexistent) |

## Покриття isTombstoned()

| # | Таблиця | Тип | Перевірка |
|---|---------|-----|-----------|
| 1 | Visits | parent | ✓ clientUuid → riadDeleted |
| 2 | ChecklistInstances | parent | ✓ clientUuid → riadDeleted |
| 3 | InstallationMaps | parent | ✓ clientUuid → riadDeleted |
| 4 | MediaAssets | parent | ✓ clientUuid → riadDeleted |
| 5 | VisitMaterials | child | ✓ clientUuid → visitUuid → Visits.riadDeleted |
| 6 | VisitPhotos | child | ✓ clientUuid → visitUuid → Visits.riadDeleted |
| 7 | ChecklistInstanceItems | child | ✓ itemUuid → instanceUuid → ChecklistInstances.riadDeleted |
| 8 | MountPoints | child | ✓ pointUuid → mapUuid → InstallationMaps.riadDeleted |
| 9 | CableRoutes | child | ✓ routeUuid → mapUuid → InstallationMaps.riadDeleted |

4 таблиці без riadDeleted (SyncMeta, PendingOps, PendingMediaUploads, SyncConflicts) — не потребують guard.

## Тести

| Набір | Тестів | Результат |
|-------|--------|-----------|
| test/s2/database_test.dart | 31 (+9 нових) | ✓ All passed |
| test/s2/sync_client_test.dart | 13 | ✓ All passed |
| test/s2/sync_service_test.dart | 9 | ✓ All passed |
| tests/s1/*.py | 11 | ✓ All passed |
| **Разом** | **64** | **✓ All passed** |
