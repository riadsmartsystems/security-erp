import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.login,
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, __) => const PlaceholderScreen('Login'),
      ),
      GoRoute(
        path: Routes.mfaEnrollment,
        builder: (_, __) => const PlaceholderScreen('MFA Enrollment'),
      ),
      GoRoute(
        path: Routes.mfaVerify,
        builder: (_, __) => const PlaceholderScreen('MFA Verify'),
      ),
      ShellRoute(
        builder: (_, __, child) => child,
        routes: [
          GoRoute(
            path: Routes.tasks,
            builder: (_, __) => const PlaceholderScreen('Tasks Today'),
          ),
          GoRoute(
            path: Routes.objects,
            builder: (_, __) => const PlaceholderScreen('Objects'),
          ),
          GoRoute(
            path: Routes.vault,
            builder: (_, __) => const PlaceholderScreen('Vault'),
          ),
          GoRoute(
            path: Routes.sync,
            builder: (_, __) => const PlaceholderScreen('Sync'),
          ),
        ],
      ),
      GoRoute(
        path: Routes.visitDetail,
        builder: (_, s) => PlaceholderScreen('Visit ${s.pathParameters["id"]}'),
      ),
      GoRoute(
        path: Routes.checklist,
        builder: (_, s) =>
            PlaceholderScreen('Checklist ${s.pathParameters["visitId"]}'),
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
