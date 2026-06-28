import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/core/db/database.dart';
import 'package:riad_mobile/core/sync/sync_queue_service.dart';
import 'package:riad_mobile/features/map/widgets/floor_plan_editor.dart';

class _FakeSyncQueue implements SyncQueueService {
  final List<Map<String, dynamic>> enqueued = [];

  @override
  Future<void> enqueue({
    required String docType,
    required String name,
    required String operation,
    required Map<String, dynamic> payload,
    int clientVersion = 0,
  }) async {
    enqueued.add({
      'docType': docType,
      'name': name,
      'operation': operation,
      'payload': payload,
    });
  }

  @override
  Future<List<SyncQueueData>> getPending() async => [];

  @override
  Future<void> markDone(int id) async {}

  @override
  Future<void> markFailed(int id) async {}
}

Widget _wrap(Widget child, _FakeSyncQueue sync) => ProviderScope(
      overrides: [
        syncQueueProvider.overrideWithValue(sync),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('FloorPlanEditor', () {
    testWidgets('renders fallback text when no base plan', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        const FloorPlanEditor(
          objectId: 'obj-1',
          basePlanUrl: null,
          points: [],
          canEdit: true,
        ),
        sync,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Немає плану приміщення'), findsOneWidget);
    });

    testWidgets('shows hint text when canEdit is true', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        const FloorPlanEditor(
          objectId: 'obj-1',
          basePlanUrl: null,
          points: [],
          canEdit: true,
        ),
        sync,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Тап — додати точку'), findsOneWidget);
    });

    testWidgets('no hint text when canEdit is false', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        const FloorPlanEditor(
          objectId: 'obj-1',
          basePlanUrl: null,
          points: [],
          canEdit: false,
        ),
        sync,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Тап — додати точку'), findsNothing);
    });

    testWidgets('renders existing points', (tester) async {
      final sync = _FakeSyncQueue();
      const points = [
        {'id': 'p1', 'x': 0.3, 'y': 0.4, 'label': 'Камера 1', 'status': 'planned'},
        {'id': 'p2', 'x': 0.7, 'y': 0.6, 'label': 'Камера 2', 'status': 'installed'},
      ];
      await tester.pumpWidget(_wrap(
        const FloorPlanEditor(
          objectId: 'obj-1',
          basePlanUrl: null,
          points: points,
          canEdit: false,
        ),
        sync,
      ));
      await tester.pumpAndSettle();
      expect(find.byType(Tooltip), findsNWidgets(2));
    });

    testWidgets('tap adds point and enqueues sync (canEdit=true)', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 400,
          height: 400,
          child: FloorPlanEditor(
            objectId: 'obj-1',
            basePlanUrl: null,
            points: const [],
            canEdit: true,
          ),
        ),
        sync,
      ));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();

      expect(sync.enqueued.length, 1);
      expect(sync.enqueued[0]['operation'], 'create');
      expect(sync.enqueued[0]['docType'], 'Installation Point');
    });

    testWidgets('tap does nothing when canEdit=false', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(_wrap(
        SizedBox(
          width: 400,
          height: 400,
          child: FloorPlanEditor(
            objectId: 'obj-1',
            basePlanUrl: null,
            points: const [],
            canEdit: false,
          ),
        ),
        sync,
      ));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(200, 200));
      await tester.pumpAndSettle();

      expect(sync.enqueued, isEmpty);
    });
  });
}
