import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

class SyncMeta extends Table {
  IntColumn get rowid => integer().autoIncrement()();
  TextColumn get watermark => text().nullable()();
  TextColumn get deviceId => text()();
}

class PendingOps extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get doctype => text()();
  TextColumn get name => text()();
  TextColumn get op => text()();
  TextColumn get payload => text()();
  IntColumn get baseVersion => integer().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  IntColumn get nextRetryAt => integer().withDefault(const Constant(0))();
}

class Visits extends Table {
  TextColumn get clientUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get visitType => text().nullable()();
  TextColumn get summary => text().nullable()();
  TextColumn get serviceTicket => text().nullable()();
  DateTimeColumn get visitDate => dateTime().nullable()();
  TextColumn get status => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

class VisitMaterials extends Table {
  TextColumn get clientUuid => text()();
  TextColumn get visitUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get itemName => text().nullable()();
  TextColumn get serialNo => text().nullable()();
  IntColumn get qty => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

class VisitPhotos extends Table {
  TextColumn get clientUuid => text()();
  TextColumn get visitUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get driveFileId => text().nullable()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

class ChecklistInstances extends Table {
  TextColumn get clientUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get template => text().nullable()();
  TextColumn get passport => text().nullable()();
  TextColumn get visit => text().nullable()();
  TextColumn get status => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

class ChecklistInstanceItems extends Table {
  TextColumn get itemUuid => text()();
  TextColumn get instanceUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get checkedBy => text().nullable()();
  TextColumn get photo => text().nullable()();
  TextColumn get value => text().nullable()();
  TextColumn get serialNo => text().nullable()();

  @override
  Set<Column> get primaryKey => {itemUuid};
}

class InstallationMaps extends Table {
  TextColumn get clientUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get passport => text().nullable()();
  TextColumn get name_ => text().named('name_').nullable()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

class MountPoints extends Table {
  TextColumn get pointUuid => text()();
  TextColumn get mapUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get type => text().nullable()();
  TextColumn get label => text().nullable()();
  RealColumn get x => real().nullable()();
  RealColumn get y => real().nullable()();
  TextColumn get status => text().nullable()();
  TextColumn get item => text().nullable()();
  TextColumn get serialNo => text().nullable()();
  TextColumn get photo => text().nullable()();

  @override
  Set<Column> get primaryKey => {pointUuid};
}

class CableRoutes extends Table {
  TextColumn get routeUuid => text()();
  TextColumn get mapUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get fromPoint => text().nullable()();
  TextColumn get toPoint => text().nullable()();
  TextColumn get pathJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {routeUuid};
}

class MediaAssets extends Table {
  TextColumn get clientUuid => text()();
  IntColumn get riadVersion => integer().withDefault(const Constant(0))();
  BoolColumn get riadDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get riadDeletedAt => dateTime().nullable()();
  TextColumn get driveFileId => text().nullable()();
  BoolColumn get aiAllowed => boolean().withDefault(const Constant(false))();
  TextColumn get transcriptionStatus => text().nullable()();
  TextColumn get mediaType => text().nullable()();
  TextColumn get tag => text().nullable()();
  TextColumn get parentDoctype => text().nullable()();
  TextColumn get parentName => text().nullable()();
  TextColumn get localPath => text().nullable()();
  TextColumn get transcription => text().nullable()();

  @override
  Set<Column> get primaryKey => {clientUuid};
}

class PendingMediaUploads extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientUuid => text()();
  TextColumn get localPath => text()();
  TextColumn get mediaType => text()();
  TextColumn get tag => text().nullable()();
  TextColumn get parentDoctype => text().nullable()();
  TextColumn get parentName => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class SyncConflicts extends Table {
  TextColumn get conflictId => text()();
  TextColumn get doctype => text()();
  TextColumn get docname => text()();
  TextColumn get fieldName => text()();
  TextColumn get serverValue => text().nullable()();
  TextColumn get clientValue => text().nullable()();
  BoolColumn get resolved => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {conflictId};
}

@DriftDatabase(tables: [
  SyncMeta,
  PendingOps,
  Visits,
  VisitMaterials,
  VisitPhotos,
  ChecklistInstances,
  ChecklistInstanceItems,
  InstallationMaps,
  MountPoints,
  CableRoutes,
  MediaAssets,
  PendingMediaUploads,
  SyncConflicts,
])
class RiadDatabase extends _$RiadDatabase {
  RiadDatabase() : super(_openConnection());

  RiadDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(syncMeta).insert(
            SyncMetaCompanion.insert(
              deviceId: const Uuid().v4(),
            ),
          );
        },
      );

