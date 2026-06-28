import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:riad_mobile/core/db/database.dart';
import 'package:riad_mobile/core/sync/sync_queue_service.dart';
import 'package:riad_mobile/features/map/widgets/territory_map.dart';

class _FakeSyncQueue implements SyncQueueService {
  @override
  Future<void> enqueue({
    required String docType,
    required String name,
    required String operation,
    required Map<String, dynamic> payload,
    int clientVersion = 0,
  }) async {}

  @override
  Future<List<SyncQueueData>> getPending() async => [];

  @override
  Future<void> markDone(int id) async {}

  @override
  Future<void> markFailed(int id) async {}
}

Widget _wrap(Widget child, _FakeSyncQueue sync) => ProviderScope(
      overrides: [syncQueueProvider.overrideWithValue(sync)],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('TerritoryMap', () {
    testWidgets('renders FlutterMap widget', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        TerritoryMap(objectId: 'obj-1', points: const [], canEdit: false),
        sync,
      ));
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('renders with existing GPS points', (tester) async {
      final sync = _FakeSyncQueue();
      const points = [
        {'id': 'gp1', 'lat': 48.9225, 'lng': 33.4519, 'label': 'GPS точка 1'},
      ];
      await tester.pumpWidget(_wrap(
        TerritoryMap(objectId: 'obj-1', points: points, canEdit: false),
        sync,
      ));
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });

    testWidgets('renders with canEdit=true without error', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        TerritoryMap(objectId: 'obj-1', points: const [], canEdit: true),
        sync,
      ));
      await tester.pump();
      expect(find.byType(FlutterMap), findsOneWidget);
    });
  });
}
