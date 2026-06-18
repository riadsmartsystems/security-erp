import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class SerialScanScreen extends StatefulWidget {
  final String deliveryNote;
  const SerialScanScreen({super.key, required this.deliveryNote});

  @override
  State<SerialScanScreen> createState() => _SerialScanScreenState();
}

class _SerialScanScreenState extends State<SerialScanScreen> {
  final List<String> _scannedSerials = [];
  bool _isUploading = false;

  Future<void> _uploadSerial(String serial) async {
    setState(() => _isUploading = true);
    try {
      final result = await api.post('/api/v2/warranty/scan', {
        'serial_number': serial,
        'delivery_note': widget.deliveryNote,
      });
      if (result['success']) {
        setState(() => _scannedSerials.add(serial));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Серійний номер $serial зареєстровано')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Помилка: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Сканування: ${widget.deliveryNote}')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: MobileScanner(
              onDetect: (capture) {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  final String code = barcodes.first.rawValue ?? '';
                  if (code.isNotEmpty && !_scannedSerials.contains(code)) {
                    _uploadSerial(code);
                  }
                }
              },
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  const Text('Відскановані серійні номери:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _scannedSerials.length,
                      itemBuilder: (context, index) => ListTile(
                        leading: const Icon(Icons.check_circle, color: Colors.green),
                        title: Text(_scannedSerials[index]),
                      ),
                    ),
                  ),
                  if (_isUploading) const LinearProgressIndicator(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
