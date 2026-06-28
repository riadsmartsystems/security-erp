import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../providers/vault_provider.dart';

class VaultSessionTimer extends ConsumerStatefulWidget {
  const VaultSessionTimer({super.key});
  @override
  ConsumerState<VaultSessionTimer> createState() => _VaultSessionTimerState();
}

class _VaultSessionTimerState extends ConsumerState<VaultSessionTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateRemaining());
  }

  void _updateRemaining() {
    final expiresAt = ref.read(vaultProvider).sessionExpiresAt;
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) {
      _timer?.cancel();
      ref.read(vaultProvider.notifier).logout();
      return;
    }
    setState(() => _remaining = remaining);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes =
        _remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
    final isUrgent = _remaining.inSeconds < 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: (isUrgent ? Colors.red : kVaultAccent).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              (isUrgent ? Colors.red : kVaultAccent).withValues(alpha: 0.4),
        ),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          Icons.timer_outlined,
          size: 14,
          color: isUrgent ? Colors.red : kVaultAccent,
        ),
        const SizedBox(width: 4),
        Text(
          '$minutes:$seconds',
          style: TextStyle(
            fontSize: 12,
            color: isUrgent ? Colors.red : kVaultAccent,
            fontFamily: 'monospace',
          ),
        ),
      ]),
    );
  }
}
