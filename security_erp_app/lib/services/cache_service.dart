import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class CacheService {
  static const String _prefix = 'cache_';

  static Future<void> save(String key, dynamic data) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(data);
    await prefs.setString('$_prefix$key', encoded);
  }

  static Future<dynamic> load(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final String? cached = prefs.getString('$_prefix$key');
    if (cached == null) return null;
    try {
      return json.decode(cached);
    } catch (e) {
      return null;
    }
  }

  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
  }
}
