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
      final result = await api.get('/api/v1/objects');
      setState(() {
        _objects = result['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Об\'єкти')),
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
                      title: Text(o['name'] ?? 'Без назви'),
                      subtitle: Text(o['object_code'] ?? ''),
                      trailing: const Icon(Icons.arrow_forward_ios),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
