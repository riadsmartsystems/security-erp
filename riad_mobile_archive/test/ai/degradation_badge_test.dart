import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:riad_mobile/ui/ai/degradation_badge.dart';

void main() {
  group('DegradationBadge', () {
    testWidgets('fetches and displays primary level', (tester) async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({
          'level': 'primary',
          'providers': [],
          'message': 'All OK',
        }), 200);
      });

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DegradationBadge(
            baseUrl: 'http://test.com',
            jwtToken: 'tok',
            refreshInterval: const Duration(hours: 1),
            client: mockClient,
          ),
        ),
      ));

      // Let the async fetch complete
      await tester.runAsync(() async => await Future.delayed(const Duration(seconds: 1)));
      await tester.pump();

      // Check that an Icon is rendered (means fetch succeeded)
      expect(find.byType(Icon), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.check_circle);
      expect(icon.color, Colors.green);
    });

    testWidgets('displays error icon on network failure', (tester) async {
      final mockClient = http_testing.MockClient((_) async => throw Exception('fail'));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DegradationBadge(
            baseUrl: 'http://test.com',
            jwtToken: 'tok',
            refreshInterval: const Duration(hours: 1),
            client: mockClient,
          ),
        ),
      ));

      await tester.runAsync(() async => await Future.delayed(const Duration(seconds: 1)));
      await tester.pump();

      expect(find.byType(Icon), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, Icons.error);
      expect(icon.color, Colors.red);
    });

    testWidgets('shows nothing while loading', (tester) async {
      final mockClient = http_testing.MockClient((_) async => http.Response('{}', 200));

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: DegradationBadge(
            baseUrl: 'http://test.com',
            jwtToken: 'tok',
            refreshInterval: const Duration(hours: 1),
            client: mockClient,
          ),
        ),
      ));

      // Before pump — still loading
      expect(find.byType(SizedBox), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });
  });
}
