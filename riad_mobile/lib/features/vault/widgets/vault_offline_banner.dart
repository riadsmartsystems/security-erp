import 'package:flutter/material.dart';
import '../../../core/theme/color_tokens.dart';

class VaultOfflineBanner extends StatelessWidget {
  const VaultOfflineBanner({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: kVaultAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: kVaultAccent.withValues(alpha: 0.3)),
                ),
                child: Column(children: [
                  Icon(Icons.wifi_off,
                      size: 48, color: kVaultAccent.withValues(alpha: 0.7)),
                  const SizedBox(height: 16),
                  const Text(
                    'Vault доступний лише онлайн',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Підключіться до мережі для доступу до паролів та облікових даних об'єктів.",
                    style: TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ]),
              ),
            ],
          ),
        ),
      );
}