  Future<String?> getWatermark() async {
    final row = await select(syncMeta).getSingleOrNull();
    return row?.watermark;
  }

  Future<String> getDeviceId() async {
    final row = await select(syncMeta).getSingleOrNull();
    if (row == null) {
      final deviceId = const Uuid().v4();
      await into(syncMeta).insert(
        SyncMetaCompanion.insert(deviceId: deviceId),
      );
      return deviceId;
    }
    return row.deviceId;
  }

  Future<void> updateWatermark(String watermark) async {
    await (update(syncMeta)..where((t) => t.rowid.equals(1)))
        .write(SyncMetaCompanion(watermark: Value(watermark)));
  }

  Future<void> upsertVisit(VisitsCompanion visit) async {
    await into(visits).insertOnConflictUpdate(visit);
  }

  Future<void> upsertVisitMaterial(VisitMaterialsCompanion material) async {
    await into(visitMaterials).insertOnConflictUpdate(material);
  }

  Future<void> upsertVisitPhoto(VisitPhotosCompanion photo) async {
    await into(visitPhotos).insertOnConflictUpdate(photo);
  }

  Future<void> upsertChecklistInstance(ChecklistInstancesCompanion instance) async {
    await into(checklistInstances).insertOnConflictUpdate(instance);
  }

  Future<void> upsertChecklistInstanceItem(ChecklistInstanceItemsCompanion item) async {
    await into(checklistInstanceItems).insertOnConflictUpdate(item);
  }

  Future<void> upsertInstallationMap(InstallationMapsCompanion map) async {
    await into(installationMaps).insertOnConflictUpdate(map);
  }

  Future<void> upsertMountPoint(MountPointsCompanion point) async {
    await into(mountPoints).insertOnConflictUpdate(point);
  }

  Future<void> upsertCableRoute(CableRoutesCompanion route) async {
    await into(cableRoutes).insertOnConflictUpdate(route);
  }

  Future<void> upsertMediaAsset(MediaAssetsCompanion asset) async {
    await into(mediaAssets).insertOnConflictUpdate(asset);
  }

