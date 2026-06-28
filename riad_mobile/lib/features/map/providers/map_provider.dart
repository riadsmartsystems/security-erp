import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/connectivity/connectivity_service.dart';

final mapDataProvider = FutureProvider.family
    .autoDispose<Map<String, dynamic>?, String>((ref, objectId) async {
  final isOnline = ref.watch(connectivityProvider).value ?? false;

  if (!isOnline) return null;

  final dio = ref.read(dioProvider);
  final resp = await dio.get('/objects/$objectId/map');
  return resp.data as Map<String, dynamic>;
});
