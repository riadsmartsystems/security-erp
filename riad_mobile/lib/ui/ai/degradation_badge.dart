import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DegradationBadge extends StatefulWidget {
  final String baseUrl;
  final String jwtToken;
  final Duration refreshInterval;
  final http.Client? client;

  const DegradationBadge({
    super.key,
    required this.baseUrl,
    required this.jwtToken,
    this.refreshInterval = const Duration(minutes: 5),
    this.client,
  });

  @override
  State<DegradationBadge> createState() => _DegradationBadgeState();
}

class _DegradationBadgeState extends State<DegradationBadge> {
  String _level = 'primary';
  String _message = '';
  bool _loading = true;
  Timer? _timer;
  late final http.Client _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client ?? http.Client();
    _fetchDegradation();
    _timer = Timer.periodic(widget.refreshInterval, (_) => _fetchDegradation());
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (widget.client == null) _client.close();
    super.dispose();
  }

  Future<void> _fetchDegradation() async {
    try {
      final response = await _client.get(
        Uri.parse('${widget.baseUrl}/api/v2/ai/degradation'),
        headers: {'Authorization': 'Bearer ${widget.jwtToken}'},
      );
      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _level = data['level'] ?? 'primary';
          _message = data['message'] ?? '';
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _level = 'manual';
          _message = 'Неможливо перевірити стан AI';
          _loading = false;
        });
      }
    }
  }

  @visibleForTesting
  String get level => _level;

  @visibleForTesting
  String get message => _message;

  @visibleForTesting
  bool get loading => _loading;

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();

    final color = switch (_level) {
      'primary' => Colors.green,
      'fallback' => Colors.orange,
      'manual' => Colors.red,
      _ => Colors.grey,
    };

    final icon = switch (_level) {
      'primary' => Icons.check_circle,
      'fallback' => Icons.warning,
      'manual' => Icons.error,
      _ => Icons.help,
    };

    return Tooltip(
      message: _message,
      child: Icon(icon, color: color, size: 20),
    );
  }
}
