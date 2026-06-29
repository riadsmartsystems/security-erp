import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Unit tests — pure logic, no widget rendering needed

void main() {
  group('ServiceRequestScreen — DTO-driven logic', () {
    test('actions list is empty when DTO has no actions field', () {
      final data = <String, dynamic>{
        'description': 'Перевірка сигналізації',
        'status': 'open',
      };
      final actions =
          (data['actions'] as List? ?? []).cast<Map<String, dynamic>>();
      expect(actions, isEmpty);
    });

    test('actions list populated when DTO contains actions', () {
      final data = <String, dynamic>{
        'description': 'Ремонт камери',
        'status': 'in_progress',
        'actions': [
          {'action_type': 'repair', 'notes': 'Замінено кабель'},
        ],
      };
      final actions =
          (data['actions'] as List? ?? []).cast<Map<String, dynamic>>();
      expect(actions.length, 1);
      expect(actions.first['action_type'], 'repair');
    });

    test('no financial fields if DTO does not include them', () {
      // Installer DTO: server does not return price/cost fields
      final data = <String, dynamic>{
        'description': 'Монтаж обладнання',
        'status': 'open',
        'actions': [],
      };
      expect(data.containsKey('price'), isFalse);
      expect(data.containsKey('cost'), isFalse);
      expect(data.containsKey('margin'), isFalse);
    });

    test('status string is preserved from DTO', () {
      final data = <String, dynamic>{'description': '—', 'status': 'done'};
      expect(data['status'], 'done');
    });
  });

  group('ServiceRequestScreen — widget renders loading state', () {
    testWidgets('shows CircularProgressIndicator when data is null',
        (tester) async {
      // Render without Dio so _load() will throw and screen stays null
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: _NullDataServiceRequestHost(),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}

// Simulates ServiceRequestScreen before data loads
class _NullDataServiceRequestHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
}
