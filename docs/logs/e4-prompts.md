# ПРОМТИ ДЛЯ ВИКОНАННЯ E4

---

## ПРОМТ 1: Сесія 1 — Виправлення payload format (БЛОКЕР)

```
Ти — Flutter розробник. Виконай завдання.

## Роль
Ти виконуєш зміни в кодовій базі Security ERP. Твоя задача — виправити критичний баг у форматі payload для sync.

## Контекст
Є offline-sync система. `sync_client.dart` метод `pushPending()` (рядки 321-330) розпарсює payload так:
```dart
final payload = jsonDecode(op.payload) as Map<String, dynamic>;
return {
  'doctype': op.doctype,
  'name': op.name,
  'op': op.op,
  'client_base_version': op.baseVersion,
  'scalars': payload['scalars'],
  'additive': payload['additive'],
};
```

Тобто він ОЧІКУє формат: `{"scalars": {"field": "value"}, "additive": {"child_table": [...]}}`

Але ВСІ 5 screens створюють PendingOps з плоским payload. Жоден sync не працює.

## Файли для зміни

1. `riad_mobile/lib/ui/visit/visit_detail_screen.dart` — рядки 29-38, метод `_changeStatus`
2. `riad_mobile/lib/ui/media/camera_screen.dart` — рядки 84-90
3. `riad_mobile/lib/ui/voice/voice_note_screen.dart` — рядки 85-91
4. `riad_mobile/lib/ui/checklist/checklist_screen.dart` — рядки 32-53
5. `riad_mobile/lib/ui/scan/scan_screen.dart` — рядки 49-55

## Інструкція

### Файл 1: visit_detail_screen.dart
- Додати `import 'dart:convert';` після `import 'package:flutter/material.dart';`
- Замінити рядок `payload: '{"status":"$newStatus"}',` на:
```dart
payload: jsonEncode({
  'scalars': {'status': newStatus},
  'additive': {},
}),
```

### Файл 2: camera_screen.dart
- Додати `import 'dart:convert';`
- Замінити `doctype: 'MediaAsset'` на `doctype: 'Media Asset'`
- Замінити рядок `payload: '{"media_type":"photo","tag":"$_selectedTag"}',` на:
```dart
payload: jsonEncode({
  'scalars': {
    'media_type': 'photo',
    'tag': _selectedTag,
    'parent_doctype': widget.parentDoctype ?? '',
    'parent_name': widget.parentName ?? '',
  },
  'additive': {},
}),
```

### Файл 3: voice_note_screen.dart
- Додати `import 'dart:convert';`
- Замінити `doctype: 'MediaAsset'` на `doctype: 'Media Asset'`
- Замінити рядок `payload: '{"media_type":"audio"}',` на:
```dart
payload: jsonEncode({
  'scalars': {
    'media_type': 'audio',
    'parent_doctype': widget.parentDoctype ?? '',
    'parent_name': widget.parentName ?? '',
  },
  'additive': {},
}),
```

### Файл 4: checklist_screen.dart
- Додати `import 'dart:convert';`
- Видалити ОБИДВА createPendingOp (рядки 227-241)
- Замінити на ОДИН createPendingOp після `db.update`:
```dart
await db.createPendingOp(PendingOpsCompanion.insert(
  doctype: 'Checklist Instance',
  name: item.instanceUuid,
  op: 'update',
  payload: jsonEncode({
    'scalars': {'status': 'in_progress'},
    'additive': {
      'checklist_instance_item': [
        {
          '_uuid': item.itemUuid,
          'checked_by': checked ? 'current_user' : null,
        },
      ],
    },
  }),
  createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
));
```

### Файл 5: scan_screen.dart
- Додати `import 'dart:convert';`
- Замінити `doctype: 'VisitMaterial'` на `doctype: 'Visit'`
- Замінити `name: clientUuid` на `name: widget.visitUuid`
- Замінити `op: 'create'` на `op: 'update'`
- Замінити payload на:
```dart
payload: jsonEncode({
  'scalars': {},
  'additive': {
    'visit_material': [
      {
        '_uuid': clientUuid,
        'serial_no': code,
        'item_name': code,
        'qty': 1,
      },
    ],
  },
}),
```

## Верифікація
Після кожної зміни запускай:
```bash
cd "/home/joker/RIAD CRM/riad_mobile" && flutter analyze [шлях_до_файлу]
```

В кінці — загальний аналіз:
```bash
cd "/home/joker/RIAD CRM/riad_mobile" && flutter analyze lib/ui/visit/visit_detail_screen.dart lib/ui/media/camera_screen.dart lib/ui/voice/voice_note_screen.dart lib/ui/checklist/checklist_screen.dart lib/ui/scan/scan_screen.dart
```

Очікуваний результат: `No issues found!`

## Лог
Запиши результат у файл: `.mimocode/plans/e4-session1-log.md` зі статусом кожного файлу.
```

