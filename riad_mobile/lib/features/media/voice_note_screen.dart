import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

import '../../core/api/dio_client.dart';
import '../../core/sync/media_upload_service.dart';

class VoiceNoteScreen extends ConsumerStatefulWidget {
  final String visitId;
  const VoiceNoteScreen({super.key, required this.visitId});

  @override
  ConsumerState<VoiceNoteScreen> createState() => _VoiceNoteScreenState();
}

class _VoiceNoteScreenState extends ConsumerState<VoiceNoteScreen> {
  final _recorder = AudioRecorder();
  bool _recording = false;
  String? _savedMediaId;
  String _transcriptionStatus = 'none';

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Голосова нотатка')),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_savedMediaId != null)
            TranscriptionStatusBadge(status: _transcriptionStatus),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: _recording ? _stop : _start,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _recording ? Colors.red : Colors.blue,
              ),
              child: Icon(
                _recording ? Icons.stop : Icons.mic,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_recording ? 'Записую...' : 'Натисніть для запису'),
        ]),
      ),
    );
  }

  Future<void> _start() async {
    if (!await _recorder.hasPermission()) return;
    final dir = await getApplicationDocumentsDirectory();
    final mediaId = const Uuid().v4();
    final path = '${dir.path}/media/$mediaId.aac';
    await Directory('${dir.path}/media').create(recursive: true);
    await _recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );
    setState(() => _recording = true);
  }

  Future<void> _stop() async {
    final path = await _recorder.stop();
    if (!mounted) return;
    setState(() => _recording = false);
    if (path == null) return;

    final mediaId = const Uuid().v4();
    await ref.read(mediaUploadProvider).saveAndQueue(
          mediaId: mediaId,
          localPath: path,
          parentDoctype: 'Engineer Visit',
          parentName: widget.visitId,
          tag: 'audio',
          mediaType: 'audio',
        );

    // Request transcription (non-critical; ignore failures)
    try {
      await ref
          .read(dioProvider)
          .post('/media/request_transcription', data: {'media_id': mediaId});
      if (mounted) {
        setState(() {
          _savedMediaId = mediaId;
          _transcriptionStatus = 'pending';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _savedMediaId = mediaId;
          _transcriptionStatus = 'none';
        });
      }
    }
  }
}

class TranscriptionStatusBadge extends StatelessWidget {
  final String status;
  const TranscriptionStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'pending' => (Colors.orange, 'Транскрипція: очікує...'),
      'ready' => (Colors.green, 'Транскрипція: готова'),
      'manual' => (Colors.grey, 'Транскрипція: вручну'),
      _ => (Colors.grey, 'Транскрипція: немає'),
    };
    return Chip(
      avatar: Icon(Icons.subtitles_outlined, color: color, size: 16),
      label: Text(label, style: TextStyle(color: color)),
      backgroundColor: color.withValues(alpha: 0.1),
    );
  }
}
