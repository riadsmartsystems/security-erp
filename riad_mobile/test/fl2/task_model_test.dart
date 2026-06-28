import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/home/task_model.dart';

void main() {
  group('Task.fromJson', () {
    final baseJson = {
      'id': 'task-1',
      'type': 'visit',
      'title': 'Перевірити CCTV',
      'object_name': 'Офіс Київ',
      'address': 'вул. Хрещатик 1',
      'status': 'in_progress',
      'due_time': '10:30',
    };

    test('parses all fields correctly', () {
      final task = Task.fromJson(baseJson);
      expect(task.id, 'task-1');
      expect(task.type, TaskType.visit);
      expect(task.title, 'Перевірити CCTV');
      expect(task.objectName, 'Офіс Київ');
      expect(task.address, 'вул. Хрещатик 1');
      expect(task.status, 'in_progress');
      expect(task.dueTime, '10:30');
    });

    test('parses null dueTime', () {
      final json = Map<String, dynamic>.from(baseJson)..['due_time'] = null;
      final task = Task.fromJson(json);
      expect(task.dueTime, isNull);
    });

    test('missing due_time key → null', () {
      final json = Map<String, dynamic>.from(baseJson)..remove('due_time');
      final task = Task.fromJson(json);
      expect(task.dueTime, isNull);
    });

    group('TaskType parsing', () {
      for (final pair in [
        ('visit', TaskType.visit),
        ('checklist', TaskType.checklist),
        ('service', TaskType.service),
        ('remote_inspection', TaskType.remoteInspection),
        ('estimate', TaskType.estimate),
      ]) {
        test('${pair.$1} → ${pair.$2}', () {
          final json = Map<String, dynamic>.from(baseJson)..['type'] = pair.$1;
          expect(Task.fromJson(json).type, pair.$2);
        });
      }

      test('unknown type defaults to visit', () {
        final json = Map<String, dynamic>.from(baseJson)
          ..['type'] = 'unknown_future_type';
        expect(Task.fromJson(json).type, TaskType.visit);
      });
    });
  });

  group('Task Equatable', () {
    const taskA = Task(
      id: 't1',
      type: TaskType.visit,
      title: 'A',
      objectName: 'Obj',
      address: 'Addr',
      status: 'draft',
    );

    test('same props → equal', () {
      const taskB = Task(
        id: 't1',
        type: TaskType.visit,
        title: 'A',
        objectName: 'Obj',
        address: 'Addr',
        status: 'draft',
      );
      expect(taskA, equals(taskB));
    });

    test('different status → not equal', () {
      const taskB = Task(
        id: 't1',
        type: TaskType.visit,
        title: 'A',
        objectName: 'Obj',
        address: 'Addr',
        status: 'done',
      );
      expect(taskA, isNot(equals(taskB)));
    });

    test('different type → not equal', () {
      const taskB = Task(
        id: 't1',
        type: TaskType.service,
        title: 'A',
        objectName: 'Obj',
        address: 'Addr',
        status: 'draft',
      );
      expect(taskA, isNot(equals(taskB)));
    });
  });
}
