import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/ui/auth/login_screen.dart';
import 'package:riad_mobile/services/auth_api_client.dart';

void main() {
  testWidgets('LoginScreen shows email/password fields and login button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onLogin: (_) async {},
        authApiClient: AuthApiClient(baseUrl: 'http://test'),
      ),
    ));
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Увійти'), findsOneWidget);
  });

  testWidgets('LoginScreen shows error on empty fields', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onLogin: (_) async {},
        authApiClient: AuthApiClient(baseUrl: 'http://test'),
      ),
    ));
    await tester.tap(find.text('Увійти'));
    await tester.pump();
    expect(find.textContaining('обов\'язкове'), findsWidgets);
  });

  testWidgets('LoginScreen shows RIAD Security title', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LoginScreen(
        onLogin: (_) async {},
        authApiClient: AuthApiClient(baseUrl: 'http://test'),
      ),
    ));
    expect(find.text('RIAD Security'), findsOneWidget);
  });
}
