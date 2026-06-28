import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull, Column;
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../data/local/database.dart';

class SyncConflictCard extends StatefulWidget {
  final RiadDatabase db;
  final String baseUrl;
  final String jwtToken;
  final VoidCallback? onResolved;

  const SyncConflictCard({
    super.key,
    required this.db,
    required this.baseUrl,
    required this.jwtToken,
    this.onResolved,
  });

  @override
  State<SyncConflictCard> createState() => _SyncConflictCardState();
}

class _SyncConflictCardState extends State<SyncConflictCard> {
  bool _isResolving = false;

  Future<void> _resolveConflict(String conflictId, String chosen) async {
    setState(() => _isResolving = true);

    try {
      final response = await http.post(
        Uri.parse('${widget.baseUrl}/api/v2/sync/resolve'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.jwtToken}',
        },
        body: jsonEncode({
          'conflict_id': conflictId,
          'chosen': chosen,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['ok'] == true) {
          await widget.db.resolveConflict(conflictId, true);
          if (chosen == 'client') {
            await _applyClientValue(conflictId);
          }
          widget.onResolved?.call();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Конфлікт вирішено')),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  Future<void> _applyClientValue(String conflictId) async {
    await widget.db.resolveConflictFieldValue(conflictId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SyncConflict>>(
      stream: _watchConflicts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final conflicts = snapshot.data!;
        return Card(
          color: Colors.orange.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Text(
                      'Конфлікти синхронізації (${conflicts.length})',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ...conflicts.map((conflict) => _buildConflictItem(conflict)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildConflictItem(SyncConflict conflict) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${conflict.doctype} - ${conflict.fieldName}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Сервер',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(conflict.serverValue ?? '(пусто)'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Клієнт',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      Text(conflict.clientValue ?? '(пусто)'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isResolving
                      ? null
                      : () => _resolveConflict(conflict.conflictId, 'server'),
                  child: const Text('Сервер'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isResolving
                      ? null
                      : () => _resolveConflict(conflict.conflictId, 'client'),
                  child: const Text('Клієнт'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Stream<List<SyncConflict>> _watchConflicts() {
    return (widget.db.select(widget.db.syncConflicts)
          ..where((t) => t.resolved.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.conflictId)]))
        .watch();
  }
}
