import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/profile/mfa_management_screen.dart';

void main() {
  group('MfaManagementScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MfaManagementScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('MFA пристрої'), findsOneWidget);
    });

    testWidgets('shows TOTP активовано text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MfaManagementScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('TOTP активовано'), findsOneWidget);
    });

    testWidgets('shows security icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MfaManagementScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.security_outlined), findsOneWidget);
    });

    testWidgets('shows Переналаштувати MFA button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: MfaManagementScreen()),
      );
      await tester.pumpAndSettle();
      expect(find.text('Переналаштувати MFA'), findsOneWidget);
    });
  });
}
