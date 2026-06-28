import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../core/sync/media_upload_service.dart';

enum PhotoTag {
  before('До'),
  after('Після'),
  cmm('CMM');

  const PhotoTag(this.label);
  final String label;
}

class CameraScreen extends ConsumerStatefulWidget {
  final String docType;
  final String docName;
  final PhotoTag defaultTag;

  const CameraScreen({
    super.key,
    required this.docType,
    required this.docName,
    this.defaultTag = PhotoTag.before,
  });

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  CameraController? _controller;
  PhotoTag _selectedTag = PhotoTag.before;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    _selectedTag = widget.defaultTag;
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty || !mounted) return;
    _controller = CameraController(cameras.first, ResolutionPreset.high);
    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller?.value.isInitialized == true;
    return Scaffold(
      appBar: AppBar(title: const Text('Фото')),
      body: isReady
          ? _buildCameraView()
          : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _buildCameraView() {
    return Stack(
      children: [
        CameraPreview(_controller!),
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: PhotoTag.values
                .map(
                  (t) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(t.label),
                      selected: _selectedTag == t,
                      onSelected: (_) => setState(() => _selectedTag = t),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        Positioned(
          bottom: 32,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _capturing ? null : _capture,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: _capturing
                      ? Colors.grey
                      : Colors.white.withValues(alpha: 0.2),
                ),
                child: _capturing
                    ? const CircularProgressIndicator()
                    : const Icon(Icons.camera, size: 32, color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _capture() async {
    setState(() => _capturing = true);
    try {
      final file = await _controller!.takePicture();
      final dir = await getApplicationDocumentsDirectory();
      final mediaId = const Uuid().v4();
      final dest = '${dir.path}/media/$mediaId.jpg';

      await Directory('${dir.path}/media').create(recursive: true);
      await File(file.path).copy(dest);

      await ref.read(mediaUploadProvider).saveAndQueue(
            mediaId: mediaId,
            localPath: dest,
            parentDoctype: widget.docType,
            parentName: widget.docName,
            tag: _selectedTag.name,
            mediaType: 'photo',
          );

      if (mounted) Navigator.of(context).pop(mediaId);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }
}
