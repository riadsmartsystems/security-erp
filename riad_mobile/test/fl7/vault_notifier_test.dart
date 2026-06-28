import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riad_mobile/core/api/dio_client.dart';
import 'package:riad_mobile/core/connectivity/connectivity_service.dart';
import 'package:riad_mobile/features/vault/providers/vault_provider.dart';

class MockDio extends Mock implements Dio {}

Response<dynamic> _resp(String path, Map<String, dynamic> data) => Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: data,
    );

const _futureExpiry = '2099-12-31T23:59:59Z';

void main() {
  late MockDio mockDio;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  setUp(() => mockDio = MockDio());

  ProviderContainer _makeContainer({required bool isOnline}) {
    return ProviderContainer(overrides: [
      connectivityProvider.overrideWith((ref) => Stream.value(isOnline)),
      dioProvider.overrideWithValue(mockDio),
    ]);
  }

  group('initial state', () {
    test('isAuthenticated=false, entries=[], error=null', () {
      final container = _makeContainer(isOnline: true);
      addTearDown(container.dispose);
      final state = container.read(vaultProvider);
      expect(state.isAuthenticated, false);
      expect(state.entries, isEmpty);
      expect(state.error, null);
      expect(state.isLoading, false);
    });
  });

  group('startMfaVerification — offline', () {
    test('sets error when offline (no connectivity yet → null → false)', () async {
      // connectivityProvider not yet emitted → AsyncLoading → value=null → false=offline
      final container = ProviderContainer(overrides: [
        dioProvider.overrideWithValue(mockDio),
        // Intentionally no connectivity override: defaults to AsyncLoading → null → false
        connectivityProvider.overrideWith((ref) => const Stream<bool>.empty()),
      ]);
      addTearDown(container.dispose);

      await container.read(vaultProvider.notifier).startMfaVerification('123456');

      final state = container.read(vaultProvider);
      expect(state.isAuthenticated, false);
      expect(state.error, 'Vault доступний лише онлайн');
    });
  });

  group('startMfaVerification — online', () {
    test('success → isAuthenticated=true, entries populated', () async {
      final container = _makeContainer(isOnline: true);
      addTearDown(container.dispose);

      // Let connectivity stream emit
      container.read(connectivityProvider);
      await Future.delayed(Duration.zero);

      when(() => mockDio.post('/vault/mfa/verify', data: any(named: 'data')))
          .thenAnswer((_) async => _resp('/vault/mfa/verify', {
                'vault_session_token': 'vst_abc',
                'expires_at': _futureExpiry,
              }));

      when(() => mockDio.get('/vault/entries', options: any(named: 'options')))
          .thenAnswer((_) async => _resp('/vault/entries', {
                'entries': [
                  {
                    'id': 'e1',
                    'label': 'DVR',
                    'username': 'admin',
                    'masked_value': '••••',
                    'category': 'cctv',
                  }
                ],
              }));

      await container.read(vaultProvider.notifier).startMfaVerification('123456');

      final state = container.read(vaultProvider);
      expect(state.isAuthenticated, true);
      expect(state.isLoading, false);
      expect(state.entries, hasLength(1));
      expect(state.entries.first.id, 'e1');
      expect(state.error, null);
    });

    test('MFA failure → error=Невірний код MFA, not authenticated', () async {
      final container = _makeContainer(isOnline: true);
      addTearDown(container.dispose);

      container.read(connectivityProvider);
      await Future.delayed(Duration.zero);

      when(() => mockDio.post('/vault/mfa/verify', data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/vault/mfa/verify'),
            message: 'RIAD-MFA-INVALID',
          ));

      await container.read(vaultProvider.notifier).startMfaVerification('000000');

      final state = container.read(vaultProvider);
      expect(state.isAuthenticated, false);
      expect(state.error, 'Невірний код MFA');
    });
  });

  group('revealEntry', () {
    test('returns value from API when session is valid', () async {
      final container = _makeContainer(isOnline: true);
      addTearDown(container.dispose);

      container.read(connectivityProvider);
      await Future.delayed(Duration.zero);

      when(() => mockDio.post('/vault/mfa/verify', data: any(named: 'data')))
          .thenAnswer((_) async => _resp('/vault/mfa/verify', {
                'vault_session_token': 'vst_abc',
                'expires_at': _futureExpiry,
              }));
      when(() => mockDio.get('/vault/entries', options: any(named: 'options')))
          .thenAnswer((_) async => _resp('/vault/entries', {'entries': []}));
      when(() => mockDio.post('/vault/entries/e1/reveal',
              options: any(named: 'options')))
          .thenAnswer((_) async => _resp('/vault/entries/e1/reveal', {
                'value': 'secret_password',
                'audit_logged': true,
              }));

      await container.read(vaultProvider.notifier).startMfaVerification('123456');
      final value =
          await container.read(vaultProvider.notifier).revealEntry('e1');

      expect(value, 'secret_password');
    });
  });

  group('logout', () {
    test('resets state to initial', () async {
      final container = _makeContainer(isOnline: true);
      addTearDown(container.dispose);

      container.read(connectivityProvider);
      await Future.delayed(Duration.zero);

      when(() => mockDio.post('/vault/mfa/verify', data: any(named: 'data')))
          .thenAnswer((_) async => _resp('/vault/mfa/verify', {
                'vault_session_token': 'vst_abc',
                'expires_at': _futureExpiry,
              }));
      when(() => mockDio.get('/vault/entries', options: any(named: 'options')))
          .thenAnswer((_) async => _resp('/vault/entries', {'entries': []}));

      await container.read(vaultProvider.notifier).startMfaVerification('123456');
      expect(container.read(vaultProvider).isAuthenticated, true);

      container.read(vaultProvider.notifier).logout();

      final state = container.read(vaultProvider);
      expect(state.isAuthenticated, false);
      expect(state.entries, isEmpty);
      expect(state.error, null);
    });
  });
}
