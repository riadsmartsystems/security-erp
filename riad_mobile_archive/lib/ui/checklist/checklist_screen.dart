import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import '../../data/local/database.dart';

class ChecklistScreen extends StatelessWidget {
  final RiadDatabase db;
  final String instanceUuid;

  const ChecklistScreen({super.key, required this.db, required this.instanceUuid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Чек-лист')),
      body: StreamBuilder<List<ChecklistInstanceItem>>(
        stream: db.watchChecklistItems(instanceUuid),
        builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) return const Center(child: Text('Немає пунктів'));
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (ctx, i) => _ChecklistItem(
              item: items[i],
              onToggle: (checked) => _toggleItem(items[i], checked),
            ),
          );
        },
      ),
    );
  }

  Future<void> _toggleItem(ChecklistInstanceItem item, bool checked) async {
    await (db.update(db.checklistInstanceItems)
      ..where((t) => t.itemUuid.equals(item.itemUuid)))
        .write(ChecklistInstanceItemsCompanion(
          checkedBy: Value(checked ? 'current_user' : null),
        ));

    await db.createPendingOp(PendingOpsCompanion.insert(
      doctype: 'Checklist Instance',
      name: item.instanceUuid,
      op: 'upsert',
      payload: jsonEncode({
        'scalars': {'status': 'in_progress'},
        'additive': {
          'checklist_instance_item': [
            {
              '_uuid': item.itemUuid,
              'checked_by': checked ? 'current_user' : null,
            },
          ],
        },
      }),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }
}

class _ChecklistItem extends StatelessWidget {
  final ChecklistInstanceItem item;
  final ValueChanged<bool> onToggle;

  const _ChecklistItem({required this.item, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final isChecked = item.checkedBy != null && item.checkedBy!.isNotEmpty;
    return CheckboxListTile(
      value: isChecked,
      onChanged: (v) => onToggle(v ?? false),
      title: Text(item.value ?? item.serialNo ?? 'Пункт'),
      subtitle: item.photo != null ? const Text('Фото додано') : null,
      secondary: item.photo != null ? const Icon(Icons.camera_alt, size: 20) : null,
    );
  }
}
