import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_messaging_platform_interface/firebase_messaging_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:riad_mobile/services/push_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFirebaseMessagingPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements FirebaseMessagingPlatform {
  @override
  bool get isAutoInitEnabled => true;

  @override
  FirebaseMessagingPlatform delegateFor({FirebaseApp? app}) {
    return this;
  }

  @override
  FirebaseMessagingPlatform setInitialValues({bool? isAutoInitEnabled}) {
    return this;
  }

  @override
  Future<String?> getToken({String? vapidKey}) async => 'mock_fcm_token';

  @override
  Future<void> deleteToken() async {}

  @override
  Future<NotificationSettings> requestPermission({
    bool? alert,
    bool? announcement,
    bool? badge,
    bool? carPlay,
    bool? criticalAlert,
    bool? provisional,
    bool? sound,
    bool? providesAppNotificationSettings,
  }) async {
    return const NotificationSettings(
      authorizationStatus: AuthorizationStatus.authorized,
      alert: AppleNotificationSetting.enabled,
      announcement: AppleNotificationSetting.disabled,
      badge: AppleNotificationSetting.enabled,
      carPlay: AppleNotificationSetting.disabled,
      criticalAlert: AppleNotificationSetting.disabled,
      lockScreen: AppleNotificationSetting.enabled,
      notificationCenter: AppleNotificationSetting.enabled,
      providesAppNotificationSettings: AppleNotificationSetting.disabled,
      showPreviews: AppleShowPreviewSetting.always,
      sound: AppleNotificationSetting.enabled,
      timeSensitive: AppleNotificationSetting.disabled,
    );
  }

  @override
  Stream<String> get onTokenRefresh => const Stream.empty();

  @override
  Future<RemoteMessage?> getInitialMessage() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final mockMessagingPlatform = MockFirebaseMessagingPlatform();

  setUp(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
    FirebaseMessagingPlatform.instance = mockMessagingPlatform;
  });

  test('PushService.initialize sends device_id in registration', () async {
    SharedPreferences.setMockInitialValues({});
    String? registeredDeviceId;
    final mockClient = http_testing.MockClient((request) async {
      if (request.url.path == '/api/v2/push/token' && request.method == 'POST') {
        final body = jsonDecode(request.body);
        registeredDeviceId = body['device_id'];
        return http.Response(jsonEncode({'ok': true, 'device_id': body['device_id']}), 200);
      }
      return http.Response('{}', 200);
    });

    final pushService = PushService(baseUrl: 'http://localhost', client: mockClient);
    await pushService.initialize(jwtToken: 'test_token');
    expect(registeredDeviceId, isNotNull);
  });

  test('PushService.revoke sends device_id in body', () async {
    SharedPreferences.setMockInitialValues({'device_id': 'test_device_123'});
    String? revokedDeviceId;
    final mockClient = http_testing.MockClient((request) async {
      if (request.url.path == '/api/v2/push/token' && request.method == 'DELETE') {
        final body = jsonDecode(request.body);
        revokedDeviceId = body['device_id'];
        return http.Response(jsonEncode({'ok': true, 'revoked': body['device_id']}), 200);
      }
      return http.Response('{}', 200);
    });

    final pushService = PushService(baseUrl: 'http://localhost', client: mockClient);
    await pushService.revoke(jwtToken: 'test_token');
    expect(revokedDeviceId, 'test_device_123');
  });
}
