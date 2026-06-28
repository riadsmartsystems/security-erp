import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/vault/providers/vault_provider.dart';
import 'package:riad_mobile/features/vault/vault_mfa_screen.dart';

Widget _buildMfaScreen(VaultState state) {
  return ProviderScope(
    overrides: [
      vaultProvider.overrideWith(() => _FakeVaultNotifier(state)),
    ],
    child: const MaterialApp(home: VaultMfaScreen()),
  );
}

class _FakeVaultNotifier extends VaultNotifier {
  final VaultState _initial;
  _FakeVaultNotifier(this._initial);

  @override
  VaultState build() => _initial;

  @override
  Future<void> startMfaVerification(String totpCode) async {}
}

void main() {
  group('VaultMfaScreen', () {
    testWidgets('shows lock icon', (tester) async {
      await tester.pumpWidget(_buildMfaScreen(const VaultState()));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.lock_outlined), findsOneWidget);
    });

    testWidgets('shows MFA code text field', (tester) async {
      await tester.pumpWidget(_buildMfaScreen(const VaultState()));
      await tester.pumpAndSettle();
      expect(find.widgetWithText(TextField, 'MFA код'), findsOneWidget);
    });

    testWidgets('shows "Відкрити Vault" button', (tester) async {
      await tester.pumpWidget(_buildMfaScreen(const VaultState()));
      await tester.pumpAndSettle();
      expect(find.text('Відкрити Vault'), findsOneWidget);
    });

    testWidgets('shows error text when state has error', (tester) async {
      await tester.pumpWidget(
        _buildMfaScreen(const VaultState(error: 'Невірний код MFA')),
      );
      await tester.pumpAndSettle();
      expect(find.text('Невірний код MFA'), findsOneWidget);
    });

    testWidgets('button disabled when isLoading', (tester) async {
      await tester.pumpWidget(
        _buildMfaScreen(const VaultState(isLoading: true)),
      );
      await tester.pump(); // don't pumpAndSettle: CircularProgressIndicator never settles
      final btn = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(btn.onPressed, isNull);
    });

    testWidgets('shows audit warning text', (tester) async {
      await tester.pumpWidget(_buildMfaScreen(const VaultState()));
      await tester.pumpAndSettle();
      expect(find.textContaining('записуються в аудит'), findsOneWidget);
    });
  });
}
