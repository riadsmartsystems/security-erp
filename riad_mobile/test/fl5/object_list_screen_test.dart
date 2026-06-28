import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riad_mobile/features/object/object_list_screen.dart';
import 'package:riad_mobile/features/object/providers/object_provider.dart';

Widget _wrap(AsyncValue<List<Map<String, dynamic>>> state) {
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, __) => const ObjectListScreen()),
    GoRoute(path: '/object/:id', builder: (_, __) => const SizedBox()),
  ]);
  return ProviderScope(
    overrides: [
      objectListProvider.overrideWith((ref) async {
        final val = state;
        if (val is AsyncError) throw (val as AsyncError).error;
        return (val as AsyncData).value;
      }),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('ObjectListScreen', () {
    testWidgets('shows loading indicator', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const ObjectListScreen()),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          objectListProvider.overrideWith(
            (ref) => Completer<List<Map<String, dynamic>>>().future,
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state text when no objects', (tester) async {
      await tester.pumpWidget(_wrap(const AsyncData([])));
      await tester.pumpAndSettle();
      expect(find.text('Немає об\'єктів'), findsOneWidget);
    });

    testWidgets('shows list of objects', (tester) async {
      await tester.pumpWidget(_wrap(AsyncData([
        {'id': 'o1', 'name': 'Склад №1', 'address': 'Вул. Промислова', 'customer_name': 'ТОВ Склад'},
        {'id': 'o2', 'name': 'Офіс директора', 'address': 'Центр', 'customer_name': 'ФОП Мельник'},
      ])));
      await tester.pumpAndSettle();
      expect(find.text('Склад №1'), findsOneWidget);
      expect(find.text('Офіс директора'), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const ObjectListScreen()),
      ]);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          objectListProvider.overrideWith((ref) async => throw Exception('Network error')),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('Помилка'), findsOneWidget);
    });

    testWidgets('shows AppBar title "Обʼєкти"', (tester) async {
      await tester.pumpWidget(_wrap(const AsyncData([])));
      await tester.pumpAndSettle();
      expect(find.text('Обʼєкти'), findsOneWidget);
    });
  });
}
