import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/home_provider.dart';
import 'task_model.dart';
import 'widgets/task_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(tasksProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(tasksProvider.future),
      child: tasks.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 8),
              Text('Помилка: $e'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => ref.invalidate(tasksProvider),
                child: const Text('Повторити'),
              ),
            ],
          ),
        ),
        data: (taskList) {
          if (taskList.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('Задач на сьогодні немає',
                      style: TextStyle(fontSize: 16)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: taskList.length,
            itemBuilder: (ctx, i) => TaskCard(
              task: taskList[i],
              onTap: () => _openTask(ctx, taskList[i]),
            ),
          );
        },
      ),
    );
  }

  void _openTask(BuildContext ctx, Task task) {
    switch (task.type) {
      case TaskType.visit:
        ctx.push('/visit/${task.id}');
      case TaskType.checklist:
        ctx.push('/checklist/${task.id}');
      case TaskType.service:
        ctx.push('/service/${task.id}');
      case TaskType.remoteInspection:
        ctx.push('/remote-inspection/${task.id}');
      case TaskType.estimate:
        break; // PWA only
    }
  }
}
