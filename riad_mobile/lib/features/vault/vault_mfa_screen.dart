import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/color_tokens.dart';
import 'providers/vault_provider.dart';

class VaultMfaScreen extends ConsumerStatefulWidget {
  const VaultMfaScreen({super.key});

  @override
  ConsumerState<VaultMfaScreen> createState() => _VaultMfaScreenState();
}

class _VaultMfaScreenState extends ConsumerState<VaultMfaScreen> {
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultProvider);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: kVaultAccent,
          brightness: Brightness.dark,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Vault — Підтвердження'),
          backgroundColor: kVaultAccent.withValues(alpha: 0.1),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outlined, size: 64, color: kVaultAccent),
              const SizedBox(height: 24),
              const Text(
                'Введіть код автентифікації',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              const Text(
                'Vault — захищена зона. Усі звернення записуються в аудит.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 28, letterSpacing: 10),
                decoration: InputDecoration(
                  labelText: 'MFA код',
                  errorText: vault.error,
                ),
                onChanged: (v) {
                  if (v.length == 6) _verify();
                },
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style:
                    FilledButton.styleFrom(backgroundColor: kVaultAccent),
                icon: vault.isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.lock_open_outlined),
                label: const Text('Відкрити Vault'),
                onPressed: vault.isLoading ? null : _verify,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _verify() async {
    await ref
        .read(vaultProvider.notifier)
        .startMfaVerification(_codeCtrl.text.trim());
  }
}
