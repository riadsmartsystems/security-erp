import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/color_tokens.dart';
import '../providers/vault_provider.dart';

class VaultEntryTile extends ConsumerStatefulWidget {
  final VaultEntry entry;
  const VaultEntryTile({super.key, required this.entry});

  @override
  ConsumerState<VaultEntryTile> createState() => _VaultEntryTileState();
}

class _VaultEntryTileState extends ConsumerState<VaultEntryTile> {
  String? _revealedValue;
  bool _auditLogged = false;
  bool _loading = false;

  @override
  Widget build(BuildContext context) => Card(
        color: kVaultAccent.withValues(alpha: 0.05),
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.entry.label,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.entry.username,
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 13),
                      ),
                    ]),
              ),
              if (_auditLogged)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kVaultAccent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.verified_outlined,
                        size: 12, color: kVaultAccent),
                    SizedBox(width: 4),
                    Text(
                      'Записано в аудит',
                      style: TextStyle(fontSize: 10, color: kVaultAccent),
                    ),
                  ]),
                ),
            ]),
            const SizedBox(height: 12),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(children: [
                Expanded(
                  child: Text(
                    _revealedValue ?? widget.entry.maskedValue,
                    style: TextStyle(
                      fontFamily: _revealedValue != null ? 'monospace' : null,
                      letterSpacing: _revealedValue == null ? 4 : null,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_revealedValue != null)
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    tooltip: 'Скопіювати',
                    onPressed: () {
                      Clipboard.setData(
                          ClipboardData(text: _revealedValue!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Скопійовано'),
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
              ]),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: [
              if (_revealedValue == null)
                TextButton.icon(
                  icon: _loading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.visibility_outlined, size: 16),
                  label: const Text('Показати'),
                  onPressed: _loading ? null : _reveal,
                )
              else
                TextButton.icon(
                  icon:
                      const Icon(Icons.visibility_off_outlined, size: 16),
                  label: const Text('Сховати'),
                  onPressed: () => setState(() => _revealedValue = null),
                ),
            ]),
          ]),
        ),
      );

  Future<void> _reveal() async {
    setState(() => _loading = true);
    try {
      final value =
          await ref.read(vaultProvider.notifier).revealEntry(widget.entry.id);
      setState(() {
        _revealedValue = value;
        _auditLogged = true;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Помилка: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
