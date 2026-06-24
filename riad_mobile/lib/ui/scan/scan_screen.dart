import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';
import '../../data/local/database.dart';

class ScanScreen extends StatefulWidget {
  final RiadDatabase db;
  final String visitUuid;

  const ScanScreen({super.key, required this.db, required this.visitUuid});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сканер серійника')),
      body: MobileScanner(
        onDetect: (capture) async {
          if (_scanned) return;
          final code = capture.barcodes.first.rawValue;
          if (code == null) return;

          _scanned = true;

          final exists = await widget.db.visitMaterialExistsBySerial(code);
          if (exists) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Вже відскановано')),
              );
              Navigator.pop(context);
            }
            return;
          }

          final clientUuid = const Uuid().v4();
          await widget.db.upsertVisitMaterial(VisitMaterialsCompanion.insert(
            clientUuid: clientUuid,
            visitUuid: widget.visitUuid,
            serialNo: code,
          ));

          await widget.db.createPendingOp(PendingOpsCompanion.insert(
            doctype: 'VisitMaterial',
            name: clientUuid,
            op: 'create',
            payload: '{"serial_no":"$code","visit_uuid":"${widget.visitUuid}"}',
            createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
          ));

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Додано: $code')),
            );
            Navigator.pop(context);
          }
        },
      ),
    );
  }
}
