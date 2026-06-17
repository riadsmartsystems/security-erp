import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'tickets_screen.dart';
import 'objects_screen.dart';
import 'equipment_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _objects = 0;
  int _equipment = 0;
  int _openTickets = 0;
  int _inProgressTickets = 0;
  int _overdueTickets = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final result = await api.get('/api/v2/stats');
      final data = result['data'] ?? {};
      setState(() {
        _objects = data['objects'] ?? 0;
        _equipment = data['equipment'] ?? 0;
        _openTickets = data['tickets_open'] ?? 0;
        _inProgressTickets = data['tickets_in_progress'] ?? 0;
        _overdueTickets = data['tickets_overdue'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security ERP'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildCard('🎫 Відкриті заявки', _openTickets, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen()));
                  }),
                  _buildCard('🔧 В роботі', _inProgressTickets, Colors.amber, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen()));
                  }),
                  _buildCard('⚠️ Прострочені', _overdueTickets, Colors.red, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen()));
                  }),
                  _buildCard('🏢 Об\'єкти', _objects, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ObjectsScreen()));
                  }),
                  _buildCard('🛠 Обладнання', _equipment, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentScreen()));
                  }),
                ],
              ),
            ),
    );
  }

  Widget _buildCard(String title, int count, Color color, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text('$count', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }
}
