import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/connectivity/connectivity_service.dart';
import '../../../core/db/database.dart';

final objectListProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final isOnline = ref.watch(connectivityProvider).value ?? false;
  final db = ref.read(databaseProvider);

  if (!isOnline) {
    final rows = await (db.select(db.objectPassports)
          ..where((t) => t.riadDeleted.equals(false)))
        .get();
    return rows.map((r) => jsonDecode(r.payload) as Map<String, dynamic>).toList();
  }

  final dio = ref.read(dioProvider);
  final resp = await dio.get('/objects');
  final list = (resp.data as Map<String, dynamic>)['data'] as List? ??
      resp.data as List? ??
      <dynamic>[];

  for (final item in list) {
    final m = item as Map<String, dynamic>;
    final id = m['id'] as String? ?? m['name'] as String? ?? '';
    if (id.isEmpty) continue;
    await db.into(db.objectPassports).insertOnConflictUpdate(
      ObjectPassportsCompanion.insert(
        id: id,
        name: m['name'] as String? ?? '',
        address: Value(m['address'] as String? ?? ''),
        customerId: m['customer_id'] as String? ?? '',
        mapKind: Value(m['map_kind'] as String? ?? 'floor'),
        basePlanUrl: Value(m['base_plan_url'] as String?),
        payload: Value(jsonEncode(m)),
      ),
    );
  }
  return list.cast<Map<String, dynamic>>();
});

final objectByIdProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, id) async {
  final isOnline = ref.watch(connectivityProvider).value ?? false;
  final db = ref.read(databaseProvider);

  if (!isOnline) {
    final row = await (db.select(db.objectPassports)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return jsonDecode(row.payload) as Map<String, dynamic>;
  }

  final dio = ref.read(dioProvider);
  final resp = await dio.get('/objects/$id');
  final data = resp.data as Map<String, dynamic>;

  await db.into(db.objectPassports).insertOnConflictUpdate(
    ObjectPassportsCompanion.insert(
      id: id,
      name: data['name'] as String? ?? '',
      address: Value(data['address'] as String? ?? ''),
      customerId: data['customer_id'] as String? ?? '',
      mapKind: Value(data['map_kind'] as String? ?? 'floor'),
      basePlanUrl: Value(data['base_plan_url'] as String?),
      payload: Value(jsonEncode(data)),
    ),
  );
  return data;
});
