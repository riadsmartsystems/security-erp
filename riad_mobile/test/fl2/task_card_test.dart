import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/home/task_model.dart';
import 'package:riad_mobile/features/home/widgets/task_card.dart';

Widget _card(Task task, {VoidCallback? onTap}) {
  return MaterialApp(
    home: Scaffold(body: TaskCard(task: task, onTap: onTap)),
  );
}

const _baseTask = Task(
  id: 't1',
  type: TaskType.visit,
  title: 'Перевірити CCTV',
  objectName: 'Офіс Київ',
  address: 'вул. Хрещатик 1',
  status: 'in_progress',
  dueTime: '10:30',
);

void main() {
  group('TaskCard', () {
    testWidgets('renders task title', (tester) async {
      await tester.pumpWidget(_card(_baseTask));
      expect(find.text('Перевірити CCTV'), findsOneWidget);
    });

    testWidgets('renders objectName and address subtitle', (tester) async {
      await tester.pumpWidget(_card(_baseTask));
      expect(find.text('Офіс Київ · вул. Хрещатик 1'), findsOneWidget);
    });

    testWidgets('renders dueTime when present', (tester) async {
      await tester.pumpWidget(_card(_baseTask));
      expect(find.text('10:30'), findsOneWidget);
    });

    testWidgets('no dueTime row when null', (tester) async {
      const task = Task(
        id: 't2',
        type: TaskType.visit,
        title: 'T',
        objectName: 'O',
        address: 'A',
        status: 'draft',
      );
      await tester.pumpWidget(_card(task));
      expect(find.text('10:30'), findsNothing);
    });

    testWidgets('shows in_progress status badge', (tester) async {
      await tester.pumpWidget(_card(_baseTask));
      expect(find.text('В роботі'), findsOneWidget);
    });

    testWidgets('shows draft status badge', (tester) async {
      const task = Task(
        id: 't3',
        type: TaskType.visit,
        title: 'T',
        objectName: 'O',
        address: 'A',
        status: 'draft',
      );
      await tester.pumpWidget(_card(task));
      expect(find.text('Чернетка'), findsOneWidget);
    });

    testWidgets('shows done status badge', (tester) async {
      const task = Task(
        id: 't4',
        type: TaskType.visit,
        title: 'T',
        objectName: 'O',
        address: 'A',
        status: 'done',
      );
      await tester.pumpWidget(_card(task));
      expect(find.text('Виконано'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(_card(_baseTask, onTap: () => tapped = true));
      await tester.tap(find.byType(ListTile));
      expect(tapped, isTrue);
    });

    testWidgets('visit type shows drive_eta icon', (tester) async {
      await tester.pumpWidget(_card(_baseTask));
      expect(find.byIcon(Icons.drive_eta_outlined), findsOneWidget);
    });

    testWidgets('service type shows build icon', (tester) async {
      const task = Task(
        id: 't5',
        type: TaskType.service,
        title: 'T',
        objectName: 'O',
        address: 'A',
        status: 'pending',
      );
      await tester.pumpWidget(_card(task));
      expect(find.byIcon(Icons.build_outlined), findsOneWidget);
    });
  });
}
