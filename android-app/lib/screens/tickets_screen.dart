import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'ticket_detail_screen.dart';

class TicketsScreen extends StatefulWidget {
  const TicketsScreen({super.key});

  @override
  State<TicketsScreen> createState() => _TicketsScreenState();
}

class _TicketsScreenState extends State<TicketsScreen> {
  List<dynamic> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    try {
      final result = await api.get('/api/v2/tickets');
      setState(() {
        _tickets = result['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.blue;
      case 'low': return Colors.green;
      default: return Colors.grey;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical': return Icons.warning;
      case 'high': return Icons.arrow_upward;
      case 'medium': return Icons.remove;
      case 'low': return Icons.arrow_downward;
      default: return Icons.help_outline;
    }
  }

  void _showCreateDialog() {
    final titleCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final priorityCtrl = TextEditingController(text: 'medium');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нова заявка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Назва')),
            const SizedBox(height: 8),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Тип')),
            const SizedBox(height: 8),
            TextField(controller: priorityCtrl, decoration: const InputDecoration(labelText: 'Пріоритет')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              await api.post('/api/v2/tickets', {
                'title': titleCtrl.text,
                'ticket_type': typeCtrl.text,
                'priority': priorityCtrl.text,
              });
              Navigator.pop(ctx);
              _loadTickets();
            },
            child: const Text('Створити'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Заявки')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadTickets,
              child: ListView.builder(
                itemCount: _tickets.length,
                itemBuilder: (context, index) {
                  final t = _tickets[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _priorityColor(t['priority'] ?? ''),
                      child: Icon(
                        _priorityIcon(t['priority'] ?? ''),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                      title: Text(t['title'] ?? 'Без назви'),
                      subtitle: Text('${t['ticket_number'] ?? ''} • ${t['status'] ?? ''}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => TicketDetailScreen(ticket: t),
                        ));
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }
}
