import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:riad_mobile/core/auth/auth_models.dart';
import 'package:riad_mobile/core/auth/auth_notifier.dart';
import 'package:riad_mobile/features/profile/profile_screen.dart';

class _FakeAuthNotifier extends AuthNotifier {
  final AuthState _init;
  _FakeAuthNotifier(this._init);

  @override
  Future<AuthState> build() async => _init;

  @override
  Future<void> logout() async {}
}

Widget _wrap(AuthState authState) {
  final router = GoRouter(
    initialLocation: '/profile',
    routes: [
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const Scaffold(body: Text('Login')),
      ),
      GoRoute(
        path: '/profile/sessions',
        builder: (_, __) => const Scaffold(body: Text('Sessions')),
      ),
      GoRoute(
        path: '/profile/mfa',
        builder: (_, __) => const Scaffold(body: Text('MFA')),
      ),
      GoRoute(
        path: '/profile/notifications',
        builder: (_, __) => const Scaffold(body: Text('Notifications')),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      authProvider.overrideWith(() => _FakeAuthNotifier(authState)),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

const _testUser = AuthUser(
  id: 'u1',
  email: 'test@riad.fun',
  role: 'engineer',
  mfaRequired: false,
);

void main() {
  group('ProfileScreen', () {
    testWidgets('shows Профіль AppBar', (tester) async {
      await tester.pumpWidget(
          _wrap(const AuthAuthenticated(_testUser)));
      await tester.pumpAndSettle();
      expect(find.text('Профіль'), findsOneWidget);
    });

    testWidgets('shows user email', (tester) async {
      await tester.pumpWidget(
          _wrap(const AuthAuthenticated(_testUser)));
      await tester.pumpAndSettle();
      expect(find.text('test@riad.fun'), findsOneWidget);
    });

    testWidgets('shows role chip for engineer', (tester) async {
      await tester.pumpWidget(
          _wrap(const AuthAuthenticated(_testUser)));
      await tester.pumpAndSettle();
      expect(find.text('Інженер'), findsOneWidget);
    });

    testWidgets('shows navigation items', (tester) async {
      await tester.pumpWidget(
          _wrap(const AuthAuthenticated(_testUser)));
      await tester.pumpAndSettle();
      expect(find.text('Активні сесії'), findsOneWidget);
      expect(find.text('MFA пристрої'), findsOneWidget);
      expect(find.text('Сповіщення'), findsOneWidget);
      expect(find.text('Вийти'), findsOneWidget);
    });

    testWidgets('shows ? avatar when unauthenticated', (tester) async {
      await tester.pumpWidget(_wrap(const Unauthenticated()));
      await tester.pumpAndSettle();
      expect(find.text('?'), findsOneWidget);
    });

    testWidgets('roleName: installer → Монтажник', (tester) async {
      const installer = AuthUser(
        id: 'u2',
        email: 'i@riad.fun',
        role: 'installer',
        mfaRequired: false,
      );
      await tester.pumpWidget(
          _wrap(const AuthAuthenticated(installer)));
      await tester.pumpAndSettle();
      expect(find.text('Монтажник'), findsOneWidget);
    });
  });
}
