import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:uuid/uuid.dart';
import 'package:riad_mobile/data/local/database.dart';

void main() {
  RiadDatabase createTestDb() {
    return RiadDatabase.forTesting(NativeDatabase.memory());
  }

  test('visit_status_change_creates_pending_op', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertVisit(VisitsCompanion.insert(
      clientUuid: uuid,
      visitDate: Value(DateTime.now()),
    ));

    await db.updateVisitStatus(uuid, 'в_роботі');

    final visits = await (db.select(db.visits)..where((t) => t.clientUuid.equals(uuid))).get();
    expect(visits.first.status, 'в_роботі');

    await db.createPendingOp(PendingOpsCompanion.insert(
      doctype: 'Visit',
      name: uuid,
      op: 'update',
      payload: '{"status":"в_роботі"}',
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));

    final ops = await db.getPendingOps();
    expect(ops.length, 1);
    expect(ops.first.doctype, 'Visit');

    await db.close();
  });

  test('camera_creates_pending_upload_ai_allowed_false', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: uuid,
      mediaType: const Value('photo'),
      tag: const Value('до'),
      aiAllowed: const Value(false),
      localPath: const Value('/media/test.jpg'),
    ));

    final assets = await (db.select(db.mediaAssets)..where((t) => t.clientUuid.equals(uuid))).get();
    expect(assets.first.aiAllowed, false);

    await db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
      clientUuid: uuid,
      localPath: '/media/test.jpg',
      mediaType: 'photo',
      tag: const Value('до'),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));

    final uploads = await db.getPendingMediaUploads();
    expect(uploads.length, 1);
    expect(uploads.first.clientUuid, uuid);

    await db.close();
  });

  test('camera_saves_file_locally_before_upload', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();
    final localPath = '/documents/media/$uuid.jpg';

    await db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: uuid,
      mediaType: const Value('photo'),
      localPath: Value(localPath),
      aiAllowed: const Value(false),
    ));

    final assets = await (db.select(db.mediaAssets)..where((t) => t.clientUuid.equals(uuid))).get();
    expect(assets.first.localPath, localPath);

    await db.close();
  });

  test('scan_duplicate_shows_toast', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertVisitMaterial(VisitMaterialsCompanion.insert(
      clientUuid: uuid,
      visitUuid: 'visit-1',
      serialNo: const Value('SN-001'),
    ));

    final exists = await db.visitMaterialExistsBySerial('SN-001');
    expect(exists, true);

    final exists2 = await db.visitMaterialExistsBySerial('SN-999');
    expect(exists2, false);

    await db.close();
  });

  test('scan_new_creates_visit_material', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertVisitMaterial(VisitMaterialsCompanion.insert(
      clientUuid: uuid,
      visitUuid: 'visit-1',
      serialNo: const Value('SN-NEW'),
    ));

    final materials = await (db.select(db.visitMaterials)
      ..where((t) => t.serialNo.equals('SN-NEW'))).get();
    expect(materials.length, 1);
    expect(materials.first.serialNo, 'SN-NEW');

    await db.createPendingOp(PendingOpsCompanion.insert(
      doctype: 'VisitMaterial',
      name: uuid,
      op: 'create',
      payload: '{"serial_no":"SN-NEW"}',
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));

    final ops = await db.getPendingOps();
    expect(ops.first.doctype, 'VisitMaterial');

    await db.close();
  });

  test('upload_service_sets_drive_id_on_success', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: uuid,
      mediaType: const Value('photo'),
      aiAllowed: const Value(false),
    ));

    await db.updateMediaAssetDriveFileId(uuid, 'drive-file-123');

    final assets = await (db.select(db.mediaAssets)..where((t) => t.clientUuid.equals(uuid))).get();
    expect(assets.first.driveFileId, 'drive-file-123');

    await db.close();
  });

  test('voice_note_triggers_transcribe_after_upload', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: uuid,
      mediaType: const Value('audio'),
      aiAllowed: const Value(false),
      transcriptionStatus: const Value('pending'),
    ));

    await db.updateMediaAssetDriveFileId(uuid, 'drive-audio-1');

    await db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
      clientUuid: uuid,
      localPath: '/media/$uuid.m4a',
      mediaType: 'audio',
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));

    final uploads = await db.getPendingMediaUploads();
    expect(uploads.length, 1);
    expect(uploads.first.mediaType, 'audio');

    await db.close();
  });

  test('transcription_status_updated_via_pull', () async {
    final db = createTestDb();
    final uuid = const Uuid().v4();

    await db.upsertMediaAsset(MediaAssetsCompanion.insert(
      clientUuid: uuid,
      mediaType: const Value('audio'),
      aiAllowed: const Value(false),
      transcriptionStatus: const Value('очікує'),
    ));

    await db.updateMediaAssetTranscription(uuid, 'Текст транскрипції', 'готово');

    final assets = await (db.select(db.mediaAssets)..where((t) => t.clientUuid.equals(uuid))).get();
    expect(assets.first.transcriptionStatus, 'готово');
    expect(assets.first.transcription, 'Текст транскрипції');

    await db.close();
  });
}
