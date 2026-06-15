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
  int _tickets = 0;
  int _objects = 0;
  int _equipment = 0;
  int _visits = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        api.get('/api/v1/tickets'),
        api.get('/api/v1/objects'),
        api.get('/api/v1/equipment'),
        api.get('/api/v1/visits'),
      ]);

      setState(() {
        _tickets = (results[0]['data'] as List?)?.length ?? 0;
        _objects = (results[1]['data'] as List?)?.length ?? 0;
        _equipment = (results[2]['data'] as List?)?.length ?? 0;
        _visits = (results[3]['data'] as List?)?.length ?? 0;
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
                  _buildCard('🎫 Заявки', _tickets, Colors.blue, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const TicketsScreen()));
                  }),
                  _buildCard('🏢 Об\'єкти', _objects, Colors.green, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ObjectsScreen()));
                  }),
                  _buildCard('🔧 Обладнання', _equipment, Colors.orange, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const EquipmentScreen()));
                  }),
                  _buildCard('🚗 Виїзди', _visits, Colors.purple, () {}),
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
