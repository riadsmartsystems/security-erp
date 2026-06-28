import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/core/auth/auth_models.dart';
import 'package:riad_mobile/core/auth/auth_notifier.dart';
import 'package:riad_mobile/core/db/database.dart';
import 'package:riad_mobile/core/sync/sync_queue_service.dart';
import 'package:riad_mobile/features/map/installation_map_screen.dart';
import 'package:riad_mobile/features/map/providers/map_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _authState;
  _FakeAuthNotifier(this._authState);

  @override
  Future<AuthState> build() async => _authState;
}

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

final _engineerState = AuthAuthenticated(
  const AuthUser(id: 'u1', email: 'e@e.ua', role: 'engineer', mfaRequired: false),
);
final _installerState = AuthAuthenticated(
  const AuthUser(id: 'u2', email: 'i@i.ua', role: 'installer', mfaRequired: false),
);

Widget _wrap({
  required String objectId,
  required Map<String, dynamic>? mapData,
  required AuthState authState,
}) {
  final sync = _FakeSyncQueue();
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(authState)),
      mapDataProvider(objectId).overrideWith((ref) async => mapData),
      syncQueueProvider.overrideWithValue(sync),
    ],
    child: MaterialApp(home: InstallationMapScreen(objectId: objectId)),
  );
}

void main() {
  group('InstallationMapScreen', () {
    testWidgets('shows loading indicator', (tester) async {
      final sync = _FakeSyncQueue();
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(_engineerState)),
          mapDataProvider('obj-1').overrideWith(
            (ref) => Completer<Map<String, dynamic>?>().future,
          ),
          syncQueueProvider.overrideWithValue(sync),
        ],
        child: MaterialApp(home: InstallationMapScreen(objectId: 'obj-1')),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Немає карти" when data is null', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', mapData: null, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.text('Немає карти'), findsOneWidget);
    });

    testWidgets('shows "Невідомий тип карти" for unknown map_kind', (tester) async {
      await tester.pumpWidget(_wrap(
        objectId: 'obj-1',
        mapData: {'map_kind': 'unknown', 'points': []},
        authState: _engineerState,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Невідомий тип карти'), findsOneWidget);
    });

    testWidgets('floor map: shows FloorPlanEditor (Немає плану приміщення)', (tester) async {
      await tester.pumpWidget(_wrap(
        objectId: 'obj-1',
        mapData: {'map_kind': 'floor', 'base_plan_url': null, 'points': []},
        authState: _engineerState,
      ));
      await tester.pumpAndSettle();
      expect(find.text('Немає плану приміщення'), findsOneWidget);
    });

    testWidgets('engineer: canEdit=true → hint visible in floor mode', (tester) async {
      await tester.pumpWidget(_wrap(
        objectId: 'obj-1',
        mapData: {'map_kind': 'floor', 'base_plan_url': null, 'points': []},
        authState: _engineerState,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Тап — додати точку'), findsOneWidget);
    });

    testWidgets('installer: canEdit=false → no hint in floor mode', (tester) async {
      await tester.pumpWidget(_wrap(
        objectId: 'obj-1',
        mapData: {'map_kind': 'floor', 'base_plan_url': null, 'points': []},
        authState: _installerState,
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Тап — додати точку'), findsNothing);
    });
  });
}
