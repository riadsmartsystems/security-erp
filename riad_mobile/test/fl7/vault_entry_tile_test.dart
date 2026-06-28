import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/vault/providers/vault_provider.dart';
import 'package:riad_mobile/features/vault/widgets/vault_entry_tile.dart';

const _entry = VaultEntry(
  id: 'e1',
  label: 'DVR Офіс',
  username: 'admin',
  maskedValue: '••••••••',
  category: 'cctv',
);

class _FakeVaultNotifier extends VaultNotifier {
  final String? revealResult;
  _FakeVaultNotifier({this.revealResult});

  @override
  VaultState build() => const VaultState(isAuthenticated: true);

  @override
  Future<String?> revealEntry(String entryId) async => revealResult;
}

Widget _buildTile({String? revealResult}) {
  return ProviderScope(
    overrides: [
      vaultProvider.overrideWith(
        () => _FakeVaultNotifier(revealResult: revealResult),
      ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: VaultEntryTile(entry: _entry),
      ),
    ),
  );
}

void main() {
  group('VaultEntryTile', () {
    testWidgets('shows entry label', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pumpAndSettle();
      expect(find.text('DVR Офіс'), findsOneWidget);
    });

    testWidgets('shows entry username', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pumpAndSettle();
      expect(find.text('admin'), findsOneWidget);
    });

    testWidgets('shows masked value initially', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pumpAndSettle();
      expect(find.text('••••••••'), findsOneWidget);
    });

    testWidgets('shows "Показати" button initially', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pumpAndSettle();
      expect(find.text('Показати'), findsOneWidget);
      expect(find.text('Сховати'), findsNothing);
    });

    testWidgets('audit badge not visible initially', (tester) async {
      await tester.pumpWidget(_buildTile());
      await tester.pumpAndSettle();
      expect(find.text('Записано в аудит'), findsNothing);
    });

    testWidgets('after reveal: shows value and audit badge', (tester) async {
      await tester.pumpWidget(_buildTile(revealResult: 'secret_pass'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Показати'));
      await tester.pumpAndSettle();

      expect(find.text('secret_pass'), findsOneWidget);
      expect(find.text('Записано в аудит'), findsOneWidget);
      expect(find.text('Сховати'), findsOneWidget);
    });

    testWidgets('hide button restores masked value', (tester) async {
      await tester.pumpWidget(_buildTile(revealResult: 'secret_pass'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Показати'));
      await tester.pumpAndSettle();
      expect(find.text('secret_pass'), findsOneWidget);

      await tester.tap(find.text('Сховати'));
      await tester.pumpAndSettle();
      expect(find.text('••••••••'), findsOneWidget);
      expect(find.text('secret_pass'), findsNothing);
    });
  });
}
