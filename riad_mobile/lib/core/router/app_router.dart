import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/mfa_enrollment_screen.dart';
import '../../features/auth/mfa_verify_screen.dart';
import '../../features/checklist/checklist_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/home/main_shell.dart';
import '../../features/visit/visit_detail_screen.dart';
import '../../features/visit/visit_list_screen.dart';
import '../auth/auth_models.dart';
import '../auth/auth_notifier.dart';
import 'route_names.dart';

class PlaceholderScreen extends StatelessWidget {
  final String name;
  const PlaceholderScreen(this.name, {super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Center(
          child: Text('$name\n(coming soon)', textAlign: TextAlign.center),
        ),
      );
}

/// Bridges Riverpod authProvider changes to GoRouter's Listenable interface.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen<AsyncValue<AuthState>>(authProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final listenable = _AuthListenable(ref);

  return GoRouter(
    initialLocation: Routes.login,
    refreshListenable: listenable,
    redirect: (context, state) {
      final authAsync = ref.read(authProvider);

      // While loading (first frame), stay put
      if (authAsync.isLoading) return null;

      final authState = authAsync.value;
      final isOnLogin = state.matchedLocation == Routes.login;
      final isOnMfa = state.matchedLocation == Routes.mfaVerify ||
          state.matchedLocation == Routes.mfaEnrollment;

      if (authState is Unauthenticated || authState is AuthInitial || authState == null) {
        return isOnLogin ? null : Routes.login;
      }
      if (authState is AuthMfaRequired) {
        return isOnMfa ? null : Routes.mfaVerify;
      }
      if (authState is AuthAuthenticated) {
        return (isOnLogin || isOnMfa) ? Routes.tasks : null;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: Routes.mfaEnrollment,
        builder: (_, __) => const MfaEnrollmentScreen(),
      ),
      GoRoute(
        path: Routes.mfaVerify,
        builder: (_, __) => const MfaVerifyScreen(),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: Routes.tasks,
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: Routes.objects,
            builder: (_, __) => const Scaffold(
                body: Center(child: Text("Об'єкти — FL5"))),
          ),
          GoRoute(
            path: Routes.vault,
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Vault — FL7'))),
          ),
          GoRoute(
            path: Routes.sync,
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Синк — FL6'))),
          ),
          GoRoute(
            path: '/home/visits',
            builder: (_, __) => const VisitListScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/estimate/:id',
        builder: (_, s) =>
            PlaceholderScreen('Estimate ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: '/lead/:id',
        builder: (_, s) =>
            PlaceholderScreen('Lead ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: Routes.visitDetail,
        builder: (_, s) =>
            VisitDetailScreen(visitId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.checklist,
        builder: (_, s) =>
            ChecklistScreen(visitId: s.pathParameters['visitId']!),
      ),
      GoRoute(
        path: Routes.objectDetail,
        builder: (_, s) =>
            PlaceholderScreen('Object ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: Routes.installationMap,
        builder: (_, s) =>
            PlaceholderScreen('Map ${s.pathParameters["objectId"]}'),
      ),
      GoRoute(
        path: Routes.scan,
        builder: (_, __) => const PlaceholderScreen('Scan'),
      ),
      GoRoute(
        path: Routes.voiceNote,
        builder: (_, s) =>
            PlaceholderScreen('Voice ${s.pathParameters["visitId"]}'),
      ),
      GoRoute(
        path: Routes.remoteInspection,
        builder: (_, s) =>
            PlaceholderScreen('RI ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: Routes.serviceRequest,
        builder: (_, s) =>
            PlaceholderScreen('Service ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: Routes.conflictResolution,
        builder: (_, s) =>
            PlaceholderScreen('Conflict ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, __) => const PlaceholderScreen('Profile'),
      ),
      GoRoute(
        path: Routes.sessions,
        builder: (_, __) => const PlaceholderScreen('Sessions'),
      ),
      GoRoute(
        path: Routes.mfaManagement,
        builder: (_, __) => const PlaceholderScreen('MFA Management'),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (_, __) => const PlaceholderScreen('Notifications'),
      ),
    ],
  );
});
