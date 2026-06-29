import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';

final sessionsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.read(dioProvider).get('/auth/sessions');
  final data = resp.data as Map<String, dynamic>;
  return (data['sessions'] as List)
      .cast<Map<String, dynamic>>();
});

class SessionsScreen extends ConsumerWidget {
  const SessionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Активні сесії')),
      body: sessions.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (list) => list.isEmpty
            ? const Center(child: Text('Немає активних сесій'))
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final s = list[i];
                  final isCurrent = s['is_current'] as bool? ?? false;
                  return ListTile(
                    leading: Icon(
                      Icons.phone_android_outlined,
                      color: isCurrent ? Colors.green : null,
                    ),
                    title: Text(
                        s['device_name'] as String? ?? 'Пристрій'),
                    subtitle: Text(
                        'Остання активність: ${s['last_used']}'),
                    trailing: isCurrent
                        ? const Chip(label: Text('Поточна'))
                        : IconButton(
                            icon: const Icon(Icons.logout,
                                color: Colors.red),
                            tooltip: 'Відкликати',
                            onPressed: () => _revoke(
                                ctx, ref, s['id'] as String),
                          ),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _revoke(
      BuildContext ctx, WidgetRef ref, String sessionId) async {
    try {
      await ref
          .read(dioProvider)
          .delete('/auth/sessions/$sessionId');
      ref.invalidate(sessionsProvider);
    } catch (e) {
      if (!ctx.mounted) return;
      ScaffoldMessenger.of(ctx).showSnackBar(
        SnackBar(content: Text('Помилка: $e')),
      );
    }
  }
}
