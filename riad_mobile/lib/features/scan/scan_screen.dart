import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends ConsumerStatefulWidget {
  final String visitId;
  const ScanScreen({super.key, required this.visitId});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen> {
  final Set<String> _scannedInSession = {};
  bool _paused = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Скан серійника')),
      body: Stack(children: [
        MobileScanner(
          onDetect: (capture) {
            if (_paused) return;
            final code = capture.barcodes.firstOrNull?.rawValue;
            if (code != null) _handleScan(code);
          },
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(
                'Відскановано: ${_scannedInSession.length}',
                style: const TextStyle(color: Colors.white),
              ),
              ..._scannedInSession.map((s) =>
                  Text(s, style: const TextStyle(color: Colors.white70, fontSize: 12))),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _handleScan(String code) async {
    setState(() => _paused = true);

    if (_scannedInSession.contains(code)) {
      _showSnack('Дублікат: $code', color: Colors.orange);
      setState(() => _paused = false);
      return;
    }

    setState(() => _scannedInSession.add(code));
    _showSnack('Збережено: $code', color: Colors.green);

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) setState(() => _paused = false);
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      duration: const Duration(milliseconds: 1500),
    ));
  }
}
