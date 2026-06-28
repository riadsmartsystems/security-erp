import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riad_mobile/core/auth/auth_models.dart';
import 'package:riad_mobile/core/auth/auth_notifier.dart';
import 'package:riad_mobile/features/object/object_passport_screen.dart';
import 'package:riad_mobile/features/object/providers/object_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _authState;
  _FakeAuthNotifier(this._authState);

  @override
  Future<AuthState> build() async => _authState;
}

final _engineerState = AuthAuthenticated(
  AuthUser(id: 'u1', email: 'e@e.ua', role: 'engineer', mfaRequired: false),
);

final _installerState = AuthAuthenticated(
  AuthUser(id: 'u2', email: 'i@i.ua', role: 'installer', mfaRequired: false),
);

final _engineerObj = <String, dynamic>{
  'id': 'obj-1',
  'name': 'Склад Петровського',
  'address': 'Вул. Промислова, 5',
  'customer_name': 'ТОВ Склад',
  'map_kind': 'floor',
  'system_type': 'CCTV',
  'technical_notes': 'IP камери Hikvision',
  'financial_summary': 'UAH 120,000',
};

final _installerObj = <String, dynamic>{
  'id': 'obj-1',
  'name': 'Склад Петровського',
  'address': 'Вул. Промислова, 5',
  'customer_name': 'ТОВ Склад',
  'map_kind': 'floor',
  'system_type': 'Alarm',
};

Widget _wrap({
  required String objectId,
  required Map<String, dynamic>? obj,
  required AuthState authState,
}) {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => ObjectPassportScreen(objectId: objectId),
      routes: [
        GoRoute(
          path: 'map/:objectId',
          builder: (_, __) => const SizedBox(),
        ),
      ],
    ),
  ]);
  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(authState)),
      objectByIdProvider(objectId).overrideWith((ref) async => obj),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ObjectPassportScreen', () {
    testWidgets('shows loading indicator while fetching', (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          authProvider.overrideWith(() => _FakeAuthNotifier(_engineerState)),
          objectByIdProvider('obj-1').overrideWith(
            (ref) => Completer<Map<String, dynamic>?>().future,
          ),
        ],
        child: MaterialApp(home: ObjectPassportScreen(objectId: 'obj-1')),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows "Не знайдено" when object is null', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-x', obj: null, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.text('Не знайдено'), findsOneWidget);
    });

    testWidgets('shows object name in mandatory section', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _engineerObj, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.text('Склад Петровського'), findsOneWidget);
    });

    testWidgets('shows address in mandatory section', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _engineerObj, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.text('Вул. Промислова, 5'), findsOneWidget);
    });

    testWidgets('engineer sees map button in AppBar', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _engineerObj, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.map_outlined), findsOneWidget);
    });

    testWidgets('installer does NOT see map button', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _installerObj, authState: _installerState));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.map_outlined), findsNothing);
    });

    testWidgets('engineer sees Фінанси section', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _engineerObj, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.text('Фінанси'), findsOneWidget);
    });

    testWidgets('installer does NOT see Фінанси section', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _installerObj, authState: _installerState));
      await tester.pumpAndSettle();
      expect(find.text('Фінанси'), findsNothing);
    });

    testWidgets('operational section expands on tap', (tester) async {
      await tester.pumpWidget(
          _wrap(objectId: 'obj-1', obj: _engineerObj, authState: _engineerState));
      await tester.pumpAndSettle();
      expect(find.text('Операційні дані'), findsOneWidget);
      await tester.tap(find.text('Операційні дані'));
      await tester.pumpAndSettle();
      expect(find.text('CCTV'), findsOneWidget);
    });
  });
}
