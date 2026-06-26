import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String deviceId;
  AuthTokens({required this.accessToken, required this.refreshToken, required this.deviceId});
}

class AuthException implements Exception {
  final int statusCode;
  final String message;
  AuthException(this.statusCode, this.message);
  @override
  String toString() => 'AuthException($statusCode): $message';
}

class AuthApiClient {
  final String _baseUrl;
  final http.Client _client;

  AuthApiClient({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl, _client = client ?? http.Client();

  Future<AuthTokens> login({required String email, required String password, String? deviceId}) async {
    final did = deviceId ?? const Uuid().v4();
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/v2/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'device_id': did}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw AuthException(response.statusCode, body['detail'] ?? 'Login failed');
    }
    final body = jsonDecode(response.body);
    return AuthTokens(
      accessToken: body['access_token'],
      refreshToken: body['refresh_token'],
      deviceId: body['device_id'],
    );
  }

  Future<AuthTokens> refresh({required String refreshToken, required String deviceId}) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/api/v2/auth/refresh'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken, 'device_id': deviceId}),
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw AuthException(response.statusCode, body['detail'] ?? 'Refresh failed');
    }
    final body = jsonDecode(response.body);
    return AuthTokens(
      accessToken: body['access_token'],
      refreshToken: body['refresh_token'],
      deviceId: body['device_id'],
    );
  }

  Future<void> logout({required String refreshToken, required String deviceId}) async {
    await _client.post(
      Uri.parse('$_baseUrl/api/v2/auth/logout'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': refreshToken, 'device_id': deviceId}),
    );
  }

  Future<Map<String, dynamic>> me({required String accessToken}) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/api/v2/auth/me'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );
    if (response.statusCode != 200) throw AuthException(response.statusCode, 'Failed to fetch user');
    return jsonDecode(response.body);
  }
}
