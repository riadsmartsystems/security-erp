import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';
import '../task_model.dart';

/// Tasks today: API → Drift cache; offline → from cache
final tasksProvider = FutureProvider.autoDispose<List<Task>>((ref) async {
  final isOnline = ref.watch(connectivityProvider).value ?? false;
  final db = ref.read(databaseProvider);

  if (!isOnline) {
    final rows = await db.select(db.taskCache).get();
    return rows
        .map((r) => Task.fromJson({
              'id': r.id,
              'type': r.taskType,
              'title': r.title,
              'object_name': r.objectName,
              'address': r.address,
              'status': r.status,
              'due_time': r.dueTime,
            }))
        .toList();
  }

  final dio = ref.read(dioProvider);
  final resp = await dio.get('/tasks/today');
  final data = (resp.data as Map<String, dynamic>)['tasks'] as List;
  final tasks =
      data.map((e) => Task.fromJson(e as Map<String, dynamic>)).toList();

  await db.delete(db.taskCache).go();
  await db.batch((batch) {
    for (final t in tasks) {
      batch.insert(
        db.taskCache,
        TaskCacheCompanion.insert(
          id: t.id,
          taskType: t.type.name,
          title: t.title,
          objectName: Value(t.objectName),
          address: Value(t.address),
          status: t.status,
          dueTime: Value(t.dueTime),
          cachedAt: Value(DateTime.now()),
        ),
      );
    }
  });

  return tasks;
});

enum AiStatus { ok, degraded, manual }

final aiStatusProvider = FutureProvider.autoDispose<AiStatus>((ref) async {
  final isOnline = ref.watch(connectivityProvider).value ?? false;
  if (!isOnline) return AiStatus.manual;

  try {
    final dio = ref.read(dioProvider);
    final resp = await dio.get('/ai/degradation');
    final status = (resp.data as Map<String, dynamic>)['status'] as String;
    return switch (status) {
      'ok' => AiStatus.ok,
      'degraded' => AiStatus.degraded,
      _ => AiStatus.manual,
    };
  } catch (_) {
    return AiStatus.manual;
  }
});

/// Pending sync count from Drift sync_queue
final pendingCountProvider = StreamProvider.autoDispose<int>((ref) {
  final db = ref.read(databaseProvider);
  return (db.select(db.syncQueue)
        ..where((t) => t.status.equals('pending')))
      .watch()
      .map((rows) => rows.length);
});
