import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:riad_mobile/data/local/database.dart';

void main() {
  late RiadDatabase db;

  setUp(() async {
    db = RiadDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('Database Schema', () {
    test('SyncMeta створюється при ініціалізації', () async {
      final meta = await db.select(db.syncMeta).getSingleOrNull();
      expect(meta, isNotNull);
      expect(meta!.deviceId, isNotEmpty);
      expect(meta.watermark, isNull);
    });

    test('device_id генерується один раз', () async {
      final deviceId1 = await db.getDeviceId();
      final deviceId2 = await db.getDeviceId();
      expect(deviceId1, equals(deviceId2));
    });

    test('watermark оновлюється', () async {
      await db.updateWatermark('test-watermark');
      final watermark = await db.getWatermark();
      expect(watermark, 'test-watermark');
    });
  });

  group('Visit Operations', () {
    test('upsertVisit створює новий запис', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'test-visit-1',
          visitType: const Value('installation'),
          summary: const Value('Test visit'),
        ),
      );

      final visits = await db.select(db.visits).get();
      expect(visits.length, 1);
      expect(visits.first.clientUuid, 'test-visit-1');
      expect(visits.first.visitType, 'installation');
    });

    test('upsertVisit оновлює існуючий запис', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'test-visit-2',
          summary: const Value('Original'),
        ),
      );

      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'test-visit-2',
          summary: const Value('Updated'),
        ),
      );

      final visits = await db.select(db.visits).get();
      expect(visits.length, 1);
      expect(visits.first.summary, 'Updated');
    });

    test('softDeleteVisit встановлює riadDeleted', () async {
      await db.upsertVisit(
        VisitsCompanion.insert(
          clientUuid: 'visit-to-delete',
        ),
      );

      await db.softDeleteVisit('visit-to-delete');

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('visit-to-delete')))
          .getSingle();
      expect(visit.riadDeleted, true);
      expect(visit.riadDeletedAt, isNotNull);
    });
  });

  group('PendingOps Operations', () {
    test('createPendingOp створює запис', () async {
      final id = await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'test-uuid',
          op: 'create',
          payload: '{"scalars": {}, "additive": {}}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      expect(id, greaterThan(0));
    });

    test('getPendingOps повертає лише pending', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'uuid-1',
          op: 'create',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'uuid-2',
          op: 'update',
          payload: '{}',
          status: const Value('inflight'),
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final pending = await db.getPendingOps();
      expect(pending.length, 1);
      expect(pending.first.name, 'uuid-1');
    });

    test('updatePendingOpStatus оновлює статус', () async {
      final id = await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'test-uuid',
          op: 'create',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await db.updatePendingOpStatus(id, 'inflight');

      final ops = await (db.select(db.pendingOps)
            ..where((t) => t.id.equals(id)))
          .getSingle();
      expect(ops.status, 'inflight');
    });

    test('deletePendingOp видаляє запис', () async {
      final id = await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'test-uuid',
          op: 'create',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await db.deletePendingOp(id);

      final ops = await db.getPendingOps();
      expect(ops.length, 0);
    });
  });

  group('SyncConflicts Operations', () {
    test('insertConflict створює запис', () async {
      await db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: 'SC-001',
          doctype: 'Visit',
          docname: 'visit-1',
          fieldName: 'summary',
          serverValue: const Value('Server'),
          clientValue: const Value('Client'),
        ),
      );

      final conflicts = await db.select(db.syncConflicts).get();
      expect(conflicts.length, 1);
      expect(conflicts.first.conflictId, 'SC-001');
    });

    test('getUnresolvedConflicts повертає лише незавершені', () async {
      await db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: 'SC-002',
          doctype: 'Visit',
          docname: 'visit-2',
          fieldName: 'summary',
        ),
      );

      await db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: 'SC-003',
          doctype: 'Visit',
          docname: 'visit-3',
          fieldName: 'status',
          resolved: const Value(true),
        ),
      );

      final unresolved = await db.getUnresolvedConflicts();
      expect(unresolved.length, 1);
      expect(unresolved.first.conflictId, 'SC-002');
    });

    test('resolveConflict оновлює resolved', () async {
      await db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: 'SC-004',
          doctype: 'Visit',
          docname: 'visit-4',
          fieldName: 'summary',
        ),
      );

      await db.resolveConflict('SC-004', true);

      final conflict = await (db.select(db.syncConflicts)
            ..where((t) => t.conflictId.equals('SC-004')))
          .getSingle();
      expect(conflict.resolved, true);
    });
  });

  group('watchPendingCount', () {
    test('watchPendingCount повертає кількість pending операцій', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'uuid-1',
          op: 'create',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'uuid-2',
          op: 'update',
          payload: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

      final stream = db.watchPendingCount();
      final count = await stream.first;
      expect(count, 2);
    });
  });

  group('Additive Tables', () {
    test('upsertVisitMaterial створює запис', () async {
      await db.upsertVisitMaterial(
        VisitMaterialsCompanion.insert(
          clientUuid: 'material-1',
          visitUuid: 'visit-1',
          itemName: const Value('Camera'),
          qty: const Value(2),
        ),
      );

      final materials = await db.select(db.visitMaterials).get();
      expect(materials.length, 1);
      expect(materials.first.itemName, 'Camera');
      expect(materials.first.qty, 2);
    });

    test('upsertVisitPhoto створює запис', () async {
      await db.upsertVisitPhoto(
        VisitPhotosCompanion.insert(
          clientUuid: 'photo-1',
          visitUuid: 'visit-1',
          driveFileId: const Value('drive-id-123'),
        ),
      );

      final photos = await db.select(db.visitPhotos).get();
      expect(photos.length, 1);
      expect(photos.first.driveFileId, 'drive-id-123');
    });

    test('upsertChecklistInstance створює запис', () async {
      await db.upsertChecklistInstance(
        ChecklistInstancesCompanion.insert(
          clientUuid: 'checklist-1',
          template: const Value('template-1'),
          status: const Value('pending'),
        ),
      );

      final instances = await db.select(db.checklistInstances).get();
      expect(instances.length, 1);
      expect(instances.first.template, 'template-1');
    });

    test('upsertInstallationMap створює запис', () async {
      await db.upsertInstallationMap(
        InstallationMapsCompanion.insert(
          clientUuid: 'map-1',
          passport: const Value('passport-1'),
        ),
      );

      final maps = await db.select(db.installationMaps).get();
      expect(maps.length, 1);
      expect(maps.first.passport, 'passport-1');
    });

    test('upsertMediaAsset створює запис', () async {
      await db.upsertMediaAsset(
        MediaAssetsCompanion.insert(
          clientUuid: 'media-1',
          driveFileId: const Value('drive-id-456'),
          aiAllowed: const Value(true),
        ),
      );

      final assets = await db.select(db.mediaAssets).get();
      expect(assets.length, 1);
      expect(assets.first.driveFileId, 'drive-id-456');
      expect(assets.first.aiAllowed, true);
    });
  });

  group('Tombstone Operations', () {
    test('softDeleteChecklistInstance працює', () async {
      await db.upsertChecklistInstance(
        ChecklistInstancesCompanion.insert(
          clientUuid: 'checklist-to-delete',
        ),
      );

      await db.softDeleteChecklistInstance('checklist-to-delete');

      final instance = await (db.select(db.checklistInstances)
            ..where((t) => t.clientUuid.equals('checklist-to-delete')))
          .getSingle();
      expect(instance.riadDeleted, true);
    });

    test('softDeleteInstallationMap працює', () async {
      await db.upsertInstallationMap(
        InstallationMapsCompanion.insert(
          clientUuid: 'map-to-delete',
        ),
      );

      await db.softDeleteInstallationMap('map-to-delete');

      final map = await (db.select(db.installationMaps)
            ..where((t) => t.clientUuid.equals('map-to-delete')))
          .getSingle();
      expect(map.riadDeleted, true);
    });

    test('softDeleteMediaAsset працює', () async {
      await db.upsertMediaAsset(
        MediaAssetsCompanion.insert(
          clientUuid: 'media-to-delete',
        ),
      );

      await db.softDeleteMediaAsset('media-to-delete');

      final asset = await (db.select(db.mediaAssets)
            ..where((t) => t.clientUuid.equals('media-to-delete')))
          .getSingle();
      expect(asset.riadDeleted, true);
    });
  });

  group('isTombstoned', () {
    test('повертає true для видаленого Visit', () async {
      await db.upsertVisit(VisitsCompanion.insert(clientUuid: 'vt-1'));
      await db.softDeleteVisit('vt-1');
      expect(await db.isTombstoned('vt-1'), true);
    });

    test('повертає false для активного Visit', () async {
      await db.upsertVisit(VisitsCompanion.insert(clientUuid: 'vt-2'));
      expect(await db.isTombstoned('vt-2'), false);
    });

    test('повертає true для material видаленого Visit', () async {
      await db.upsertVisit(VisitsCompanion.insert(clientUuid: 'vt-3'));
      await db.upsertVisitMaterial(VisitMaterialsCompanion.insert(
        clientUuid: 'vm-1',
        visitUuid: 'vt-3',
      ));
      await db.softDeleteVisit('vt-3');
      expect(await db.isTombstoned('vm-1'), true);
    });

    test('повертає true для photo видаленого Visit', () async {
      await db.upsertVisit(VisitsCompanion.insert(clientUuid: 'vt-4'));
      await db.upsertVisitPhoto(VisitPhotosCompanion.insert(
        clientUuid: 'vp-1',
        visitUuid: 'vt-4',
      ));
      await db.softDeleteVisit('vt-4');
      expect(await db.isTombstoned('vp-1'), true);
    });

    test('повертає true для item видаленого ChecklistInstance', () async {
      await db.upsertChecklistInstance(ChecklistInstancesCompanion.insert(
        clientUuid: 'ci-1',
      ));
      await db.upsertChecklistInstanceItem(ChecklistInstanceItemsCompanion.insert(
        itemUuid: 'cii-1',
        instanceUuid: 'ci-1',
      ));
      await db.softDeleteChecklistInstance('ci-1');
      expect(await db.isTombstoned('cii-1'), true);
    });

    test('повертає true для point видаленої InstallationMap', () async {
      await db.upsertInstallationMap(InstallationMapsCompanion.insert(
        clientUuid: 'im-1',
      ));
      await db.upsertMountPoint(MountPointsCompanion.insert(
        pointUuid: 'mp-1',
        mapUuid: 'im-1',
      ));
      await db.softDeleteInstallationMap('im-1');
      expect(await db.isTombstoned('mp-1'), true);
    });

    test('повертає true для route видаленої InstallationMap', () async {
      await db.upsertInstallationMap(InstallationMapsCompanion.insert(
        clientUuid: 'im-2',
      ));
      await db.upsertCableRoute(CableRoutesCompanion.insert(
        routeUuid: 'cr-1',
        mapUuid: 'im-2',
      ));
      await db.softDeleteInstallationMap('im-2');
      expect(await db.isTombstoned('cr-1'), true);
    });

    test('повертає true для видаленого MediaAsset', () async {
      await db.upsertMediaAsset(MediaAssetsCompanion.insert(
        clientUuid: 'ma-1',
        mediaType: const Value('photo'),
        aiAllowed: const Value(false),
      ));
      await db.softDeleteMediaAsset('ma-1');
      expect(await db.isTombstoned('ma-1'), true);
    });

    test('повертає false для неіснуючого UUID', () async {
      expect(await db.isTombstoned('nonexistent'), false);
    });
  });

  group('resolveConflictFieldValue', () {
    test('оновлює поле status для Visit за conflict.fieldName', () async {
      await db.upsertVisit(VisitsCompanion.insert(
        clientUuid: 'visit-field-resolve',
        status: const Value('old_status'),
      ));

      await db.insertConflict(SyncConflictsCompanion.insert(
        conflictId: 'SC-FIELD-001',
        doctype: 'Visit',
        docname: 'visit-field-resolve',
        fieldName: 'status',
        serverValue: const Value('server_status'),
        clientValue: const Value('client_status'),
      ));

      await db.resolveConflictFieldValue('SC-FIELD-001');

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('visit-field-resolve')))
          .getSingle();
      expect(visit.status, 'client_status');
    });

    test('оновлює поле summary для Visit за conflict.fieldName', () async {
      await db.upsertVisit(VisitsCompanion.insert(
        clientUuid: 'visit-summary-resolve',
        summary: const Value('old_summary'),
      ));

      await db.insertConflict(SyncConflictsCompanion.insert(
        conflictId: 'SC-FIELD-002',
        doctype: 'Visit',
        docname: 'visit-summary-resolve',
        fieldName: 'summary',
        serverValue: const Value('server_summary'),
        clientValue: const Value('client_summary'),
      ));

      await db.resolveConflictFieldValue('SC-FIELD-002');

      final visit = await (db.select(db.visits)
            ..where((t) => t.clientUuid.equals('visit-summary-resolve')))
          .getSingle();
      expect(visit.summary, 'client_summary');
    });

    test('позначає conflict як resolved', () async {
      await db.upsertVisit(VisitsCompanion.insert(
        clientUuid: 'visit-resolved-mark',
        status: const Value('x'),
      ));

      await db.insertConflict(SyncConflictsCompanion.insert(
        conflictId: 'SC-FIELD-003',
        doctype: 'Visit',
        docname: 'visit-resolved-mark',
        fieldName: 'status',
        clientValue: const Value('y'),
      ));

      await db.resolveConflictFieldValue('SC-FIELD-003');

      final conflict = await (db.select(db.syncConflicts)
            ..where((t) => t.conflictId.equals('SC-FIELD-003')))
          .getSingle();
      expect(conflict.resolved, true);
    });

    test('для Checklist Instance оновлює вказане поле', () async {
      await db.upsertChecklistInstance(ChecklistInstancesCompanion.insert(
        clientUuid: 'ci-field-resolve',
        status: const Value('old'),
      ));

      await db.insertConflict(SyncConflictsCompanion.insert(
        conflictId: 'SC-FIELD-004',
        doctype: 'Checklist Instance',
        docname: 'ci-field-resolve',
        fieldName: 'status',
        clientValue: const Value('new_status'),
      ));

      await db.resolveConflictFieldValue('SC-FIELD-004');

      final ci = await (db.select(db.checklistInstances)
            ..where((t) => t.clientUuid.equals('ci-field-resolve')))
          .getSingle();
      expect(ci.status, 'new_status');
    });
  });
}
