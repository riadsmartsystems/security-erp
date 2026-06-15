import 'package:flutter/material.dart';
import '../services/api_service.dart';

class EquipmentScreen extends StatefulWidget {
  const EquipmentScreen({super.key});

  @override
  State<EquipmentScreen> createState() => _EquipmentScreenState();
}

class _EquipmentScreenState extends State<EquipmentScreen> {
  List<dynamic> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadEquipment();
  }

  Future<void> _loadEquipment() async {
    try {
      final result = await api.get('/api/v1/equipment');
      setState(() {
        _items = result['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  String _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active': return '✅';
      case 'installed': return '🔧';
      case 'in_stock': return '📦';
      case 'repair': return '⚠️';
      case 'retired': return '🔴';
      default: return '⚪';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обладнання')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadEquipment,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final e = _items[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: Text(_statusIcon(e['status'] ?? ''), style: const TextStyle(fontSize: 24)),
                      title: Text(e['model'] ?? 'Без моделі'),
                      subtitle: Text('${e['equipment_code'] ?? ''} • ${e['serial_number'] ?? ''}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
