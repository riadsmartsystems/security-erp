import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart';
import '../local/database.dart';

class SyncClient {
  final RiadDatabase _db;
  final String _baseUrl;
  final String _jwtToken;

  SyncClient({
    required RiadDatabase db,
    required String baseUrl,
    required String jwtToken,
  })  : _db = db,
        _baseUrl = baseUrl,
        _jwtToken = jwtToken;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_jwtToken',
      };

  Future<void> pullDelta() async {
    final watermark = await _db.getWatermark();
    final deviceId = await _db.getDeviceId();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v2/sync/pull'),
      headers: _headers,
      body: jsonEncode({
        'device_id': deviceId,
        'watermark': watermark,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Pull failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['ok'] != true) {
      throw Exception('Pull error: ${data['error']}');
    }

    final changes = data['data']['changes'] as List;
    for (final change in changes) {
      await _applyChange(change);
    }

    final nextWatermark = data['data']['next_watermark'] as String;
    await _db.updateWatermark(nextWatermark);
  }

  Future<void> _applyChange(Map<String, dynamic> change) async {
    final doctype = change['doctype'] as String;
    final name = change['name'] as String;
    final riadDeleted = change['riad_deleted'] == 1;

    if (riadDeleted) {
      await _softDelete(doctype, name);
      return;
    }

    final fields = change['fields'] as Map<String, dynamic>?;
    final additive = change['additive'] as Map<String, dynamic>?;

    switch (doctype) {
      case 'Visit':
        await _upsertVisit(name, fields, additive);
        break;
      case 'Checklist Instance':
        await _upsertChecklistInstance(name, fields, additive);
        break;
      case 'Installation Map':
        await _upsertInstallationMap(name, fields, additive);
        break;
      case 'Media Asset':
        await _upsertMediaAsset(name, fields);
        break;
    }
  }

  Future<void> _softDelete(String doctype, String name) async {
    switch (doctype) {
      case 'Visit':
        await _db.softDeleteVisit(name);
        break;
      case 'Checklist Instance':
        await _db.softDeleteChecklistInstance(name);
        break;
      case 'Installation Map':
        await _db.softDeleteInstallationMap(name);
        break;
      case 'Media Asset':
        await _db.softDeleteMediaAsset(name);
        break;
    }
  }

  Future<void> _upsertVisit(
    String name,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? additive,
  ) async {
    final visit = VisitsCompanion.insert(
      clientUuid: name,
      riadVersion: Value(fields?['riad_version'] ?? 0),
      riadDeleted: Value(fields?['riad_deleted'] == 1),
      riadDeletedAt: Value(fields?['riad_deleted_at'] != null
          ? DateTime.parse(fields!['riad_deleted_at'])
          : null),
      visitType: Value(fields?['visit_type']),
      summary: Value(fields?['summary']),
      serviceTicket: Value(fields?['service_ticket']),
      visitDate: Value(fields?['visit_date'] != null
          ? DateTime.parse(fields!['visit_date'])
          : null),
      status: Value(fields?['status']),
    );
    await _db.upsertVisit(visit);

    if (additive != null) {
      await _mergeAdditiveVisit(name, additive);
    }
  }

  Future<void> _mergeAdditiveVisit(
    String visitUuid,
    Map<String, dynamic> additive,
  ) async {
    final materials = additive['visit_material'] as List? ?? [];
    for (final material in materials) {
      final uuid = material['client_uuid'] as String;
      final existing = await (_db.select(_db.visitMaterials)
            ..where((t) => t.clientUuid.equals(uuid)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.upsertVisitMaterial(
          VisitMaterialsCompanion.insert(
            clientUuid: uuid,
            visitUuid: visitUuid,
            riadVersion: Value(material['riad_version'] ?? 0),
            itemName: Value(material['item_name']),
            serialNo: Value(material['serial_no']),
            qty: Value(material['qty'] ?? 1),
          ),
        );
      }
    }

    final photos = additive['visit_photo'] as List? ?? [];
    for (final photo in photos) {
      final uuid = photo['client_uuid'] as String;
      final existing = await (_db.select(_db.visitPhotos)
            ..where((t) => t.clientUuid.equals(uuid)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.upsertVisitPhoto(
          VisitPhotosCompanion.insert(
            clientUuid: uuid,
            visitUuid: visitUuid,
            riadVersion: Value(photo['riad_version'] ?? 0),
            driveFileId: Value(photo['drive_file_id']),
            description: Value(photo['description']),
          ),
        );
      }
    }
  }

  Future<void> _upsertChecklistInstance(
    String name,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? additive,
  ) async {
    final instance = ChecklistInstancesCompanion.insert(
      clientUuid: name,
      riadVersion: Value(fields?['riad_version'] ?? 0),
      riadDeleted: Value(fields?['riad_deleted'] == 1),
      riadDeletedAt: Value(fields?['riad_deleted_at'] != null
          ? DateTime.parse(fields!['riad_deleted_at'])
          : null),
      template: Value(fields?['template']),
      passport: Value(fields?['passport']),
      visit: Value(fields?['visit']),
      status: Value(fields?['status']),
    );
    await _db.upsertChecklistInstance(instance);

    if (additive != null) {
      await _mergeAdditiveChecklist(name, additive);
    }
  }

  Future<void> _mergeAdditiveChecklist(
    String instanceUuid,
    Map<String, dynamic> additive,
  ) async {
    final items = additive['checklist_instance_item'] as List? ?? [];
    for (final item in items) {
      final uuid = item['item_uuid'] as String;
      final existing = await (_db.select(_db.checklistInstanceItems)
            ..where((t) => t.itemUuid.equals(uuid)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.upsertChecklistInstanceItem(
          ChecklistInstanceItemsCompanion.insert(
            itemUuid: uuid,
            instanceUuid: instanceUuid,
            riadVersion: Value(item['riad_version'] ?? 0),
            checkedBy: Value(item['checked_by']),
            photo: Value(item['photo']),
            value: Value(item['value']),
            serialNo: Value(item['serial_no']),
          ),
        );
      }
    }
  }

  Future<void> _upsertInstallationMap(
    String name,
    Map<String, dynamic>? fields,
    Map<String, dynamic>? additive,
  ) async {
    final map = InstallationMapsCompanion.insert(
      clientUuid: name,
      riadVersion: Value(fields?['riad_version'] ?? 0),
      riadDeleted: Value(fields?['riad_deleted'] == 1),
      riadDeletedAt: Value(fields?['riad_deleted_at'] != null
          ? DateTime.parse(fields!['riad_deleted_at'])
          : null),
      passport: Value(fields?['passport']),
      name_: Value(fields?['name']),
    );
    await _db.upsertInstallationMap(map);

    if (additive != null) {
      await _mergeAdditiveInstallationMap(name, additive);
    }
  }

  Future<void> _mergeAdditiveInstallationMap(
    String mapUuid,
    Map<String, dynamic> additive,
  ) async {
    final points = additive['mount_point'] as List? ?? [];
    for (final point in points) {
      final uuid = point['point_uuid'] as String;
      final existing = await (_db.select(_db.mountPoints)
            ..where((t) => t.pointUuid.equals(uuid)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.upsertMountPoint(
          MountPointsCompanion.insert(
            pointUuid: uuid,
            mapUuid: mapUuid,
            riadVersion: Value(point['riad_version'] ?? 0),
            type: Value(point['type']),
            label: Value(point['label']),
            x: Value(point['x']?.toDouble()),
            y: Value(point['y']?.toDouble()),
            status: Value(point['status']),
            item: Value(point['item']),
            serialNo: Value(point['serial_no']),
            photo: Value(point['photo']),
          ),
        );
      }
    }

    final routes = additive['cable_route'] as List? ?? [];
    for (final route in routes) {
      final uuid = route['route_uuid'] as String;
      final existing = await (_db.select(_db.cableRoutes)
            ..where((t) => t.routeUuid.equals(uuid)))
          .getSingleOrNull();
      if (existing == null) {
        await _db.upsertCableRoute(
          CableRoutesCompanion.insert(
            routeUuid: uuid,
            mapUuid: mapUuid,
            riadVersion: Value(route['riad_version'] ?? 0),
            fromPoint: Value(route['from_point']),
            toPoint: Value(route['to_point']),
            pathJson: Value(route['path_json']),
          ),
        );
      }
    }
  }

  Future<void> _upsertMediaAsset(
    String name,
    Map<String, dynamic>? fields,
  ) async {
    final asset = MediaAssetsCompanion.insert(
      clientUuid: name,
      riadVersion: Value(fields?['riad_version'] ?? 0),
      riadDeleted: Value(fields?['riad_deleted'] == 1),
      riadDeletedAt: Value(fields?['riad_deleted_at'] != null
          ? DateTime.parse(fields!['riad_deleted_at'])
          : null),
      driveFileId: Value(fields?['drive_file_id']),
      aiAllowed: Value(fields?['ai_allowed'] == 1),
      transcriptionStatus: Value(fields?['transcription_status']),
    );
    await _db.upsertMediaAsset(asset);
  }

  Future<void> pushPending() async {
    final pendingOps = await _db.getPendingOps();

    if (pendingOps.isEmpty) return;

    for (final op in pendingOps) {
      await _db.updatePendingOpStatus(op.id, 'inflight');
    }

    final batch = pendingOps.map((op) {
      final payload = jsonDecode(op.payload) as Map<String, dynamic>;
      return {
        'doctype': op.doctype,
        'name': op.name,
        'op': op.op,
        'client_base_version': op.baseVersion,
        'scalars': payload['scalars'],
        'additive': payload['additive'],
      };
    }).toList();

    final response = await http.post(
      Uri.parse('$_baseUrl/api/v2/sync/push'),
      headers: _headers,
      body: jsonEncode({
        'device_id': await _db.getDeviceId(),
        'batch': batch,
      }),
    );

    if (response.statusCode != 200) {
      for (final op in pendingOps) {
        await _db.updatePendingOpStatus(op.id, 'failed');
      }
      throw Exception('Push failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data['ok'] != true) {
      for (final op in pendingOps) {
        await _db.updatePendingOpStatus(op.id, 'failed');
      }
      throw Exception('Push error: ${data['error']}');
    }

    final results = data['data']['results'] as List;
    for (final result in results) {
      final name = result['name'] as String;
      final status = result['status'] as String;
      final serverVersion = result['server_version'] as int;

      final op = pendingOps.firstWhere((o) => o.name == name);

      switch (status) {
        case 'applied':
        case 'merged':
        case 'ignored_duplicate':
          await _db.deletePendingOp(op.id);
          await _updateLocalVersion(op.doctype, name, serverVersion);
          break;
        case 'tombstoned':
          await _softDelete(op.doctype, name);
          await _db.deletePendingOp(op.id);
          break;
        case 'conflict':
          await handleConflict(name, result['conflicts'] as List);
          await _db.updatePendingOpStatus(op.id, 'failed');
          break;
      }
    }
  }

  Future<void> _updateLocalVersion(
    String doctype,
    String name,
    int version,
  ) async {
    switch (doctype) {
      case 'Visit':
        await (_db.update(_db.visits)..where((t) => t.clientUuid.equals(name)))
            .write(VisitsCompanion(riadVersion: Value(version)));
        break;
      case 'Checklist Instance':
        await (_db.update(_db.checklistInstances)
              ..where((t) => t.clientUuid.equals(name)))
            .write(ChecklistInstancesCompanion(riadVersion: Value(version)));
        break;
      case 'Installation Map':
        await (_db.update(_db.installationMaps)
              ..where((t) => t.clientUuid.equals(name)))
            .write(InstallationMapsCompanion(riadVersion: Value(version)));
        break;
      case 'Media Asset':
        await (_db.update(_db.mediaAssets)
              ..where((t) => t.clientUuid.equals(name)))
            .write(MediaAssetsCompanion(riadVersion: Value(version)));
        break;
    }
  }

  Future<void> handleConflict(
    String docname,
    List conflicts,
  ) async {
    for (final conflict in conflicts) {
      await _db.insertConflict(
        SyncConflictsCompanion.insert(
          conflictId: conflict['conflict_id'] as String,
          doctype: conflict['doctype'] ?? '',
          docname: docname,
          fieldName: conflict['field'] as String,
          serverValue: Value(conflict['server_value']),
          clientValue: Value(conflict['client_value']),
        ),
      );
    }
  }

  Future<void> createTombstone(String doctype, String name, int baseVersion) async {
    final now = DateTime.now().toUtc();

    switch (doctype) {
      case 'Visit':
        await _db.softDeleteVisit(name);
        break;
      case 'Checklist Instance':
        await _db.softDeleteChecklistInstance(name);
        break;
      case 'Installation Map':
        await _db.softDeleteInstallationMap(name);
        break;
      case 'Media Asset':
        await _db.softDeleteMediaAsset(name);
        break;
    }

    await _db.createPendingOp(
      PendingOpsCompanion.insert(
        doctype: doctype,
        name: name,
        op: 'delete',
        payload: '{}',
        baseVersion: Value(baseVersion),
        status: const Value('pending'),
        createdAt: now.millisecondsSinceEpoch,
      ),
    );
  }

  Stream<int> watchPendingCount() => _db.watchPendingCount();
}
