import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static String baseUrl = 'https://erp.riad.fun';
  final _storage = const FlutterSecureStorage();
  String? _token;

  static void updateBaseUrl(String url) {
    baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }

  static Future<String> _resolveHost(String host) async {
    try {
      final addresses = await InternetAddress.lookup(host);
      final ipv4 = addresses.where((a) => a.type == InternetAddressType.IPv4);
      if (ipv4.isNotEmpty) return ipv4.first.address;
    } catch (_) {}
    return host;
  }

  static HttpClient? _httpClient;
  static String? _resolvedHost;

  static Future<HttpClient> _getClient() async {
    if (_httpClient != null) return _httpClient!;
    final uri = Uri.parse(baseUrl);
    _resolvedHost = await _resolveHost(uri.host);
    _httpClient = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15)
      ..badCertificateCallback = (_, __, ___) => true;
    return _httpClient!;
  }

  Future<HttpClientRequest> _request(String method, String path, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$baseUrl$path');
    final client = await _getClient();
    final resolvedUri = uri.replace(host: _resolvedHost ?? uri.host);
    final request = await client.openUrl(method, resolvedUri);
    request.headers.set('Content-Type', 'application/json');
    request.headers.set('Host', uri.host);
    if (_token != null) {
      request.headers.set('Authorization', 'Bearer $_token');
    }
    if (body != null) {
      request.write(jsonEncode(body));
    }
    return request;
  }

  Future<Map<String, dynamic>> _send(HttpClientRequest request) async {
    final response = await request.close().timeout(const Duration(seconds: 15));
    final body = await response.transform(utf8.decoder).join();
    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(body);
    }
    throw Exception('API error ${response.statusCode}: $body');
  }

  Future<bool> login(String username, String password) async {
    try {
      final request = await _request('POST', '/api/v1/auth/login',
          body: {'username': username, 'password': password});
      final data = await _send(request);
      _token = data['access_token'] ?? data['token'];
      await _storage.write(key: 'token', value: _token);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path) async {
    _token ??= await _storage.read(key: 'token');
    final request = await _request('GET', path);
    return await _send(request);
  }

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    _token ??= await _storage.read(key: 'token');
    final request = await _request('POST', path, body: body);
    return await _send(request);
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: 'token');
  }
}

final api = ApiService();
