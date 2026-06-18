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

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Icons.check_circle;
      case 'installed': return Icons.build;
      case 'in_stock': return Icons.inventory_2;
      case 'repair': return Icons.warning;
      case 'retired': return Icons.cancel;
      default: return Icons.help_outline;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return Colors.green;
      case 'installed': return Colors.blue;
      case 'in_stock': return Colors.orange;
      case 'repair': return Colors.red;
      case 'retired': return Colors.grey;
      default: return Colors.grey;
    }
  }

  void _showCreateDialog() {
    final codeCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final serialCtrl = TextEditingController();
    final objectCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Нове обладнання'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeCtrl, decoration: const InputDecoration(labelText: 'Код обладнання')),
            const SizedBox(height: 8),
            TextField(controller: objectCtrl, decoration: const InputDecoration(labelText: 'Об\'єкт')),
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
                'equipment_code': codeCtrl.text,
                'security_object': objectCtrl.text,
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
                      leading: Icon(_statusIcon(e['status'] ?? ''), color: _statusColor(e['status'] ?? ''), size: 28),
                      title: Text(e['equipment_code'] ?? 'Без коду'),
                      subtitle: Text('${e['equipment_type'] ?? ''} • ${e['serial_number'] ?? ''}'),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
