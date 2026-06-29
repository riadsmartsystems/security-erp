import 'package:flutter/material.dart';

class MfaManagementScreen extends StatelessWidget {
  const MfaManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('MFA пристрої')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.security_outlined, size: 64),
              const SizedBox(height: 16),
              const Text('TOTP активовано',
                  style: TextStyle(fontSize: 18)),
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Ваш акаунт захищений двофакторною автентифікацією.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              const SizedBox(height: 32),
              OutlinedButton.icon(
                icon: const Icon(Icons.restart_alt),
                label: const Text('Переналаштувати MFA'),
                onPressed: () =>
                    Navigator.pushNamed(context, '/mfa-enrollment'),
              ),
            ],
          ),
        ),
      );
}
