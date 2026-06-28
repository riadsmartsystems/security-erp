import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'tables/visits.dart';
import 'tables/checklist_instances.dart';
import 'tables/checklist_items.dart';
import 'tables/object_passports.dart';
import 'tables/installation_points.dart';
import 'tables/media_assets.dart';
import 'tables/pending_media_uploads.dart';
import 'tables/remote_inspections.dart';
import 'tables/service_requests.dart';
import 'tables/sync_queue.dart';
import 'tables/sync_conflicts.dart';
import 'tables/task_cache.dart';

part 'database.g.dart';

@DriftDatabase(tables: [
  Visits,
  ChecklistInstances,
  ChecklistItems,
  ObjectPassports,
  InstallationPoints,
  MediaAssets,
  PendingMediaUploads,
  RemoteInspections,
  ServiceRequests,
  SyncQueue,
  SyncConflicts,
  TaskCache,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.forTesting(QueryExecutor e) : super(e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.database.customStatement('DROP TABLE IF EXISTS task_cache');
        await m.create(taskCache);
      }
      if (from < 3) {
        // Column renames not supported in SQLite — drop & recreate
        await m.database.customStatement('DROP TABLE IF EXISTS checklist_items');
        await m.create(checklistItems);
        await m.database.customStatement('DROP TABLE IF EXISTS sync_queue');
        await m.create(syncQueue);
      }
      if (from < 4) {
        await m.addColumn(objectPassports, objectPassports.mapKind);
        await m.addColumn(objectPassports, objectPassports.basePlanUrl);
        await m.addColumn(installationPoints, installationPoints.status);
      }
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'riad_mobile_db');
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
