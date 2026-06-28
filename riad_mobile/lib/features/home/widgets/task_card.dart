import 'package:flutter/material.dart';
import '../task_model.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;

  const TaskCard({super.key, required this.task, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        minTileHeight: 64,
        leading: CircleAvatar(
          backgroundColor: _typeColor(task.type).withValues(alpha: 0.2),
          child: Icon(_typeIcon(task.type),
              color: _typeColor(task.type), size: 20),
        ),
        title:
            Text(task.title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${task.objectName} · ${task.address}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (task.dueTime != null)
              Text(task.dueTime!, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            _StatusBadge(task.status),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _typeColor(TaskType t) => switch (t) {
        TaskType.visit => Colors.blue,
        TaskType.checklist => Colors.green,
        TaskType.service => Colors.orange,
        TaskType.remoteInspection => Colors.purple,
        TaskType.estimate => Colors.teal,
      };

  IconData _typeIcon(TaskType t) => switch (t) {
        TaskType.visit => Icons.drive_eta_outlined,
        TaskType.checklist => Icons.checklist_outlined,
        TaskType.service => Icons.build_outlined,
        TaskType.remoteInspection => Icons.videocam_outlined,
        TaskType.estimate => Icons.calculate_outlined,
      };
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'draft' => (Colors.grey, 'Чернетка'),
      'in_progress' => (Colors.blue, 'В роботі'),
      'done' => (Colors.green, 'Виконано'),
      'pending' => (Colors.orange, 'Очікує'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color)),
    );
  }
}
