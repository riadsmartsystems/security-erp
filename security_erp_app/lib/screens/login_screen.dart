import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController();
  bool _loading = true;
  String? _error;
  bool _showServerSettings = false;

  @override
  void initState() {
    super.initState();
    _serverController.text = ApiService.baseUrl;
    _autoLogin();
  }

  Future<void> _autoLogin() async {
    try {
      final creds = await api.loadCredentials();
      final u = creds['username'] ?? '';
      final p = creds['password'] ?? '';
      if (u.isNotEmpty) _usernameController.text = u;
      if (p.isNotEmpty) _passwordController.text = p;
      if (u.isNotEmpty && p.isNotEmpty) {
        final success = await api.login(u, p);
        if (success && mounted) {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          return;
        }
      }
    } catch (_) {}
    if (mounted) setState(() { _loading = false; });
  }

  Future<void> _login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() { _error = 'Введіть логін та пароль'; });
      return;
    }
    setState(() { _loading = true; _error = null; });

    await api.saveCredentials(username);

    try {
      final serverUrl = _serverController.text.trim();
      if (serverUrl.isNotEmpty && serverUrl != ApiService.baseUrl) {
        ApiService.updateBaseUrl(serverUrl);
      }
      final success = await api.login(username, password);
      if (success && mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
      } else {
        setState(() { _error = 'Невірний логін або пароль'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Помилка: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.primary, AppColors.primaryLight, AppColors.background],
            stops: [0.0, 0.35, 0.35],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Image.asset(
                  'assets/logo.jpg',
                  width: 280,
                  fit: BoxFit.fitWidth,
                ),
                const SizedBox(height: 48),
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _usernameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Логін',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _login(),
                          decoration: const InputDecoration(
                            labelText: 'Пароль',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.lock),
                          ),
                        ),
                        if (_showServerSettings) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _serverController,
                            decoration: const InputDecoration(
                              labelText: 'Сервер API',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.dns),
                            ),
                          ),
                        ],
                         if (_error != null) ...[
                           const SizedBox(height: 12),
                           Container(
                             padding: const EdgeInsets.all(12),
                             decoration: BoxDecoration(
                               color: AppColors.danger.withOpacity(0.1),
                               borderRadius: BorderRadius.circular(8),
                               border: Border.all(color: AppColors.danger.withOpacity(0.3)),
                             ),
                             child: Text(_error!, style: TextStyle(color: AppColors.danger, fontSize: 13)),
                           ),
                         ],
                        const SizedBox(height: 24),
                         SizedBox(
                           width: double.infinity,
                           height: 48,
                           child: ElevatedButton(
                             onPressed: _loading ? null : _login,
                             style: ElevatedButton.styleFrom(
                               backgroundColor: AppColors.primary,
                               foregroundColor: Colors.white,
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                             ),
                             child: _loading
                                 ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                 : const Text('Увійти', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                           ),
                         ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => _showServerSettings = !_showServerSettings),
                  child: Text(
                    _showServerSettings ? 'Приховати налаштування' : 'Налаштування сервера',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
