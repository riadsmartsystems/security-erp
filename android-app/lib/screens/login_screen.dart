import 'package:flutter/material.dart';
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
  bool _loading = false;
  String? _error;
  bool _showServerSettings = false;

  @override
  void initState() {
    super.initState();
    _serverController.text = ApiService.baseUrl;
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final creds = await api.loadCredentials();
    if (creds['username']!.isNotEmpty) {
      _usernameController.text = creds['username']!;
    }
    if (creds['password']!.isNotEmpty) {
      _passwordController.text = creds['password']!;
    }
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() { _error = 'Введіть логін та пароль'; });
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final serverUrl = _serverController.text.trim();
      if (serverUrl.isNotEmpty && serverUrl != ApiService.baseUrl) {
        ApiService.updateBaseUrl(serverUrl);
      }
      final success = await api.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (success && mounted) {
        await api.saveCredentials(
          _usernameController.text.trim(),
          _passwordController.text,
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        setState(() { _error = 'Невірний логін або пароль'; });
      }
    } catch (e) {
      setState(() { _error = 'Помилка підключення: $e'; });
    } finally {
      setState(() { _loading = false; });
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
            colors: [Color(0xFF1E40AF), Color(0xFF3B82F6), Color(0xFFF8FAFC)],
            stops: [0.0, 0.3, 0.3],
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
                  'assets/logo.png',
                  height: 120,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.security,
                    size: 80,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'RIAD SMART SYSTEM',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Система управління обслуговуванням',
                  style: TextStyle(fontSize: 14, color: Colors.white70),
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
                              hintText: 'https://api.riad.fun',
                            ),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(_error!, style: TextStyle(color: Colors.red.shade700, fontSize: 13)),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E40AF),
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
