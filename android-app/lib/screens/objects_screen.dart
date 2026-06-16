import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ObjectsScreen extends StatefulWidget {
  const ObjectsScreen({super.key});

  @override
  State<ObjectsScreen> createState() => _ObjectsScreenState();
}

class _ObjectsScreenState extends State<ObjectsScreen> {
  List<dynamic> _objects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadObjects();
  }

  Future<void> _loadObjects() async {
    try {
      final result = await api.get('/api/v2/objects');
      setState(() {
        _objects = result['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final typeCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Новий об\'єкт'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Назва')),
            const SizedBox(height: 8),
            TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Тип')),
            const SizedBox(height: 8),
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Адреса')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
          ElevatedButton(
            onPressed: () async {
              await api.post('/api/v2/objects', {
                'object_name': nameCtrl.text,
                'object_type': typeCtrl.text,
                'address': addressCtrl.text,
              });
              Navigator.pop(ctx);
              _loadObjects();
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
      appBar: AppBar(title: const Text('Об\'єкти')),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateDialog,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadObjects,
              child: ListView.builder(
                itemCount: _objects.length,
                itemBuilder: (context, index) {
                  final o = _objects[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.business)),
                      title: Text(o['object_name'] ?? 'Без назви'),
                      subtitle: Text('${o['object_type'] ?? ''} • ${o['address'] ?? ''}'),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
