import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'visit_flow_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const TicketDetailScreen({super.key, required this.ticket});

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  List<dynamic> _visits = [];

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<void> _loadVisits() async {
    final ticketId = widget.ticket['name'] ?? widget.ticket['id'];
    final result = await api.get('/api/v1/visits?ticket_id=$ticketId&limit=20');
    setState(() { _visits = result['data'] ?? []; });
  }

  Future<void> _startVisit() async {
    final ticketId = widget.ticket['name'] ?? widget.ticket['id'];
    final engineerId = widget.ticket['assigned_engineer'];
    if (engineerId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Заявка не призначена інженеру. Спочатку призначте інженера.')),
        );
      }
      return;
    }
    final result = await api.post('/api/v1/visits', {
      'ticket_id': ticketId,
      'engineer_id': engineerId,
    });
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Виїзд створено!')),
      );
      _loadVisits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Scaffold(
      appBar: AppBar(title: Text(t['ticket_number'] ?? 'Заявка')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _infoRow('Пріоритет', '${t['priority'] ?? ''}'),
              _infoRow('Статус', '${t['status'] ?? ''}'),
              _infoRow('Створено', '${t['creation'] ?? ''}'),
            ]),
          )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => VisitFlowScreen(ticket: widget.ticket),
              ));
            },
            icon: const Icon(Icons.add),
            label: const Text('Створити виїзд'),
          ),
          const SizedBox(height: 16),
          Text('Виїзди (${_visits.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._visits.map((v) => Card(child: ListTile(
            leading: Icon(v['status'] == 'completed' ? Icons.check_circle : Icons.schedule),
            title: Text(v['visit_number'] ?? ''),
            subtitle: Text('${v['status'] ?? ''}'),
          ))),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.grey))),
        Expanded(child: Text(value)),
      ]),
    );
  }
}