  Future<void> softDeleteVisit(String clientUuid) async {
    await (update(visits)..where((t) => t.clientUuid.equals(clientUuid))).write(
      VisitsCompanion(
        riadDeleted: const Value(true),
        riadDeletedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> softDeleteChecklistInstance(String clientUuid) async {
    await (update(checklistInstances)..where((t) => t.clientUuid.equals(clientUuid))).write(
      ChecklistInstancesCompanion(
        riadDeleted: const Value(true),
        riadDeletedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> softDeleteInstallationMap(String clientUuid) async {
    await (update(installationMaps)..where((t) => t.clientUuid.equals(clientUuid))).write(
      InstallationMapsCompanion(
        riadDeleted: const Value(true),
        riadDeletedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<void> softDeleteMediaAsset(String clientUuid) async {
    await (update(mediaAssets)..where((t) => t.clientUuid.equals(clientUuid))).write(
      MediaAssetsCompanion(
        riadDeleted: const Value(true),
        riadDeletedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  Future<int> createPendingOp(PendingOpsCompanion op) async {
    return into(pendingOps).insert(op);
  }

  Future<List<PendingOp>> getPendingOps() async {
    return (select(pendingOps)..where((t) => t.status.equals('pending'))).get();
  }

  Future<void> updatePendingOpStatus(int id, String status) async {
    await (update(pendingOps)..where((t) => t.id.equals(id)))
        .write(PendingOpsCompanion(status: Value(status)));
  }

  Future<void> deletePendingOp(int id) async {
    await (delete(pendingOps)..where((t) => t.id.equals(id))).go();
  }

  Future<List<PendingOp>> getFailedPendingOps() async {
    return (select(pendingOps)..where((t) => t.status.equals('failed'))).get();
  }

  Future<List<PendingOp>> getRetryablePendingOps() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return (select(pendingOps)
          ..where((t) => t.status.equals('failed'))
          ..where((t) => t.nextRetryAt.isSmallerOrEqualValue(now)))
        .get();
  }

  Future<void> updatePendingOpRetry(int id, int retryCount, int nextRetryAt) async {
    await (update(pendingOps)..where((t) => t.id.equals(id))).write(
      PendingOpsCompanion(
        retryCount: Value(retryCount),
        nextRetryAt: Value(nextRetryAt),
      ),
    );
  }

  Stream<int> watchPendingCount() {
    final count = pendingOps.id.count();
    return (selectOnly(pendingOps)..addColumns([count]))
        .watchSingle()
        .map((row) => row.read(count)!);
  }

  Future<void> insertConflict(SyncConflictsCompanion conflict) async {
    await into(syncConflicts).insertOnConflictUpdate(conflict);
  }

  Future<List<SyncConflict>> getUnresolvedConflicts() async {
    return (select(syncConflicts)..where((t) => t.resolved.equals(false))).get();
  }

  Future<void> resolveConflict(String conflictId, bool resolved) async {
    await (update(syncConflicts)..where((t) => t.conflictId.equals(conflictId)))
        .write(SyncConflictsCompanion(resolved: Value(resolved)));
  }

  // --- PendingMediaUpload methods ---

  Future<int> createPendingMediaUpload(PendingMediaUploadsCompanion upload) async {
    return into(pendingMediaUploads).insert(upload);
  }

  Future<List<PendingMediaUpload>> getPendingMediaUploads() async {
    return (select(pendingMediaUploads)..where((t) => t.status.equals('pending'))).get();
  }

  Future<void> updatePendingMediaUploadStatus(int id, String status) async {
    await (update(pendingMediaUploads)..where((t) => t.id.equals(id)))
        .write(PendingMediaUploadsCompanion(status: Value(status)));
  }

  Future<void> deletePendingMediaUpload(int id) async {
    await (delete(pendingMediaUploads)..where((t) => t.id.equals(id))).go();
  }

  Stream<int> watchPendingMediaUploadCount() {
    final count = pendingMediaUploads.id.count();
    return (selectOnly(pendingMediaUploads)..addColumns([count]))
        .watchSingle()
        .map((row) => row.read(count)!);
  }

  // --- Extended MediaAsset methods ---

  Future<void> updateMediaAssetDriveFileId(String clientUuid, String driveFileId) async {
    await (update(mediaAssets)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(MediaAssetsCompanion(driveFileId: Value(driveFileId)));
  }

  Future<void> updateMediaAssetTranscription(String clientUuid, String transcription, String status) async {
    await (update(mediaAssets)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(MediaAssetsCompanion(
          transcription: Value(transcription),
          transcriptionStatus: Value(status),
        ));
  }

  // --- Visit status methods ---

  Future<void> updateVisitStatus(String clientUuid, String status) async {
    await (update(visits)..where((t) => t.clientUuid.equals(clientUuid)))
        .write(VisitsCompanion(status: Value(status)));
  }

  Stream<List<Visit>> watchVisits() {
    return (select(visits)..where((t) => t.riadDeleted.equals(false))
      ..orderBy([(t) => OrderingTerm.desc(t.visitDate)])).watch();
  }

  Stream<List<ChecklistInstanceItem>> watchChecklistItems(String instanceUuid) {
    return (select(checklistInstanceItems)
      ..where((t) => t.instanceUuid.equals(instanceUuid))
      ..where((t) => t.riadDeleted.equals(false))).watch();
  }

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

    final asset = await (select(mediaAssets)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (asset != null) return asset.riadDeleted;

    final material = await (select(visitMaterials)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (material != null) {
      final parent = await (select(visits)
            ..where((t) => t.clientUuid.equals(material.visitUuid)))
          .getSingleOrNull();
      if (parent != null && parent.riadDeleted) return true;
    }

    final photo = await (select(visitPhotos)
          ..where((t) => t.clientUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (photo != null) {
      final parent = await (select(visits)
            ..where((t) => t.clientUuid.equals(photo.visitUuid)))
          .getSingleOrNull();
      if (parent != null && parent.riadDeleted) return true;
    }

    final item = await (select(checklistInstanceItems)
          ..where((t) => t.itemUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (item != null) {
      final parent = await (select(checklistInstances)
            ..where((t) => t.clientUuid.equals(item.instanceUuid)))
          .getSingleOrNull();
      if (parent != null && parent.riadDeleted) return true;
    }

    final point = await (select(mountPoints)
          ..where((t) => t.pointUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (point != null) {
      final parent = await (select(installationMaps)
            ..where((t) => t.clientUuid.equals(point.mapUuid)))
          .getSingleOrNull();
      if (parent != null && parent.riadDeleted) return true;
    }

    final route = await (select(cableRoutes)
          ..where((t) => t.routeUuid.equals(clientUuid)))
        .getSingleOrNull();
    if (route != null) {
      final parent = await (select(installationMaps)
            ..where((t) => t.clientUuid.equals(route.mapUuid)))
          .getSingleOrNull();
      if (parent != null && parent.riadDeleted) return true;
    }

    return false;
  }

  Future<bool> visitMaterialExistsBySerial(String serialNo) async {
    final result = await (select(visitMaterials)
      ..where((t) => t.serialNo.equals(serialNo))
      ..limit(1)).get();
    return result.isNotEmpty;
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'riad.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
