import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/core/widgets/ai_status_chip.dart';
import 'package:riad_mobile/features/home/providers/home_provider.dart';

Widget _buildChip(AsyncValue<AiStatus> status) {
  return ProviderScope(
    overrides: [
      aiStatusProvider.overrideWith((ref) async {
        final v = status;
        if (v is AsyncData<AiStatus>) return v.value;
        if (v is AsyncError<AiStatus>) throw v.error;
        // Never resolves → stays AsyncLoading (no timer)
        return Completer<AiStatus>().future;
      }),
    ],
    child: const MaterialApp(
      home: Scaffold(body: Center(child: AiStatusChip())),
    ),
  );
}

void main() {
  group('AiStatusChip', () {
    testWidgets('shows AI label when status is ok', (tester) async {
      await tester.pumpWidget(_buildChip(const AsyncData(AiStatus.ok)));
      await tester.pumpAndSettle();
      expect(find.text('AI'), findsOneWidget);
    });

    testWidgets('shows AI резерв when degraded', (tester) async {
      await tester.pumpWidget(_buildChip(const AsyncData(AiStatus.degraded)));
      await tester.pumpAndSettle();
      expect(find.text('AI резерв'), findsOneWidget);
    });

    testWidgets('shows Ручний режим when manual', (tester) async {
      await tester.pumpWidget(_buildChip(const AsyncData(AiStatus.manual)));
      await tester.pumpAndSettle();
      expect(find.text('Ручний режим'), findsOneWidget);
    });

    testWidgets('shows nothing (SizedBox.shrink) when loading', (tester) async {
      await tester.pumpWidget(_buildChip(const AsyncLoading()));
      await tester.pump();
      // No Chip widget should be rendered
      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('shows Ручний режим when error', (tester) async {
      await tester.pumpWidget(
        _buildChip(AsyncError(Exception('fail'), StackTrace.empty)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Ручний режим'), findsOneWidget);
    });
  });
}
