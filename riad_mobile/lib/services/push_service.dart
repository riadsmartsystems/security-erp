import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PushService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final String _baseUrl;
  final http.Client _client;

  PushService({required String baseUrl, http.Client? client})
      : _baseUrl = baseUrl, _client = client ?? http.Client();

  Future<void> initialize({required String jwtToken}) async {
    final settings = await _fcm.requestPermission(alert: true, badge: true, sound: true);
    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return;
    }
    final token = await _fcm.getToken();
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    var deviceId = prefs.getString('device_id');
    if (deviceId == null) {
      deviceId = '${Platform.operatingSystem}_${DateTime.now().millisecondsSinceEpoch}';
      await prefs.setString('device_id', deviceId);
    }
    await _registerToken(jwtToken: jwtToken, deviceId: deviceId, fcmToken: token);
    _fcm.onTokenRefresh.listen((newToken) {
      _registerToken(jwtToken: jwtToken, deviceId: deviceId!, fcmToken: newToken);
    });
    FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(_onBackgroundMessage);
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) _onNotificationTap(initialMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onNotificationTap);
  }

  Future<void> _registerToken({required String jwtToken, required String deviceId, required String fcmToken}) async {
    try {
      await _client.post(Uri.parse('$_baseUrl/api/v2/push/token'),
        headers: {'Authorization': 'Bearer $jwtToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId, 'fcm_token': fcmToken, 'platform': Platform.operatingSystem}));
    } catch (_) {}
  }

  void _onForegroundMessage(RemoteMessage message) {
    final n = message.notification;
    if (n != null) print('[Push] Foreground: ${n.title} — ${n.body}');
  }

  void _onNotificationTap(RemoteMessage message) {
    final type = message.data['type'];
    print('[Push] Tap: type=$type data=${message.data}');
  }

  Future<void> revoke({required String jwtToken}) async {
    final prefs = await SharedPreferences.getInstance();
    final deviceId = prefs.getString('device_id');
    if (deviceId == null) return;
    try {
      await _client.delete(Uri.parse('$_baseUrl/api/v2/push/token'),
        headers: {'Authorization': 'Bearer $jwtToken', 'Content-Type': 'application/json'},
        body: jsonEncode({'device_id': deviceId}));
    } catch (_) {}
  }
}

@pragma('vm:entry-point')
Future<void> _onBackgroundMessage(RemoteMessage message) async {
  print('[Push] Background: ${message.messageId}');
}
