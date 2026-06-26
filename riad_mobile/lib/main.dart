import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:riad_mobile/services/auth_service.dart';
import 'package:riad_mobile/services/auth_api_client.dart';
import 'package:riad_mobile/services/push_service.dart';
import 'package:riad_mobile/ui/auth/login_screen.dart';

const String _baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const RiadApp());
}

class RiadApp extends StatefulWidget {
  const RiadApp({super.key});
  @override
  State<RiadApp> createState() => _RiadAppState();
}

class _RiadAppState extends State<RiadApp> {
  final _authService = AuthService();
  final _authClient = AuthApiClient(baseUrl: _baseUrl);
  bool _authenticated = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuth = await _authService.isAuthenticated();
    if (mounted) setState(() { _authenticated = isAuth; _loading = false; });
  }

  Future<void> _handleLogin(AuthTokens tokens) async {
    final pushService = PushService(baseUrl: _baseUrl);
    await pushService.initialize(jwtToken: tokens.accessToken);
    if (mounted) setState(() { _authenticated = true; });
  }

  Future<void> _handleLogout() async {
    final accessToken = await _authService.getAccessToken();
    final refreshToken = await _authService.getRefreshToken();
    if (refreshToken != null) {
      final pushService = PushService(baseUrl: _baseUrl);
      await pushService.revoke(jwtToken: accessToken ?? '');
      await _authClient.logout(refreshToken: refreshToken, deviceId: '');
    }
    await _authService.clearTokens();
    if (mounted) setState(() { _authenticated = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    }
    return MaterialApp(
      title: 'RIAD Security',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: _authenticated
          ? HomeScreen(onLogout: _handleLogout)
          : LoginScreen(onLogin: _handleLogin, authApiClient: _authClient, authService: _authService),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final Future<void> Function() onLogout;
  const HomeScreen({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIAD Security'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: () => onLogout()),
        ],
      ),
      body: const Center(child: Text('Головний екран')),
    );
  }
}
