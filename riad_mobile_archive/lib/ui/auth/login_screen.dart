import 'package:flutter/material.dart';
import 'package:riad_mobile/services/auth_api_client.dart';
import 'package:riad_mobile/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  final Future<void> Function(AuthTokens tokens) onLogin;
  final AuthApiClient? authApiClient;
  final AuthService? authService;

  const LoginScreen({super.key, required this.onLogin, this.authApiClient, this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('RIAD Security', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || v.isEmpty) ? 'Email обов\'язкове' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Пароль', border: OutlineInputBorder()),
                obscureText: true,
                validator: (v) => (v == null || v.isEmpty) ? 'Пароль обов\'язковий' : null,
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _handleLogin,
                  child: _loading ? const CircularProgressIndicator() : const Text('Увійти'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      final api = widget.authApiClient ?? AuthApiClient(baseUrl: 'http://localhost');
      final tokens = await api.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final auth = widget.authService ?? AuthService();
      await auth.saveTokens(accessToken: tokens.accessToken, refreshToken: tokens.refreshToken);
      await widget.onLogin(tokens);
    } on AuthException catch (e) {
      setState(() { _error = 'Помилка: ${e.message}'; });
    } catch (e) {
      setState(() { _error = 'Мережева помилка'; });
    } finally {
      if (mounted) setState(() { _loading = false; });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
