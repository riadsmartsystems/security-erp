import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/profile/notification_settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap() => const ProviderScope(
      child: MaterialApp(home: NotificationSettingsScreen()),
    );

void main() {
  group('NotificationSettingsScreen', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows AppBar title', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Сповіщення'), findsOneWidget);
    });

    testWidgets('shows security disclaimer', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(
        find.text('Секрети НІКОЛИ не надсилаються в сповіщеннях.'),
        findsOneWidget,
      );
    });

    testWidgets('shows all 5 channel toggles', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.byType(SwitchListTile), findsNWidgets(5));
    });

    testWidgets('shows Нова задача channel', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Нова задача призначена'), findsOneWidget);
    });

    testWidgets('shows all 5 channel labels', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      expect(find.text('Конфлікт синхронізації'), findsOneWidget);
      expect(find.text('Транскрипція готова'), findsOneWidget);
      expect(find.text('Кошторис на перевірку'), findsOneWidget);
      expect(find.text('Деградація AI'), findsOneWidget);
    });

    testWidgets('all channels default to enabled', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();
      final tiles = tester.widgetList<SwitchListTile>(
          find.byType(SwitchListTile));
      for (final tile in tiles) {
        expect(tile.value, isTrue,
            reason: '${tile.title} should default to enabled');
      }
    });

    testWidgets('toggle disables a channel', (tester) async {
      await tester.pumpWidget(_wrap());
      await tester.pumpAndSettle();

      final before = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile).first);
      expect(before.value, isTrue);

      await tester.tap(find.byType(SwitchListTile).first);
      await tester.pump();

      final after = tester.widget<SwitchListTile>(
          find.byType(SwitchListTile).first);
      expect(after.value, isFalse);
    });
  });
}
