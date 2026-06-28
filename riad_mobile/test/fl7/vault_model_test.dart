import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/features/vault/providers/vault_provider.dart';

void main() {
  group('VaultEntry.fromJson', () {
    const json = {
      'id': 'entry-1',
      'label': 'DVR Офіс',
      'username': 'admin',
      'masked_value': '••••••••',
      'category': 'cctv',
    };

    test('parses all fields correctly', () {
      final entry = VaultEntry.fromJson(json);
      expect(entry.id, 'entry-1');
      expect(entry.label, 'DVR Офіс');
      expect(entry.username, 'admin');
      expect(entry.maskedValue, '••••••••');
      expect(entry.category, 'cctv');
    });

    test('different category parses correctly', () {
      final entry = VaultEntry.fromJson({...json, 'category': 'alarm'});
      expect(entry.category, 'alarm');
    });
  });

  group('VaultSession', () {
    test('isValid returns true for future expiresAt', () {
      final session = VaultSession(
        token: 'vst_test',
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      expect(session.isValid, true);
    });

    test('isValid returns false for past expiresAt', () {
      final session = VaultSession(
        token: 'vst_expired',
        expiresAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      expect(session.isValid, false);
    });
  });

  group('VaultState', () {
    test('default values', () {
      const state = VaultState();
      expect(state.isLoading, false);
      expect(state.isAuthenticated, false);
      expect(state.entries, isEmpty);
      expect(state.sessionExpiresAt, null);
      expect(state.error, null);
    });

    test('copyWith updates only specified fields', () {
      const state = VaultState();
      final updated = state.copyWith(isLoading: true, isAuthenticated: true);
      expect(updated.isLoading, true);
      expect(updated.isAuthenticated, true);
      expect(updated.entries, isEmpty);
      expect(updated.error, null);
    });

    test('copyWith clears error when not passed', () {
      const state = VaultState(error: 'some error');
      final updated = state.copyWith(isLoading: true);
      // error: null in copyWith signature means it's cleared
      expect(updated.error, null);
    });

    test('copyWith with error: sets error', () {
      const state = VaultState();
      final updated = state.copyWith(error: 'bad code');
      expect(updated.error, 'bad code');
    });

    test('copyWith with entries updates entries', () {
      const state = VaultState();
      const entry = VaultEntry(
        id: 'e1', label: 'Cam', username: 'admin',
        maskedValue: '••••', category: 'cctv',
      );
      final updated = state.copyWith(entries: [entry]);
      expect(updated.entries, hasLength(1));
      expect(updated.entries.first.id, 'e1');
    });
  });
}