---

## ПРОМТ 2: Сесія 2 — Background sync + Retry + Тест

```
Ти — Flutter розробник. Виконай завдання.

## Роль
Ти додаєш background sync service та retry механізм для offline-sync системи.

## Контекст
Є `sync_client.dart` з методами `pullDelta()`, `pushPending()`, `watchPendingCount()`.
Є `media_upload_service.dart` з методом `uploadPending()`.
PendingOps таблиця має поле status: pending/inflight/failed/done.
Failed PendingOps залишаються failed назавжди.
Немає background sync — все викликається вручну.
Тест `sync_client_test.dart` рядок 589 викликає приватний метод `_handleConflict`.

## Завдання

### Крок 1: Запустити існуючі тести
```bash
cd "/home/joker/RIAD CRM" && python -m unittest tests.s1.test_s1_sync -v
cd "/home/joker/RIAD CRM/riad_mobile" && flutter test test/s2/sync_client_test.dart
```

### Крок 2: Створити файл `riad_mobile/lib/data/sync/background_sync_service.dart`

Створи файл з наступним вмістом:
```dart
import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'sync_client.dart';
import 'media_upload_service.dart';

class BackgroundSyncService {
  final SyncClient _syncClient;
  final MediaUploadService _mediaUploadService;
  Timer? _timer;
  bool _syncing = false;

  BackgroundSyncService({
    required SyncClient syncClient,
    required MediaUploadService mediaUploadService,
  })  : _syncClient = syncClient,
        _mediaUploadService = mediaUploadService;

  void start({Duration interval = const Duration(minutes: 5)}) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) => syncNow());
    Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline) syncNow();
    });
    syncNow();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> syncNow() async {
    if (_syncing) return;
    _syncing = true;
    try {
      await _syncClient.retryFailed();
      await _syncClient.pushPending();
      await _syncClient.pullDelta();
      await _mediaUploadService.uploadPending();
    } catch (_) {
    } finally {
      _syncing = false;
    }
  }
}
```

### Крок 3: Додати метод `retryFailed` в `riad_mobile/lib/data/sync/sync_client.dart`

Додати після метода `watchPendingCount()` (рядок 461):
```dart
Future<void> retryFailed() async {
    final failedOps = await (_db.select(_db.pendingOps)
      ..where((t) => t.status.equals('failed')))
        .get();
    for (final op in failedOps) {
      final createdAt = DateTime.fromMillisecondsSinceEpoch(op.createdAt);
      final elapsed = DateTime.now().difference(createdAt);
      if (elapsed.inMinutes < 5) continue;
      await _db.updatePendingOpStatus(op.id, 'pending');
    }
  }
```

### Крок 4: Виправити тест `riad_mobile/test/s2/sync_client_test.dart`

Рядок 589: замінити `syncClient._handleConflict` на `syncClient.handleConflict`

## Верифікація
```bash
cd "/home/joker/RIAD CRM/riad_mobile" && flutter analyze
cd "/home/joker/RIAD CRM/riad_mobile" && flutter test test/s2/sync_client_test.dart
cd "/home/joker/RIAD CRM" && python -m unittest tests.s1.test_s1_sync -v
```

## Лог
Запиши результат у файл: `.mimocode/plans/e4-session2-log.md`
```

---

## ПРОМТ 3: Сесія 3 — Drive bridge + Tombstone guard + Integration tests

```
Ти — Flutter + Python розробник. Виконай завдання.

## Роль
Ти завершуєш offline-sync: додаєш bridge між Drive upload та sync, захист від resurrection, та інтеграційні тести.

## Контекст
Є `media_upload_service.dart` який завантажує файли на сервер. Після upload оновлює MediaAsset drive_file_id.
Але він НЕ створює PendingOp для sync — тому зміна не потрапляє на інші пристрої.
Є `database.dart` з Drift таблицями. Tombstoned записи (riadDeleted=true) можна "воскресити" створивши новий запис з тим самим UUID.
Немає інтеграційних тестів для повного sync flow.

## Завдання

### Крок 1: Drive upload → sync bridge

В `riad_mobile/lib/data/sync/media_upload_service.dart`:
- Додати `import 'dart:convert';`
- Після рядка 54 (`await db.updatePendingMediaUploadStatus(upload.id, 'done')`) додати:
```dart
if (driveFileId != null) {
              await db.createPendingOp(PendingOpsCompanion.insert(
                doctype: 'Media Asset',
                name: upload.clientUuid,
                op: 'update',
                payload: jsonEncode({
                  'scalars': {'drive_file_id': driveFileId},
                  'additive': {},
                }),
                createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
              ));
            }
