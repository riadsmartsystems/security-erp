import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/api/dio_client.dart';
import '../../core/sync/sync_queue_service.dart';

class ServiceRequestScreen extends ConsumerStatefulWidget {
  final String requestId;
  const ServiceRequestScreen({super.key, required this.requestId});

  @override
  ConsumerState<ServiceRequestScreen> createState() =>
      _ServiceRequestScreenState();
}

class _ServiceRequestScreenState
    extends ConsumerState<ServiceRequestScreen> {
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final resp = await ref
          .read(dioProvider)
          .get('/service-requests/${widget.requestId}');
      if (mounted) {
        setState(() => _data = resp.data as Map<String, dynamic>);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (_data == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // DTO-driven: якщо сервер не повернув фінансових полів → їх немає в UI
    final actions =
        (_data!['actions'] as List? ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      appBar: AppBar(title: const Text('Сервісна заявка')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _data!['description'] as String? ?? '—',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  'Статус: ${_data!['status']}',
                  style: const TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Виконані дії',
            style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...actions.map((a) => Card(
              child: ListTile(
                title: Text(a['action_type'] as String? ?? ''),
                subtitle: Text(a['notes'] as String? ?? ''),
                leading: const Icon(Icons.check_circle_outline,
                    color: Colors.green),
              ),
            )),
        const SizedBox(height: 16),
        FilledButton.icon(
          icon: const Icon(Icons.add),
          label: const Text('Додати дію'),
          onPressed: _addAction,
        ),
      ]),
    );
  }

  Future<void> _addAction() async {
    final actionType = await _showActionTypeDialog();
    if (actionType == null) return;

    final actionId = const Uuid().v4();
    await ref.read(syncQueueProvider).enqueue(
      docType: 'Service Action',
      name: actionId,
      operation: 'create',
      payload: {
        'name': actionId,
        'request_id': widget.requestId,
        'action_type': actionType,
        'notes': '',
      },
    );

    if (mounted) {
      setState(() {
        (_data!['actions'] as List)
            .add({'action_type': actionType, 'notes': ''});
      });
    }
  }

  Future<String?> _showActionTypeDialog() => showDialog<String>(
        context: context,
        builder: (_) => SimpleDialog(
          title: const Text('Тип дії'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'inspection'),
              child: const Text('Огляд'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'repair'),
              child: const Text('Ремонт'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'replacement'),
              child: const Text('Заміна обладнання'),
            ),
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, 'cleaning'),
              child: const Text('Технічне обслуговування'),
            ),
          ],
        ),
      );
}
