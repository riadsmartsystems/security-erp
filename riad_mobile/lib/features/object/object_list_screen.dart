import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/object_provider.dart';

class ObjectListScreen extends ConsumerWidget {
  const ObjectListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objects = ref.watch(objectListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Обʼєкти")),
      body: objects.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text("Немає об'єктів"));
          }
          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final obj = list[i];
              return ListTile(
                leading: const Icon(Icons.location_city_outlined),
                title: Text(obj['name'] as String? ?? '—'),
                subtitle: Text(
                  '${obj['address'] as String? ?? ''} · ${obj['customer_name'] as String? ?? ''}',
                ),
                onTap: () => context.push('/object/${obj['id'] ?? obj['name']}'),
              );
            },
          );
        },
      ),
    );
  }
}
