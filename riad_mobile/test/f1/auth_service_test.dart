import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riad_mobile/services/auth_service.dart';

class MockFlutterSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

void main() {
  late AuthService authService;
  late MockFlutterSecureStorage mockStorage;

  setUp(() {
    mockStorage = MockFlutterSecureStorage();
    authService = AuthService.forTesting(storage: mockStorage);
  });

  test('starts unauthenticated', () async {
    expect(await authService.isAuthenticated(), false);
  });

  test('saveTokens then getAccessToken returns token', () async {
    await authService.saveTokens(
        accessToken: 'acc_123', refreshToken: 'ref_456');
    expect(await authService.getAccessToken(), 'acc_123');
    expect(await authService.getRefreshToken(), 'ref_456');
    expect(await authService.isAuthenticated(), true);
  });

  test('clearTokens removes all tokens', () async {
    await authService.saveTokens(
        accessToken: 'acc_123', refreshToken: 'ref_456');
    await authService.clearTokens();
    expect(await authService.isAuthenticated(), false);
    expect(await authService.getAccessToken(), isNull);
  });
}
