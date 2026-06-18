import 'package:flutter/material.dart';
import '../core/theme.dart';

class PriorityBadge extends StatelessWidget {
  final String priority;
  const PriorityBadge({super.key, required this.priority});

  Color _getPriorityColor() {
    switch (priority.toLowerCase()) {
      case 'critical':
      case 'emergency':
        return AppColors.danger;
      case 'high':
        return AppColors.warning;
      case 'medium':
        return AppColors.accent;
      case 'low':
        return AppColors.info;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _getPriorityColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _getPriorityColor(), width: 1),
      ),
      child: Text(
        priority,
        style: TextStyle(
          color: _getPriorityColor(),
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
