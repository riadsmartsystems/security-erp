import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import '../../core/router/route_names.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider).value;
    final user =
        authState is AuthAuthenticated ? authState.user : null;

    return Scaffold(
      appBar: AppBar(title: const Text('Профіль')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Center(
          child: Column(children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                user?.email.isNotEmpty == true
                    ? user!.email.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user?.email ?? '—',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 4),
            Chip(label: Text(_roleName(user?.role ?? ''))),
          ]),
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.devices_outlined),
          title: const Text('Активні сесії'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.sessions),
        ),
        ListTile(
          leading: const Icon(Icons.security_outlined),
          title: const Text('MFA пристрої'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.mfaManagement),
        ),
        ListTile(
          leading: const Icon(Icons.notifications_outlined),
          title: const Text('Сповіщення'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push(Routes.notifications),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title:
              const Text('Вийти', style: TextStyle(color: Colors.red)),
          onTap: () => _logout(context, ref),
        ),
      ]),
    );
  }

  String _roleName(String role) => switch (role) {
        'manager' => 'Керівник',
        'engineer' => 'Інженер',
        'installer' => 'Монтажник',
        'warehouse' => 'Склад',
        _ => role,
      };

  Future<void> _logout(BuildContext ctx, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Вийти?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Вийти'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(authProvider.notifier).logout();
      if (ctx.mounted) ctx.go(Routes.login);
    }
  }
}
