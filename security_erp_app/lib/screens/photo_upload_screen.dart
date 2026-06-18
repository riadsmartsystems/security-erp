import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../core/theme.dart';
import '../services/api_service.dart';
import '../services/sync_queue_service.dart';

class PhotoUploadScreen extends StatefulWidget {
  final String visitId;
  final String? zoneId;
  const PhotoUploadScreen({super.key, required this.visitId, this.zoneId});

  @override
  State<PhotoUploadScreen> createState() => _PhotoUploadScreenState();
}

class _PhotoUploadScreenState extends State<PhotoUploadScreen> {
  String _selectedType = 'after';
  final List<String> _types = ['before', 'after', 'problem', 'equipment'];
  final List<Map<String, dynamic>> _photos = [];
  bool _isUploading = false;


  Future<void> _addPhoto() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1080,
    );

    if (image == null) return;

    final filePath = image.path;
    final photoIndex = _photos.length;

    setState(() {
      _photos.add({
        'path': filePath,
        'type': _selectedType,
        'caption': '',
        'status': 'uploading',
      });
    });

    await _uploadPhoto(photoIndex, File(filePath));
  }

  Future<void> _uploadPhoto(int index, File file) async {
    setState(() => _isUploading = true);
    try {
      final request = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}/api/v1/visits/${widget.visitId}/photos'));
      
      final storage = FlutterSecureStorage();
      final tokenStr = await storage.read(key: 'token');
      if (tokenStr != null) {
        request.headers['Authorization'] = 'Bearer $tokenStr';
      }

      request.fields['type'] = _photos[index]['type'];
      request.fields['caption'] = _photos[index]['caption'];
      if (widget.zoneId != null) {
        request.fields['zone'] = widget.zoneId!;
      }
      request.files.add(await http.MultipartFile.fromPath('file', file.path));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() {
          _photos[index]['status'] = 'uploaded';
        });
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      // Store in sync queue for offline support
      await syncQueue.enqueue(
        '/api/v1/visits/${widget.visitId}/photos',
        'POST',
        {
          'type': _photos[index]['type'],
          'caption': _photos[index]['caption'],
          if (widget.zoneId != null) 'zone': widget.zoneId!,
        },
        filePath: file.path,
      );

      setState(() {
        _photos[index]['status'] = 'error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Офлайн: Фото додано в чергу синхронізації')),
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
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _addPhoto,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Зробити фото'),
          ),
          const SizedBox(height: 16),
          Text('Завантажені фото (${_photos.length})', 
               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._photos.map((p) => Card(
            child: ListTile(
               leading: p['status'] == 'uploading' 
                   ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                   : p['status'] == 'error'
                       ? const Icon(Icons.error, color: AppColors.danger)
                       : Image.file(File(p['path']), width: 40, height: 40, fit: BoxFit.cover),
              title: Text('Тип: ${p['type']}'),
              subtitle: Text(p['status'] == 'uploading' ? 'Завантаження...' : 
                             p['status'] == 'error' ? 'Помилка' : 'Завантажено'),
              trailing: p['status'] == 'error' 
                  ? IconButton(icon: const Icon(Icons.refresh), onPressed: () async {
                      // Simple retry logic: find index and re-upload
                      int idx = _photos.indexOf(p);
                      await _uploadPhoto(idx, File(p['path']));
                    })
                  : null,
            ),
          )),
        ],
      ),
    );
  }
}
