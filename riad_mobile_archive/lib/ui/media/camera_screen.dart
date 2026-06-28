import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:camera/camera.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';
import '../../core/permissions/permission_service.dart';

class CameraScreen extends StatefulWidget {
  final RiadDatabase db;
  final String? parentDoctype;
  final String? parentName;

  const CameraScreen({super.key, required this.db, this.parentDoctype, this.parentName});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  String _selectedTag = 'до';
  bool _initialized = false;

  static const _tags = ['до', 'під час', 'після', 'СММ'];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (!await PermissionService.requestCamera()) return;
    if (!await PermissionService.requestMicrophone()) return;

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    setState(() => _initialized = true);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final xFile = await _controller!.takePicture();
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/media');
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

    final clientUuid = const Uuid().v4();
    final ext = xFile.path.split('.').last;
    final localPath = '${mediaDir.path}/$clientUuid.$ext';
    await File(xFile.path).copy(localPath);

    await widget.db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: clientUuid,
      mediaType: const Value('photo'),
      tag: Value(_selectedTag),
      parentDoctype: Value(widget.parentDoctype ?? ''),
      parentName: Value(widget.parentName ?? ''),
      localPath: Value(localPath),
      aiAllowed: const Value(false),
    ));

    await widget.db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
      clientUuid: clientUuid,
      localPath: localPath,
      mediaType: 'photo',
      tag: Value(_selectedTag),
      parentDoctype: Value(widget.parentDoctype ?? ''),
      parentName: Value(widget.parentName ?? ''),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));

    await widget.db.createPendingOp(PendingOpsCompanion.insert(
      doctype: 'Media Asset',
      name: clientUuid,
      op: 'upsert',
      payload: jsonEncode({
        'scalars': {
          'media_type': 'photo',
          'tag': _selectedTag,
          'parent_doctype': widget.parentDoctype ?? '',
          'parent_name': widget.parentName ?? '',
        },
        'additive': {},
      }),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));

    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Камера'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _selectedTag = v),
            itemBuilder: (_) => _tags.map((t) => PopupMenuItem(value: t, child: Text(t))).toList(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Chip(label: Text(_selectedTag)),
            ),
          ),
        ],
      ),
      body: _initialized && _controller != null
          ? CameraPreview(_controller!)
          : const Center(child: CircularProgressIndicator()),
      floatingActionButton: FloatingActionButton(
        onPressed: _takePicture,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
