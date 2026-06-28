import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/dio_client.dart';
import '../../../core/connectivity/connectivity_service.dart';

/// Vault session — ТІЛЬКИ в пам'яті (не flutter_secure_storage, не Drift)
class VaultSession {
  final String token;
  final DateTime expiresAt;
  const VaultSession({required this.token, required this.expiresAt});
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

class VaultState {
  final bool isLoading;
  final bool isAuthenticated;
  final List<VaultEntry> entries;
  final DateTime? sessionExpiresAt;
  final String? error;

  const VaultState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.entries = const [],
    this.sessionExpiresAt,
    this.error,
  });

  VaultState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    List<VaultEntry>? entries,
    DateTime? sessionExpiresAt,
    String? error,
  }) =>
      VaultState(
        isLoading: isLoading ?? this.isLoading,
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        entries: entries ?? this.entries,
        sessionExpiresAt: sessionExpiresAt ?? this.sessionExpiresAt,
        error: error,
      );
}

class VaultEntry {
  final String id;
  final String label;
  final String username;
  final String maskedValue;
  final String category;

  const VaultEntry({
    required this.id,
    required this.label,
    required this.username,
    required this.maskedValue,
    required this.category,
  });

  factory VaultEntry.fromJson(Map<String, dynamic> j) => VaultEntry(
        id: j['id'] as String,
        label: j['label'] as String,
        username: j['username'] as String,
        maskedValue: j['masked_value'] as String,
        category: j['category'] as String,
      );
}

class VaultNotifier extends Notifier<VaultState> {
  VaultSession? _session;

  @override
  VaultState build() => const VaultState();

  bool get _isOnline => ref.read(connectivityProvider).value ?? false;

  Future<void> startMfaVerification(String totpCode) async {
    if (!_isOnline) {
      state = state.copyWith(error: 'Vault доступний лише онлайн');
      return;
    }
    state = state.copyWith(isLoading: true, error: null);
    try {
      final dio = ref.read(dioProvider);
      final resp =
          await dio.post('/vault/mfa/verify', data: {'totp_code': totpCode});
      final data = resp.data as Map<String, dynamic>;

      _session = VaultSession(
        token: data['vault_session_token'] as String,
        expiresAt: DateTime.parse(data['expires_at'] as String),
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        sessionExpiresAt: _session!.expiresAt,
      );
      await _loadEntries();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Невірний код MFA');
    }
  }

  Future<void> _loadEntries() async {
    if (_session == null || !_session!.isValid) {
      _expireSession();
      return;
    }
    state = state.copyWith(isLoading: true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get(
        '/vault/entries',
        options: Options(headers: {'X-Vault-Session': _session!.token}),
      );
      final data = resp.data as Map<String, dynamic>;
      final entries = (data['entries'] as List)
          .map((e) => VaultEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = state.copyWith(isLoading: false, entries: entries);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: '$e');
    }
  }

  Future<String?> revealEntry(String entryId) async {
    if (_session == null || !_session!.isValid) {
      _expireSession();
      return null;
    }
    final dio = ref.read(dioProvider);
    final resp = await dio.post(
      '/vault/entries/$entryId/reveal',
      options: Options(headers: {'X-Vault-Session': _session!.token}),
    );
    final data = resp.data as Map<String, dynamic>;
    return data['value'] as String?;
  }

  void _expireSession() {
    _session = null;
    state = const VaultState();
  }

  void logout() => _expireSession();
}

final vaultProvider =
    NotifierProvider<VaultNotifier, VaultState>(VaultNotifier.new);