```

### Крок 2: Tombstone resurrection guard

В `riad_mobile/lib/data/local/database.dart`, після метода `watchChecklistItems` (рядок 412), додати:
```dart
Future<bool> isTombstoned(String clientUuid) async {
    final visit = await (select(visits)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (visit != null) return visit.riadDeleted;
    final instance = await (select(checklistInstances)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (instance != null) return instance.riadDeleted;
    final map = await (select(installationMaps)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (map != null) return map.riadDeleted;
    return false;
  }
```

### Крок 3: Інтеграційний тест

Створити файл `tests/s1/test_s1_sync_integration.py`:
```python
"""E4 Integration Test — push → conflict → resolve → pull"""
import asyncio
import json
import os
import sys
import unittest
from unittest.mock import AsyncMock, patch

_services_root = os.path.join(
    os.path.dirname(__file__), "..", "..", "services", "security-api"
)
if os.path.isdir(_services_root):
    sys.path.insert(0, _services_root)


def _run(coro):
    return asyncio.get_event_loop().run_until_complete(coro)


class TestSyncIntegration(unittest.TestCase):
    def test_push_conflict_resolve_pull_cycle(self):
        from app.schemas.sync import (
            SyncPullRequest,
            SyncPushItem,
            SyncPushRequest,
            SyncResolveRequest,
        )
        from app.services.sync_service import (
            _encode_watermark,
            pull_changes,
            push_batch,
            resolve_conflict,
        )

        existing_doc = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 3,
                "riad_deleted": 0,
                "status": "Server",
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }
        conflict_doc = {
            "data": {
                "name": "SC-001",
                "conflict_doctype": "Visit",
                "conflict_docname": "uuid-visit-1",
                "conflict_field": "status",
                "server_value": "Server",
                "client_value": "Client",
                "resolved": 0,
            }
        }
        updated_visit = {
            "data": {
                "name": "uuid-visit-1",
                "riad_version": 4,
                "riad_deleted": 0,
                "status": "Client",
                "engineer": "eng@riad.fun",
                "materials": [],
                "photos": [],
            }
        }

        call_count = [0]

        def _get(path, params=None, sid=""):
            call_count[0] += 1
            if "Sync Conflict" in path:
                return conflict_doc
            if "Visit/uuid-visit-1" in path and call_count[0] > 5:
                return updated_visit
            return existing_doc

        with patch(
            "app.services.sync_service.frappe_get", side_effect=_get
        ), patch(
            "app.services.sync_service.frappe_post", new_callable=AsyncMock
        ) as mock_post, patch(
            "app.services.sync_service.frappe_put", new_callable=AsyncMock
        ) as mock_put:
            mock_post.return_value = {"data": {"name": "SC-001"}}
            mock_put.return_value = {"data": {}}

            push_req = SyncPushRequest(
                device_id="d1",
                batch=[
                    SyncPushItem(
                        doctype="Visit",
                        name="uuid-visit-1",
                        op="upsert",
                        client_base_version=2,
                        scalars={"status": "Client"},
                    )
                ],
            )
            push_result = _run(
                push_batch(push_req, user_id="eng", sid="sid")
            )
            self.assertEqual(push_result.results[0].status, "conflict")

            resolve_req = SyncResolveRequest(
                conflict_id="SC-001", chosen="client"
            )
            resolve_result = _run(
                resolve_conflict(resolve_req, user_id="eng", sid="sid")
            )
            self.assertEqual(resolve_result.status, "resolved")

            pull_req = SyncPullRequest(
                device_id="d1",
                watermark=_encode_watermark(
                    "2020-01-01 00:00:00.000000"
                ),
            )
            pull_result = _run(pull_changes(pull_req, sid="sid"))
            self.assertTrue(pull_result.next_watermark)


if __name__ == "__main__":
    unittest.main()
```

### Крок 4: Запустити всі тести
```bash
cd "/home/joker/RIAD CRM" && python -m unittest tests.s1.test_s1_sync -v
cd "/home/joker/RIAD CRM" && python -m unittest tests.s1.test_s1_sync_integration -v
cd "/home/joker/RIAD CRM/riad_mobile" && flutter test test/s2/sync_client_test.dart
cd "/home/joker/RIAD CRM/riad_mobile" && flutter analyze
```

## Лог
Запиши результат у файл: `.mimocode/plans/e4-session3-log.md`
```

---

## Обмеження моделі (mimo-auto)

mimo-auto — lightweight модель. Обмеження:
- Контекст: обмежений, не давати >3000 рядків коду в одному промті
- Точність: для складних змін у 5+ файлах одночасно — високий ризик помилок
- Рекомендація: РОЗДІЛИТИ на 3 сесії

| Сесія | Завдання | Файлів | Час |
|-------|----------|--------|-----|
| 1 | Payload format (БЛОКЕР) | 5 | 30 хв |
| 2 | Background sync + retry + тест | 4 | 1 год |
| 3 | Drive bridge + guard + tests | 3 | 1 год |
