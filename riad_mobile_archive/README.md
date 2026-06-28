# RIAD Mobile - Offline-first Flutter App

## Архітектура

### Структура каталогів
```
riad_mobile/
├── lib/
│   ├── data/
│   │   ├── local/
│   │   │   ├── database.dart      # Drift схема БД
│   │   │   └── database.g.dart    # Згенерований код
│   │   └── sync/
│   │       └── sync_client.dart   # Клієнт синхронізації
│   └── ui/
│       └── sync/
│           └── sync_conflict_card.dart  # UI конфліктів
├── test/
│   └── s2/
│       ├── database_test.dart     # Тести бази даних
│       └── sync_client_test.dart  # Тests sync клієнта
└── pubspec.yaml
```

## Таблиці Drift

### SyncMeta (singleton)
- `watermark` — опаковий токен від сервера
- `device_id` — UUID пристрою

### PendingOps (черга змін)
- `doctype`, `name`, `op`, `payload`, `base_version`, `status`, `created_at`

### Visit + childs
- `client_uuid`, `riad_version`, `riad_deleted`, `riad_deleted_at`
- `visit_type`, `summary`, `service_ticket`, `visit_date`, `status`

### VisitMaterial
- `client_uuid`, `visit_uuid`, `riad_version`, `riad_deleted`
- `item_name`, `serial_no`, `qty`

### VisitPhoto
- `client_uuid`, `visit_uuid`, `riad_version`, `riad_deleted`
- `drive_file_id`, `description`

### ChecklistInstance + childs
- `client_uuid`, `riad_version`, `riad_deleted`
- `template`, `passport`, `visit`, `status`

### ChecklistInstanceItem
- `item_uuid`, `instance_uuid`, `riad_version`, `riad_deleted`
- `checked_by`, `photo`, `value`, `serial_no`

### InstallationMap + childs
- `client_uuid`, `riad_version`, `riad_deleted`
- `passport`, `name_`

### MountPoint
- `point_uuid`, `map_uuid`, `riad_version`, `riad_deleted`
- `type`, `label`, `x`, `y`, `status`, `item`, `serial_no`, `photo`

### CableRoute
- `route_uuid`, `map_uuid`, `riad_version`, `riad_deleted`
- `from_point`, `to_point`, `path_json`

### MediaAsset
- `client_uuid`, `riad_version`, `riad_deleted`
- `drive_file_id`, `ai_allowed`, `transcription_status`

### SyncConflict
- `conflict_id`, `doctype`, `docname`, `field_name`
- `server_value`, `client_value`, `resolved`

## Sync Client

### pullDelta()
- POST `/api/v2/sync/pull` з `{device_id, watermark}`
- Upsert основних документів
- Union-merge адитивних колекцій за UUID
- Tombstone → soft-delete
- Просування watermark

### push_pending()
- POST `/api/v2/sync/push` з batch ops
- Обробка статусів: applied, merged, conflict, tombstoned, ignored_duplicate
- При конфлікті → збереження в SyncConflict

### createTombstone()
- Soft-delete локально
- Запис PendingOp з op=delete

### watchPendingCount()
- Stream для badge на home screen

## Conflict UI

### SyncConflictCard
- Показує незавершені конфлікти
- Кнопки «Сервер» / «Клієнт»
- POST `/api/v2/sync/resolve` з `{conflict_id, chosen}`
- При виборі «Клієнт» → оновлення локального поля

## Тести

### database_test.dart (20 тестів)
- SyncMeta операції
- Visit CRUD + soft-delete
- PendingOps CRUD
- SyncConflicts CRUD
- Additive таблиці
- Tombstone операції
- watchPendingCount

### sync_client_test.dart (12 тестів)
- pull_creates_local_record
- pull_updates_existing
- pull_tombstone
- pull_advances_watermark
- pull_union_merge_additive
- push_applied
- push_conflict
- push_tombstone
- push_ignored_duplicate
- push_already_present_additive
- conflict_resolve_client
- conflict_resolve_server

## Запуск тестів

```bash
# З генерацією коду
flutter pub run build_runner build
flutter test

# Або окремо
flutter test test/s2/database_test.dart
```

## Залежності

- `drift: ^2.14.0` — SQLite ORM
- `uuid: ^4.2.0` — Генерація UUID
- `http: ^1.1.0` — HTTP запити
- `flutter_secure_storage: ^9.0.0` — Безпечне зберігання токенів
