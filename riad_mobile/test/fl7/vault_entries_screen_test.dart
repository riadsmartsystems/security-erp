import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/core/connectivity/connectivity_service.dart';
import 'package:riad_mobile/features/vault/providers/vault_provider.dart';
import 'package:riad_mobile/features/vault/vault_entries_screen.dart';
import 'package:riad_mobile/features/vault/vault_mfa_screen.dart';
import 'package:riad_mobile/features/vault/widgets/vault_offline_banner.dart';

class _FakeVaultNotifier extends VaultNotifier {
  final VaultState _initial;
  _FakeVaultNotifier(this._initial);

  @override
  VaultState build() => _initial;

  @override
  Future<void> startMfaVerification(String totpCode) async {}
}

Widget _buildScreen({
  required bool isOnline,
  required VaultState vaultState,
}) {
  return ProviderScope(
    overrides: [
      connectivityProvider.overrideWith((ref) => Stream.value(isOnline)),
      vaultProvider.overrideWith(() => _FakeVaultNotifier(vaultState)),
    ],
    child: const MaterialApp(home: VaultEntriesScreen()),
  );
}

const _entry = VaultEntry(
  id: 'e1',
  label: 'DVR Офіс',
  username: 'admin',
  maskedValue: '••••••••',
  category: 'cctv',
);

void main() {
  group('VaultEntriesScreen', () {
    testWidgets('offline → shows VaultOfflineBanner', (tester) async {
      await tester.pumpWidget(
        _buildScreen(isOnline: false, vaultState: const VaultState()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VaultOfflineBanner), findsOneWidget);
      expect(find.byType(VaultMfaScreen), findsNothing);
    });

    testWidgets('online + not authenticated → shows VaultMfaScreen',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(isOnline: true, vaultState: const VaultState()),
      );
      await tester.pumpAndSettle();
      expect(find.byType(VaultMfaScreen), findsOneWidget);
      expect(find.byType(VaultOfflineBanner), findsNothing);
    });

    testWidgets('online + authenticated + entries → shows entry label',
        (tester) async {
      final state = VaultState(
        isAuthenticated: true,
        entries: const [_entry],
        sessionExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      await tester.pumpWidget(
        _buildScreen(isOnline: true, vaultState: state),
      );
      await tester.pumpAndSettle();
      expect(find.text('DVR Офіс'), findsOneWidget);
      expect(find.byType(VaultOfflineBanner), findsNothing);
      expect(find.byType(VaultMfaScreen), findsNothing);
    });

    testWidgets('online + authenticated + empty → shows empty message',
        (tester) async {
      final state = VaultState(
        isAuthenticated: true,
        sessionExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      await tester.pumpWidget(
        _buildScreen(isOnline: true, vaultState: state),
      );
      await tester.pumpAndSettle();
      expect(find.text('Немає записів'), findsOneWidget);
    });
  });
}
