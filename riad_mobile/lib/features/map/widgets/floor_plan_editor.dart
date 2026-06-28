import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/sync/sync_queue_service.dart';

class FloorPlanEditor extends ConsumerStatefulWidget {
  final String objectId;
  final String? basePlanUrl;
  final List points;
  final bool canEdit;

  const FloorPlanEditor({
    super.key,
    required this.objectId,
    required this.basePlanUrl,
    required this.points,
    required this.canEdit,
  });

  @override
  ConsumerState<FloorPlanEditor> createState() => _FloorPlanEditorState();
}

class _FloorPlanEditorState extends ConsumerState<FloorPlanEditor> {
  late List<_Point> _points;

  @override
  void initState() {
    super.initState();
    _points = widget.points
        .map((p) => _Point.fromMap(p as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (ctx, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return GestureDetector(
            onTapUp: widget.canEdit
                ? (details) => _addPoint(details.localPosition, w, h)
                : null,
            child: Stack(
              children: [
                if (widget.basePlanUrl != null)
                  Image.network(
                    widget.basePlanUrl!,
                    fit: BoxFit.contain,
                    width: w,
                    height: h,
                  )
                else
                  Container(
                    color: Colors.white10,
                    width: w,
                    height: h,
                    child: const Center(
                      child: Text('Немає плану приміщення'),
                    ),
                  ),
                ..._points.map((p) => Positioned(
                      left: p.x * w - 12,
                      top: p.y * h - 12,
                      child: GestureDetector(
                        onLongPress:
                            widget.canEdit ? () => _showPointMenu(p) : null,
                        child: _PointMarker(point: p),
                      ),
                    )),
                if (widget.canEdit)
                  const Positioned(
                    bottom: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        'Тап — додати точку · Утримати — редагувати',
                        style: TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      );

  Future<void> _addPoint(Offset pos, double w, double h) async {
    final x = (pos.dx / w).clamp(0.0, 1.0);
    final y = (pos.dy / h).clamp(0.0, 1.0);
    final id = const Uuid().v4();

    final newPoint = _Point(
      id: id,
      x: x,
      y: y,
      label: 'Точка ${_points.length + 1}',
      status: 'planned',
    );
    setState(() => _points.add(newPoint));

    await ref.read(syncQueueProvider).enqueue(
          docType: 'Installation Point',
          name: id,
          operation: 'create',
          payload: {
            'name': id,
            'object_id': widget.objectId,
            'x': x,
            'y': y,
            'label': newPoint.label,
            'status': 'planned',
          },
        );
  }

  void _showPointMenu(_Point point) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Видалити точку'),
            onTap: () {
              Navigator.pop(context);
              _deletePoint(point);
            },
          ),
        ],
      ),
    );
  }

  Future<void> _deletePoint(_Point point) async {
    setState(() => _points.removeWhere((p) => p.id == point.id));
    await ref.read(syncQueueProvider).enqueue(
          docType: 'Installation Point',
          name: point.id,
          operation: 'delete',
          payload: {'name': point.id},
        );
  }
}

class _Point {
  final String id;
  final double x, y;
  final String label;
  final String status;

  _Point({
    required this.id,
    required this.x,
    required this.y,
    required this.label,
    required this.status,
  });

  factory _Point.fromMap(Map<String, dynamic> m) => _Point(
        id: m['id'] as String,
        x: (m['x'] as num).toDouble(),
        y: (m['y'] as num).toDouble(),
        label: m['label'] as String? ?? '',
        status: m['status'] as String? ?? 'planned',
      );
}

class _PointMarker extends StatelessWidget {
  final _Point point;
  const _PointMarker({required this.point});

  @override
  Widget build(BuildContext context) => Tooltip(
        message: point.label,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _statusColor(point.status),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.sensors, size: 12, color: Colors.white),
        ),
      );

  Color _statusColor(String s) => switch (s) {
        'planned' => Colors.blue,
        'installed' => Colors.green,
        'issue' => Colors.red,
        _ => Colors.grey,
      };
}
