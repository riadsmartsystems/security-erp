import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

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
      final objects = result['data'] ?? [];
      
      // Cache the objects
      await CacheService.save('objects_list', objects);
      
      setState(() {
        _objects = objects;
        _loading = false;
      });
    } catch (e) {
      // Try to load from cache on error
      try {
        final cached = await CacheService.load('objects_list');
        if (cached != null) {
          setState(() {
            _objects = cached;
            _loading = false;
          });
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Працюємо в офлайн-режимі (дані з кешу)')),
            );
          }
        } else {
          setState(() { _loading = false; });
        }
      } catch (cacheError) {
        setState(() { _loading = false; });
      }
    }
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    String objectType = 'Shop';
    final objectTypes = ['Shop', 'Office', 'Warehouse', 'Apartment', 'Factory', 'School', 'Other'];
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Новий об\'єкт', style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl, 
                    decoration: const InputDecoration(
                      labelText: 'Назва *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Обов\'язкове поле' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: objectType,
                    decoration: const InputDecoration(
                      labelText: 'Тип',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    items: objectTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) { setDialogState(() { objectType = v!; }); },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: addressCtrl, 
                    decoration: const InputDecoration(
                      labelText: 'Адреса *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Обов\'язкове поле' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Скасувати')),
            ElevatedButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final now = DateTime.now();
                  final objectCode = 'OBJ-${now.year}${now.month.toString().padLeft(2,'0')}${now.day.toString().padLeft(2,'0')}-${now.millisecond.toString().padLeft(4,'0')}';
                  await api.post('/api/v2/objects', {
                    'object_code': objectCode,
                    'object_name': nameCtrl.text,
                    'object_type': objectType,
                    'address': addressCtrl.text,
                  });
                  Navigator.pop(ctx);
                  _loadObjects();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Об\'єкт створено'), backgroundColor: Colors.green));
                  }
                } catch (e) {
                  Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red));
                  }
                }
              },
              child: const Text('Створити'),
            ),
          ],
        ),
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
