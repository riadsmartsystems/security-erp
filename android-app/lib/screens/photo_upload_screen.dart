import 'package:flutter/material.dart';

class PhotoUploadScreen extends StatefulWidget {
  final String visitId;
  const PhotoUploadScreen({super.key, required this.visitId});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  String _selectedType = 'after';
  final List<String> _types = ['before', 'after', 'problem', 'equipment'];
  final List<Map<String, String>> _photos = [];

  void _addPhoto() {
    setState(() {
      _photos.add({'type': _selectedType, 'caption': ''});
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Фото додано (демо)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Фотозвіт: ${widget.visitId}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Тип фото:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: _types.map((t) => ChoiceChip(
              label: Text(t),
              selected: _selectedType == t,
              onSelected: (_) => setState(() => _selectedType = t),
            )).toList(),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Завантажити фото'),
          ),
          const SizedBox(height: 16),
          Text('Завантажені фото (${_photos.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._photos.map((p) => Card(child: ListTile(
            leading: const Icon(Icons.image),
            title: Text('Тип: ${p['type']}'),
          ))),
        ],
      ),
    );
  }
}
