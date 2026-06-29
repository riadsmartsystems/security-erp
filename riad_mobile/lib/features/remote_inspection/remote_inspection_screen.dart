import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/dio_client.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/widgets/offline_banner.dart';

class RemoteInspectionScreen extends ConsumerStatefulWidget {
  final String inspectionId;
  const RemoteInspectionScreen({super.key, required this.inspectionId});

  @override
  ConsumerState<RemoteInspectionScreen> createState() =>
      _RemoteInspectionScreenState();
}

class _RemoteInspectionScreenState
    extends ConsumerState<RemoteInspectionScreen> {
  Map<String, dynamic>? _data;
  final _reportCtrl = TextEditingController();
  bool _loading = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final isOnline = ref.read(connectivityProvider).value ?? false;
    if (!isOnline) return;
    setState(() => _loading = true);
    try {
      final dio = ref.read(dioProvider);
      final resp = await dio.get('/remote-inspections/${widget.inspectionId}');
      setState(() {
        _data = resp.data as Map<String, dynamic>;
        _reportCtrl.text = _data?['report_text'] as String? ?? '';
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = ref.watch(connectivityProvider).value ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Віддалений огляд')),
      body: Column(children: [
        const OfflineBanner(),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _buildBody(isOnline),
        ),
      ]),
    );
  }

  Widget _buildBody(bool isOnline) {
    if (_data == null && !isOnline) {
      return const Center(
        child: Text('Недоступно офлайн. Підключіться для перегляду.'),
      );
    }
    if (_data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(padding: const EdgeInsets.all(16), children: [
      _MediaSection(
        mediaIds:
            (_data!['media_ids'] as List? ?? []).cast<String>(),
      ),
      const SizedBox(height: 16),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Звіт огляду',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _reportCtrl,
                maxLines: 5,
                enabled: isOnline,
                decoration: const InputDecoration(
                    hintText: 'Опис результатів огляду...'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: isOnline && !_submitting ? _submit : null,
                child: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child:
                            CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Надіслати звіт'),
              ),
              if (!isOnline)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Відправка доступна лише онлайн',
                    style:
                        TextStyle(color: Colors.orange, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    ]);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/remote-inspections/${widget.inspectionId}', data: {
        'status': 'completed',
        'report_text': _reportCtrl.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Звіт надіслано'),
          backgroundColor: Colors.green,
        ));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _reportCtrl.dispose();
    super.dispose();
  }
}

class _MediaSection extends StatelessWidget {
  final List<String> mediaIds;
  const _MediaSection({required this.mediaIds});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Медіафайли (${mediaIds.length})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (mediaIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Немає прикріплених файлів',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ...mediaIds.map((id) => ListTile(
                    leading: const Icon(Icons.attach_file),
                    title: Text(id,
                        style: const TextStyle(fontSize: 12)),
                    dense: true,
                  )),
            ],
          ),
        ),
      );
}
