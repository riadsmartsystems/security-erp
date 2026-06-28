import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/home/providers/home_provider.dart';
import '../theme/color_tokens.dart';

class AiStatusChip extends ConsumerWidget {
  const AiStatusChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(aiStatusProvider);

    return status.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => _chip(AiStatus.manual),
      data: _chip,
    );
  }

  Widget _chip(AiStatus status) {
    final (color, label) = switch (status) {
      AiStatus.ok => (kAiGreen, 'AI'),
      AiStatus.degraded => (kAiYellow, 'AI резерв'),
      AiStatus.manual => (kAiGrey, 'Ручний режим'),
    };
    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: color.withValues(alpha: 0.15),
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      padding: EdgeInsets.zero,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
    );
  }
}
