import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  final String visitId;
  const PhotoUploadScreen({super.key, required this.visitId});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  String _selectedType = 'after';
  final List<String> _types = ['before', 'after', 'problem', 'equipment'];
  final List<Map<String, dynamic>> _photos = [];
  bool _isUploading = false;
  final _storage = const FlutterSecureStorage();

  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (image == null) return;

    File imageFile = File(image.path);
    
    setState(() {
      _photos.add({
        'file': imageFile,
        'type': _selectedType,
        'caption': '',
        'status': 'pending',
      });
    });

    await _uploadPhoto(_photos.last);
  }

  Future<void> _uploadPhoto(Map<String, dynamic> photo) async {
    setState(() => _isUploading = true);
    try {
      final token = await _storage.read(key: 'token');
      final uri = Uri.parse('${ApiService.baseUrl}/api/v1/visits/${widget.visitId}/photos');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';
      
      request.fields['type'] = photo['type'];
      request.fields['caption'] = photo['caption'];
      
      request.files.add(await http.MultipartFile.fromPath('file', photo['file'].path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          photo['status'] = 'uploaded';
        });
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        photo['status'] = 'error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка завантаження: $e')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
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
          if (_isUploading)
            const LinearProgressIndicator(),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Зробити фото'),
          ),
          const SizedBox(height: 16),
          Text('Фотографії (${_photos.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._photos.map((p) => Card(
            child: ListTile(
              leading: p['file'] != null 
                ? Image.file(p['file'], width: 50, height: 50, fit: BoxFit.cover)
                : const Icon(Icons.image),
              title: Text('Тип: ${p['type']}'),
              subtitle: Text(p['status'] == 'uploaded' ? '✅ Завантажено' : (p['status'] == 'error' ? '❌ Помилка' : '⏳ Завантаження...')),
              trailing: p['status'] == 'error' 
                ? IconButton(icon: const Icon(Icons.refresh), onPressed: () => _uploadPhoto(p))
                : null,
            ),
          )),
        ],
      ),
    );
  }
}
