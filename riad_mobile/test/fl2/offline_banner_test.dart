import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/core/connectivity/connectivity_service.dart';
import 'package:riad_mobile/core/widgets/offline_banner.dart';

Widget _buildBanner(bool isOnline) {
  return ProviderScope(
    overrides: [
      connectivityProvider.overrideWith(
        (ref) => Stream.value(isOnline),
      ),
    ],
    child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
  );
}

void main() {
  group('OfflineBanner', () {
    testWidgets('shows banner text when offline', (tester) async {
      await tester.pumpWidget(_buildBanner(false));
      await tester.pumpAndSettle();

      expect(find.text('Офлайн — показано кешовані дані'), findsOneWidget);
    });

    testWidgets('shows wifi_off icon when offline', (tester) async {
      await tester.pumpWidget(_buildBanner(false));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('hidden when online', (tester) async {
      await tester.pumpWidget(_buildBanner(true));
      await tester.pumpAndSettle();

      expect(find.text('Офлайн — показано кешовані дані'), findsNothing);
      expect(find.byIcon(Icons.wifi_off), findsNothing);
    });

    testWidgets('hidden when connectivity value not yet available', (tester) async {
      // StreamProvider with no initial value → AsyncValue.loading → value=null → isOnline treated as true (hides banner)
      await ProviderScope(
        overrides: [
          connectivityProvider.overrideWith(
            (ref) => const Stream<bool>.empty(),
          ),
        ],
        child: const MaterialApp(home: Scaffold(body: OfflineBanner())),
      ).let((w) async {
        await tester.pumpWidget(w);
        await tester.pump();
        // Banner should be hidden (default=true when no value)
        expect(find.byIcon(Icons.wifi_off), findsNothing);
      });
    });
  });
}

extension _Let<T> on T {
  R let<R>(R Function(T) fn) => fn(this);
}
