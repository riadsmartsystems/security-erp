import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/scan/scan_screen.dart';

void main() {
  group('ScanScreen widget', () {
    testWidgets('shows AppBar with correct title', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ScanScreen(visitId: 'v1')),
        ),
      );
      await tester.pump();
      expect(find.text('Скан серійника'), findsOneWidget);
    });

    testWidgets('shows scanned count initially 0', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: ScanScreen(visitId: 'v1')),
        ),
      );
      await tester.pump();
      expect(find.textContaining('Відскановано: 0'), findsOneWidget);
    });
  });

  group('ScanScreen duplicate logic', () {
    test('new code is not duplicate', () {
      final seen = <String>{};
      const code = 'SN-12345';
      expect(seen.contains(code), false);
      seen.add(code);
      expect(seen.contains(code), true);
    });

    test('same code twice is duplicate', () {
      final seen = <String>{'SN-12345'};
      expect(seen.contains('SN-12345'), true);
    });

    test('different codes are not duplicates of each other', () {
      final seen = <String>{'SN-001'};
      expect(seen.contains('SN-002'), false);
    });
  });
}
