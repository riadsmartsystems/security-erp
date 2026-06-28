import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/theme/color_tokens.dart';
import 'providers/vault_provider.dart';
import 'vault_mfa_screen.dart';
import 'widgets/vault_entry_tile.dart';
import 'widgets/vault_offline_banner.dart';
import 'widgets/vault_session_timer.dart';

class VaultEntriesScreen extends ConsumerWidget {
  const VaultEntriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(connectivityProvider).value ?? false;

    if (!isOnline) return const VaultOfflineBanner();

    final vault = ref.watch(vaultProvider);

    if (!vault.isAuthenticated) return const VaultMfaScreen();

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kVaultAccent,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vault'),
          backgroundColor: kVaultAccent.withValues(alpha: 0.1),
          actions: const [VaultSessionTimer(), SizedBox(width: 8)],
        ),
        body: vault.isLoading
            ? const Center(child: CircularProgressIndicator())
            : vault.entries.isEmpty
                ? const Center(child: Text('Немає записів'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: vault.entries.length,
                    itemBuilder: (ctx, i) =>
                        VaultEntryTile(entry: vault.entries[i]),
                  ),
      ),
    );
  }
}
