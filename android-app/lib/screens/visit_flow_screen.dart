import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import 'photo_upload_screen.dart';
import 'materials_screen.dart';

class VisitFlowScreen extends StatefulWidget {
  final Map<String, dynamic> ticket;
  const VisitFlowScreen({super.key, required this.ticket});

  @override
  State<VisitFlowScreen> createState() => _VisitFlowScreenState();
}

class _VisitFlowScreenState extends State<VisitFlowScreen> {
  List<dynamic> _visits = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadVisits();
  }

  Future<Position?> _getPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    } catch (e) {
      return null;
    }
  }

  Future<void> _loadVisits() async {
    try {
      final result = await api.get('/api/v2/visits?limit=20');
      setState(() {
        _visits = result['data'] ?? [];
        _loading = false;
      });
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _startVisit(String visitId) async {
    final pos = await _getPosition();
    await api.post('/api/v2/visits/$visitId/start', {
      'lat': pos?.latitude ?? 0.0,
      'lon': pos?.longitude ?? 0.0,
    });
    _loadVisits();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pos != null
            ? 'GPS чекін: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
            : 'GPS недоступний. Чекін без координат.')),
      );
    }
  }

  Future<void> _finishVisit(String visitId) async {
    final pos = await _getPosition();
    await api.post('/api/v2/visits/$visitId/finish', {
      'lat': pos?.latitude ?? 0.0,
      'lon': pos?.longitude ?? 0.0,
    });
    _loadVisits();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pos != null
            ? 'GPS чекаут: ${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}'
            : 'GPS недоступний. Чекаут без координат.')),
      );
    }
  }

  Future<void> _createVisit() async {
    await api.post('/api/v2/visits', {
      'ticket_id': widget.ticket['id'],
      'engineer_id': 'joker@riad.fun',
    });
    _loadVisits();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.ticket;
    return Scaffold(
      appBar: AppBar(title: Text('Виїзд: ${t['ticket_number'] ?? ''}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t['title'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Пріоритет: ${t['priority'] ?? ''} | Статус: ${t['status'] ?? ''}'),
            ]),
          )),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _createVisit,
            icon: const Icon(Icons.add),
            label: const Text('Створити виїзд'),
          ),
          const SizedBox(height: 16),
          Text('Виїзди (${_visits.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ..._visits.map((v) => Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${v['visit_number'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(v['status'] ?? '', style: TextStyle(
                    color: v['status'] == 'completed' ? Colors.green :
                           v['status'] == 'working' ? Colors.orange : Colors.blue,
                  )),
                ]),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                  if (v['status'] == 'planned' || v['status'] == 'accepted')
                    ElevatedButton.icon(
                      onPressed: () => _startVisit(v['id']),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Старт'),
                    ),
                  if (v['status'] == 'on_route' || v['status'] == 'arrived' || v['status'] == 'working')
                    ElevatedButton.icon(
                      onPressed: () => _finishVisit(v['id']),
                      icon: const Icon(Icons.stop),
                      label: const Text('Завершити'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  if (v['status'] != 'completed')
                    IconButton(
                      icon: const Icon(Icons.camera_alt),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => PhotoUploadScreen(visitId: v['id']),
                        ));
                      },
                    ),
                  if (v['status'] != 'completed')
                    IconButton(
                      icon: const Icon(Icons.inventory_2),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => MaterialsScreen(visitId: v['id']),
                        ));
                      },
                    ),
                ]),
              ]),
            ),
          )),
        ],
      ),
    );
  }
}
