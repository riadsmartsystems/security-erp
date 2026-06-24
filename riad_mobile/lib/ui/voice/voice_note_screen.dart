import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';
import '../../core/permissions/permission_service.dart';

class VoiceNoteScreen extends StatefulWidget {
  final RiadDatabase db;
  final String? parentDoctype;
  final String? parentName;

  const VoiceNoteScreen({super.key, required this.db, this.parentDoctype, this.parentName});

  @override
  State<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends State<VoiceNoteScreen> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  String? _recordedPath;

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() {
        _recording = false;
        _recordedPath = path;
      });
      if (path != null) await _saveRecording(path);
    } else {
      if (!await PermissionService.requestMicrophone()) return;

      final appDir = await getApplicationDocumentsDirectory();
      final mediaDir = Directory('${appDir.path}/media');
      if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

      final clientUuid = const Uuid().v4();
      final filePath = '${mediaDir.path}/$clientUuid.m4a';

      await _recorder.start(
        RecordConfig(encoder: AudioEncoder.aacLc),
        path: filePath,
      );
      setState(() => _recording = true);
    }
  }

  Future<void> _saveRecording(String path) async {
    final clientUuid = Uuid().v4();
    final appDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory('${appDir.path}/media');
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

    final localPath = '${mediaDir.path}/$clientUuid.m4a';
    await File(path).copy(localPath);

    await widget.db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: clientUuid,
      mediaType: 'audio',
      parentDoctype: widget.parentDoctype ?? '',
      parentName: widget.parentName ?? '',
      localPath: localPath,
      aiAllowed: const Value(false),
      transcriptionStatus: Value('pending'),
    ));

    await widget.db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
      clientUuid: clientUuid,
      localPath: localPath,
      mediaType: 'audio',
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
          'media_type': 'audio',
          'parent_doctype': widget.parentDoctype ?? '',
          'parent_name': widget.parentName ?? '',
        },
        'additive': {},
      }),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Голосова нотатка')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(_recording ? Icons.mic : Icons.mic_none, size: 80, color: _recording ? Colors.red : null),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _toggleRecording,
              icon: Icon(_recording ? Icons.stop : Icons.mic),
              label: Text(_recording ? 'Зупинити' : 'Почати запис'),
            ),
            if (_recordedPath != null) ...[
              const SizedBox(height: 16),
              const Text('Запис збережено. Транскрипція буде виконана після завантаження.'),
            ],
          ],
        ),
      ),
    );
  }
}
