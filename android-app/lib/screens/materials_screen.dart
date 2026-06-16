import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MaterialsScreen extends StatefulWidget {
  final String visitId;
  const MaterialsScreen({super.key, required this.visitId});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController(text: '0');
  List<Map<String, dynamic>> _materials = [];

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _addMaterial() async {
    if (_nameController.text.isEmpty) return;
    try {
      await api.post('/api/v2/visits/${widget.visitId}/materials', {
        'material_name': _nameController.text,
        'quantity': int.tryParse(_qtyController.text) ?? 1,
        'unit_price': double.tryParse(_priceController.text) ?? 0,
      });
      _nameController.clear();
      _qtyController.text = '1';
      _priceController.text = '0';
      _loadMaterials();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Матеріал додано')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Помилка: $e')),
        );
      }
    }
  }

  Future<void> _loadMaterials() async {
    try {
      final result = await api.get('/api/v2/visits/${widget.visitId}/materials');
      setState(() {
        _materials = (result['data'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e))
            .toList() ?? [];
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Матеріали')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Додати матеріал', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Назва',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _qtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Кількість',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Ціна',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addMaterial,
                      icon: const Icon(Icons.add),
                      label: const Text('Додати'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Додані матеріали (${_materials.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ..._materials.map((m) => Card(
            child: ListTile(
              leading: const Icon(Icons.inventory_2),
              title: Text('${m['material_name'] ?? ''}'),
              subtitle: Text('Кількість: ${m['quantity'] ?? 0} • Ціна: ${m['unit_price'] ?? 0}'),
              trailing: Text('${((m['quantity'] ?? 0) * (m['unit_price'] ?? 0)).toStringAsFixed(2)} ₴'),
            ),
          )),
        ],
      ),
    );
  }
}
