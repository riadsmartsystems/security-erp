import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/profile/sessions_screen.dart';

Widget _wrapData(List<Map<String, dynamic>> data) => ProviderScope(
      overrides: [
        sessionsProvider.overrideWith((ref) async => data),
      ],
      child: const MaterialApp(home: SessionsScreen()),
    );

// For loading state: Completer that never completes → no pending timer issue
Widget _wrapLoading() {
  final completer = Completer<List<Map<String, dynamic>>>();
  return ProviderScope(
    overrides: [
      sessionsProvider.overrideWith((ref) => completer.future),
    ],
    child: const MaterialApp(home: SessionsScreen()),
  );
}

void main() {
  group('SessionsScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await tester.pumpWidget(_wrapData([]));
      await tester.pump();
      expect(find.text('Активні сесії'), findsOneWidget);
    });

    testWidgets('shows empty state when no sessions', (tester) async {
      await tester.pumpWidget(_wrapData([]));
      await tester.pumpAndSettle();
      expect(find.text('Немає активних сесій'), findsOneWidget);
    });

    testWidgets('shows session device_name', (tester) async {
      final sessions = [
        {
          'id': 's1',
          'device_name': 'Samsung Galaxy A54',
          'last_used': '2026-06-29',
          'is_current': false,
        }
      ];
      await tester.pumpWidget(_wrapData(sessions));
      await tester.pumpAndSettle();
      expect(find.text('Samsung Galaxy A54'), findsOneWidget);
    });

    testWidgets('current session shows Поточна chip', (tester) async {
      final sessions = [
        {
          'id': 's2',
          'device_name': 'Pixel 7',
          'last_used': '2026-06-29',
          'is_current': true,
        }
      ];
      await tester.pumpWidget(_wrapData(sessions));
      await tester.pumpAndSettle();
      expect(find.text('Поточна'), findsOneWidget);
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('non-current session shows revoke button', (tester) async {
      final sessions = [
        {
          'id': 's3',
          'device_name': 'Xiaomi 12',
          'last_used': '2026-06-28',
          'is_current': false,
        }
      ];
      await tester.pumpWidget(_wrapData(sessions));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator while loading',
        (tester) async {
      await tester.pumpWidget(_wrapLoading());
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
