import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/home/home_screen.dart';
import 'package:riad_mobile/features/home/providers/home_provider.dart';
import 'package:riad_mobile/features/home/task_model.dart';

Widget _buildHome(AsyncValue<List<Task>> tasksValue) {
  return ProviderScope(
    overrides: [
      tasksProvider.overrideWith((ref) async {
        final v = tasksValue;
        if (v is AsyncData<List<Task>>) return v.value;
        if (v is AsyncError<List<Task>>) throw v.error;
        await Completer<List<Task>>().future; // never resolves
        return [];
      }),
    ],
    child: const MaterialApp(home: HomeScreen()),
  );
}

const _sampleTask = Task(
  id: 't1',
  type: TaskType.visit,
  title: 'Перевірити CCTV',
  objectName: 'Офіс Київ',
  address: 'вул. Хрещатик 1',
  status: 'in_progress',
  dueTime: '10:30',
);

void main() {
  group('HomeScreen', () {
    testWidgets('shows loading indicator while tasks load', (tester) async {
      await tester.pumpWidget(_buildHome(const AsyncLoading()));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error message on failure', (tester) async {
      await tester.pumpWidget(
        _buildHome(AsyncError(Exception('network error'), StackTrace.empty)),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Повторити'), findsOneWidget);
    });

    testWidgets('shows empty state when no tasks', (tester) async {
      await tester.pumpWidget(_buildHome(const AsyncData([])));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.text('Задач на сьогодні немає'), findsOneWidget);
    });

    testWidgets('shows task cards when tasks available', (tester) async {
      await tester.pumpWidget(_buildHome(const AsyncData([_sampleTask])));
      await tester.pumpAndSettle();
      expect(find.text('Перевірити CCTV'), findsOneWidget);
    });

    testWidgets('shows multiple task cards', (tester) async {
      const tasks = [
        _sampleTask,
        Task(
          id: 't2',
          type: TaskType.service,
          title: 'Замінити камеру',
          objectName: 'Склад',
          address: 'вул. Промислова 5',
          status: 'pending',
        ),
      ];
      await tester.pumpWidget(_buildHome(const AsyncData(tasks)));
      await tester.pumpAndSettle();
      expect(find.text('Перевірити CCTV'), findsOneWidget);
      expect(find.text('Замінити камеру'), findsOneWidget);
    });
  });
}
