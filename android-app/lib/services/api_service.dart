import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static String baseUrl = 'https://erp.riad.fun';
  final _storage = const FlutterSecureStorage();
  String? _token;

  static void updateBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  Future<bool> login(String username, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/v1/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _token = data['access_token'] ?? data['token'];
      await _storage.write(key: 'token', value: _token);
      return true;
    }
    return false;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };
  }

  Future<Map<String, dynamic>> get(String path) async {
    _token ??= await _storage.read(key: 'token');
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('API error: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    _token ??= await _storage.read(key: 'token');
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: _headers(),
      body: jsonEncode(body),
    );
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    throw Exception('API error: ${response.statusCode}');
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'token');
  }
}

final api = ApiService();
