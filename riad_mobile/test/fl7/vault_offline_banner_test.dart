import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/vault/widgets/vault_offline_banner.dart';

void main() {
  group('VaultOfflineBanner', () {
    testWidgets('shows wifi_off icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VaultOfflineBanner()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
    });

    testWidgets('shows offline text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VaultOfflineBanner()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vault доступний лише онлайн'), findsOneWidget);
    });

    testWidgets('shows connection instruction', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: VaultOfflineBanner()),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Підключіться до мережі'),
        findsOneWidget,
      );
    });
  });
}
