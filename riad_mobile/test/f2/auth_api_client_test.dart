import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:riad_mobile/services/auth_api_client.dart';

void main() {
  group('AuthApiClient', () {
    test('login sends correct payload and parses response', () async {
      final mockClient = http_testing.MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v2/auth/login');
        final body = jsonDecode(request.body);
        expect(body['email'], 'user@test.com');
        expect(body['password'], 'pass123');
        expect(body['device_id'], isNotNull);
        return http.Response(jsonEncode({
          'access_token': 'acc_test',
          'refresh_token': 'ref_test',
          'device_id': 'dev_123',
        }), 200);
      });

      final client = AuthApiClient(baseUrl: 'http://localhost', client: mockClient);
      final result = await client.login(email: 'user@test.com', password: 'pass123');
      expect(result.accessToken, 'acc_test');
      expect(result.refreshToken, 'ref_test');
      expect(result.deviceId, 'dev_123');
    });

    test('refresh sends refresh_token in body', () async {
      final mockClient = http_testing.MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v2/auth/refresh');
        final body = jsonDecode(request.body);
        expect(body['refresh_token'], 'old_ref');
        expect(body['device_id'], 'dev_123');
        return http.Response(jsonEncode({
          'access_token': 'new_acc',
          'refresh_token': 'new_ref',
          'device_id': 'dev_123',
        }), 200);
      });

      final client = AuthApiClient(baseUrl: 'http://localhost', client: mockClient);
      final result = await client.refresh(refreshToken: 'old_ref', deviceId: 'dev_123');
      expect(result.accessToken, 'new_acc');
    });

    test('login throws on non-200', () async {
      final mockClient = http_testing.MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Invalid credentials'}), 401);
      });

      final client = AuthApiClient(baseUrl: 'http://localhost', client: mockClient);
      expect(() => client.login(email: 'x', password: 'y'), throwsA(isA<AuthException>()));
    });

    test('logout sends correct body', () async {
      final mockClient = http_testing.MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/api/v2/auth/logout');
        final body = jsonDecode(request.body);
        expect(body['refresh_token'], 'ref_123');
        expect(body['device_id'], 'dev_456');
        return http.Response('{}', 200);
      });

      final client = AuthApiClient(baseUrl: 'http://localhost', client: mockClient);
      await client.logout(refreshToken: 'ref_123', deviceId: 'dev_456');
    });
  });
}
