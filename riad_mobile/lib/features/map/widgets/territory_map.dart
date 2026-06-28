import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_queue_service.dart';

class TerritoryMap extends ConsumerStatefulWidget {
  final String objectId;
  final List points;
  final bool canEdit;

  const TerritoryMap({
    super.key,
    required this.objectId,
    required this.points,
    required this.canEdit,
  });

  @override
  ConsumerState<TerritoryMap> createState() => _TerritoryMapState();
}

class _TerritoryMapState extends ConsumerState<TerritoryMap> {
  late List<_GeoPoint> _points;
  final _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _points = widget.points
        .where((p) => (p as Map)['lat'] != null)
        .map((p) => _GeoPoint.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) => FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _points.isNotEmpty
              ? LatLng(_points.first.lat, _points.first.lng)
              : const LatLng(48.9225, 33.4519),
          initialZoom: 16,
          onTap: widget.canEdit
              ? (_, latLng) => _addPoint(latLng)
              : null,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'fun.riad.mobile',
          ),
          MarkerLayer(
            markers: _points
                .map((p) => Marker(
                      point: LatLng(p.lat, p.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onLongPress: widget.canEdit ? () => _deletePoint(p) : null,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.blue,
                          ),
                          child: const Icon(
                            Icons.sensors,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      );

  Future<void> _addPoint(LatLng latLng) async {
    final id = const Uuid().v4();
    setState(() => _points.add(
          _GeoPoint(id: id, lat: latLng.latitude, lng: latLng.longitude),
        ));
    await ref.read(syncQueueProvider).enqueue(
          docType: 'Installation Point',
          name: id,
          operation: 'create',
          payload: {
            'name': id,
            'object_id': widget.objectId,
            'lat': latLng.latitude,
            'lng': latLng.longitude,
            'label': 'GPS точка',
            'status': 'planned',
          },
        );
  }

  Future<void> _deletePoint(_GeoPoint p) async {
    setState(() => _points.removeWhere((pt) => pt.id == p.id));
    await ref.read(syncQueueProvider).enqueue(
          docType: 'Installation Point',
          name: p.id,
          operation: 'delete',
          payload: {'name': p.id},
        );
  }
}

class _GeoPoint {
  final String id;
  final double lat, lng;

  _GeoPoint({required this.id, required this.lat, required this.lng});

  factory _GeoPoint.fromMap(Map<String, dynamic> m) => _GeoPoint(
        id: m['id'] as String,
        lat: (m['lat'] as num).toDouble(),
        lng: (m['lng'] as num).toDouble(),
      );
}
