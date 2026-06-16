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
      final result = await api.get('/api/v2/equipment');
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

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нове обладнання'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Назва')),
            const SizedBox(height: 8),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Тип')),
            const SizedBox(height: 8),
            TextField(controller: serialCtrl, decoration: const InputDecoration(labelText: 'Серійний номер')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              await api.post('/api/v2/equipment', {
                'equipment_name': nameCtrl.text,
                'equipment_type': typeCtrl.text,
                'serial_number': serialCtrl.text,
              });
              Navigator.pop(ctx);
              _loadEquipment();
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
      appBar: AppBar(title: const Text('Обладнання')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
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
                      title: Text(e['equipment_name'] ?? 'Без назви'),
                      subtitle: Text('${e['equipment_type'] ?? ''} • ${e['serial_number'] ?? ''}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
