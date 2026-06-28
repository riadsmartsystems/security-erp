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

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.database.customStatement('DROP TABLE IF EXISTS task_cache');
        await m.create(taskCache);
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
