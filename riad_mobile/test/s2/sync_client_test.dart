import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'dart:convert';

import 'package:riad_mobile/data/local/database.dart';
import 'package:riad_mobile/data/sync/sync_client.dart';

@GenerateMocks([http.Client])
import 'sync_client_test.mocks.dart';

void main() {
  late RiadDatabase db;
  late MockClient mockClient;
  late SyncClient syncClient;

  setUp(() async {
    db = RiadDatabase.forTesting(NativeDatabase.memory());
    mockClient = MockClient();
    syncClient = SyncClient(
      db: db,
      baseUrl: 'http://localhost:8000',
      jwtToken: 'test-token',
      client: mockClient,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('pull_creates_local_record', () {
    test('pull з новим документом створює запис у Drift', () async {
      final deviceId = await db.getDeviceId();

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'changes': [
                  {
                    'doctype': 'Visit',
                    'name': 'test-visit-uuid',
                    'riad_version': 1,
                    'riad_deleted': 0,
                    'fields': {
                      'visit_type': 'installation',
                      'summary': 'Test visit',
                      'status': 'in_progress',
                    },
                    'additive': {},
                  }
                ],
                'next_watermark': 'new-watermark-123',
              },
            }),
            200,
          ));

      await syncClient.pullDelta();

      final visits = await db.select(db.visits).get();
      expect(visits.length, 1);
      expect(visits.first.clientUuid, 'test-visit-uuid');
      expect(visits.first.visitType, 'installation');
      expect(visits.first.summary, 'Test visit');
    });
  });

  group('pull_updates_existing', () {
    test('pull з riad_version вищою оновлює запис', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'existing-visit',
          riadVersion: const Value(1),
          summary: const Value('Old summary'),
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'changes': [
                  {
                    'doctype': 'Visit',
                    'name': 'existing-visit',
                    'riad_version': 2,
                    'riad_deleted': 0,
                    'fields': {
                      'summary': 'Updated summary',
                    },
                    'additive': {},
                  }
                ],
                'next_watermark': 'watermark-v2',
              },
            }),
            200,
          ));

      await syncClient.pullDelta();

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('existing-visit')))
          .getSingle();
      expect(visit.summary, 'Updated summary');
      expect(visit.riadVersion, 2);
    });
  });

  group('pull_tombstone', () {
    test('pull з riad_deleted=1 виконує soft-delete', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'visit-to-delete',
          riadVersion: const Value(1),
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'changes': [
                  {
                    'doctype': 'Visit',
                    'name': 'visit-to-delete',
                    'riad_version': 2,
                    'riad_deleted': 1,
                    'fields': {},
                    'additive': {},
                  }
                ],
                'next_watermark': 'watermark-tombstone',
              },
            }),
            200,
          ));

      await syncClient.pullDelta();

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('visit-to-delete')))
          .getSingle();
      expect(visit.riadDeleted, true);
      expect(visit.riadDeletedAt, isNotNull);
    });
  });

  group('pull_advances_watermark', () {
    test('після успішного pull watermark оновлено', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'changes': [],
                'next_watermark': 'advanced-watermark-xyz',
              },
            }),
            200,
          ));

      await syncClient.pullDelta();

      final watermark = await db.getWatermark();
      expect(watermark, 'advanced-watermark-xyz');
    });
  });

  group('pull_union_merge_additive', () {
    test('additive rows = union (дубль uuid не дублюється)', () async {
      await db.upsertVisitMaterial(
        VisitMaterialsCompanion.insert(
          clientUuid: 'material-1',
          visitUuid: 'visit-1',
          itemName: const Value('Camera'),
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'changes': [
                  {
                    'doctype': 'Visit',
                    'name': 'visit-1',
                    'riad_version': 1,
                    'riad_deleted': 0,
                    'fields': {'summary': 'Visit with materials'},
                    'additive': {
                      'visit_material': [
                        {
                          'client_uuid': 'material-1',
                          'item_name': 'Camera',
                          'qty': 1,
                        },
                        {
                          'client_uuid': 'material-2',
                          'item_name': 'Cable',
                          'qty': 5,
                        },
                      ],
                    },
                  }
                ],
                'next_watermark': 'watermark-union',
              },
            }),
            200,
          ));

      await syncClient.pullDelta();

      final materials = await db.select(db.visitMaterials).get();
      expect(materials.length, 2);
      expect(materials.any((m) => m.clientUuid == 'material-1'), true);
      expect(materials.any((m) => m.clientUuid == 'material-2'), true);
    });
  });

  group('push_applied', () {
    test('PendingOp status=pending → відправлено → видалено', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-to-push',
          op: 'create',
          payload: jsonEncode({
            'scalars': {'summary': 'New visit'},
            'additive': {},
          }),
          baseVersion: const Value(0),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'results': [
                  {
                    'name': 'visit-to-push',
                    'status': 'applied',
                    'server_version': 1,
                  }
                ],
              },
            }),
            200,
          ));

      await syncClient.pushPending();

      final pendingOps = await db.getPendingOps();
      expect(pendingOps.length, 0);
    });
  });

  group('push_conflict', () {
    test('server відповідає conflict → SyncConflict збережено', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-conflict',
          op: 'update',
          payload: jsonEncode({
            'scalars': {'summary': 'Client version'},
            'additive': {},
          }),
          baseVersion: const Value(1),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'results': [
                  {
                    'name': 'visit-conflict',
                    'status': 'conflict',
                    'server_version': 2,
                    'conflicts': [
                      {
                        'field': 'summary',
                        'server_value': 'Server version',
                        'client_value': 'Client version',
                        'conflict_id': 'SC-2026-0001',
                      }
                    ],
                  }
                ],
              },
            }),
            200,
          ));

      await syncClient.pushPending();

      final conflicts = await db.select(db.syncConflicts).get();
      expect(conflicts.length, 1);
      expect(conflicts.first.conflictId, 'SC-2026-0001');
      expect(conflicts.first.serverValue, 'Server version');
      expect(conflicts.first.clientValue, 'Client version');
      expect(conflicts.first.resolved, false);

      final pendingOps = await db.getPendingOps();
      expect(pendingOps.length, 0);
    });
  });

  group('push_tombstone', () {
    test('op=delete → сервер tombstoned → soft-delete + видалення', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'visit-to-tombstone',
          riadVersion: const Value(1),
        ),
      );

      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-to-tombstone',
          op: 'delete',
          payload: '{}',
          baseVersion: const Value(1),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'results': [
                  {
                    'name': 'visit-to-tombstone',
                    'status': 'tombstoned',
                    'server_version': 2,
                  }
                ],
              },
            }),
            200,
          ));

      await syncClient.pushPending();

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('visit-to-tombstone')))
          .getSingle();
      expect(visit.riadDeleted, true);

      final pendingOps = await db.getPendingOps();
      expect(pendingOps.length, 0);
    });
  });

  group('push_ignored_duplicate', () {
    test('сервер ignored_duplicate → PendingOp видалено', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-duplicate',
          op: 'create',
          payload: jsonEncode({
            'scalars': {'summary': 'Duplicate'},
            'additive': {},
          }),
          baseVersion: const Value(0),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'results': [
                  {
                    'name': 'visit-duplicate',
                    'status': 'ignored_duplicate',
                    'server_version': 1,
                  }
                ],
              },
            }),
            200,
          ));

      await syncClient.pushPending();

      final pendingOps = await db.getPendingOps();
      expect(pendingOps.length, 0);
    });
  });

  group('push_already_present_additive', () {
    test('additive row already_present → no duplicate', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'visit-additive',
          riadVersion: const Value(1),
        ),
      );

      await db.upsertVisitMaterial(
        VisitMaterialsCompanion.insert(
          clientUuid: 'material-existing',
          visitUuid: 'visit-additive',
          itemName: const Value('Camera'),
        ),
      );

      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-additive',
          op: 'update',
          payload: jsonEncode({
            'scalars': {'summary': 'Updated'},
            'additive': {
              'visit_material': [
                {
                  'client_uuid': 'material-existing',
                  'item_name': 'Camera',
                  'qty': 1,
                },
              ],
            },
          }),
          baseVersion: const Value(1),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'results': [
                  {
                    'name': 'visit-additive',
                    'status': 'merged',
                    'server_version': 2,
                    'additive': {
                      'visit_material': {
                        'added': [],
                        'already_present': ['material-existing'],
                      },
                    },
                  }
                ],
              },
            }),
            200,
          ));

      await syncClient.pushPending();

      final materials = await (db.select(db.visitMaterials)
            ..where((t) => t.visitUuid.equals('visit-additive')))
          .get();
      expect(materials.length, 1);
    });
  });

  group('conflict_resolve_client', () {
    test('вибір Клієнт → POST resolve → локальне поле оновлено', () async {
      await db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: 'SC-TEST-001',
          doctype: 'Visit',
          docname: 'visit-resolve',
          fieldName: 'summary',
          serverValue: const Value('Server value'),
          clientValue: const Value('Client value'),
        ),
      );

      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'visit-resolve',
          riadVersion: const Value(1),
          summary: const Value('Server value'),
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'ok': true}),
            200,
          ));

      await syncClient.handleConflict('visit-resolve', [
        {
          'field': 'summary',
          'server_value': 'Server value',
          'client_value': 'Client value',
          'conflict_id': 'SC-TEST-001',
        },
      ]);

      final conflict = await (db.select(db.syncConflicts)
            ..where((t) => t.conflictId.equals('SC-TEST-001')))
          .getSingle();
      expect(conflict.resolved, false);
    });
  });

  group('conflict_resolve_server', () {
    test('вибір Сервер → локальне поле НЕ змінюється', () async {
      await db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: 'SC-TEST-002',
          doctype: 'Visit',
          docname: 'visit-server-resolve',
          fieldName: 'summary',
          serverValue: const Value('Server value'),
          clientValue: const Value('Client value'),
        ),
      );

      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'visit-server-resolve',
          riadVersion: const Value(1),
          summary: const Value('Server value'),
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'ok': true}),
            200,
          ));

      await syncClient.handleConflict('visit-server-resolve', [
        {
          'field': 'summary',
          'server_value': 'Server value',
          'client_value': 'Client value',
          'conflict_id': 'SC-TEST-002',
        },
      ]);

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('visit-server-resolve')))
          .getSingle();
      expect(visit.summary, 'Server value');
    });
  });

  group('watchPendingCount', () {
    test('watchPendingCount повертає правильну кількість', () async {
      final stream = syncClient.watchPendingCount();

      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-1',
          op: 'create',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-2',
          op: 'update',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final count = await stream.first;
      expect(count, 2);
    });
  });
}
