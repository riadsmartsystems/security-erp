import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:path/path.dart' as p;
import 'package:riad_mobile/data/local/database.dart';
import 'package:riad_mobile/data/sync/media_upload_service.dart';

void main() {
  RiadDatabase createTestDb() {
    return RiadDatabase.forTesting(NativeDatabase.memory());
  }

  group('MediaUploadService.uploadPending', () {
    test('uploads file, updates drive_file_id, and triggers transcribe for voice', () async {
      final db = createTestDb();
      final tmpDir = await Directory.systemTemp.createTemp('upload_test');
      final testFile = File(p.join(tmpDir.path, 'test.m4a'));
      await testFile.writeAsBytes([1, 2, 3, 4, 5]);

      // Create MediaAsset first (required for updateMediaAssetDriveFileId)
      await db.upsertMediaAsset(MediaAssetsCompanion.insert(
        clientUuid: 'uuid-001',
        mediaType: const Value('voice'),
        aiAllowed: const Value(true),
      ));

      await db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
        clientUuid: 'uuid-001',
        localPath: testFile.path,
        mediaType: 'voice',
        createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      ));

      final requests = <http.BaseRequest>[];
      final mockClient = http_testing.MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v2/media/upload') {
          return http.Response(
            jsonEncode({'drive_file_id': 'drive-001', 'size_bytes': 5}),
            200,
          );
        }
        if (request.url.path == '/api/v2/media/uuid-001/transcribe') {
          return http.Response(jsonEncode({'status': 'queued'}), 200);
        }
        return http.Response('Not found', 404);
      });

      final service = MediaUploadService(
        db: db,
        baseUrl: 'http://localhost:8000',
        jwtToken: 'test-token',
        httpClient: mockClient,
      );

      await service.uploadPending();

      // Verify 2 requests: upload + transcribe
      expect(requests.length, 2);
      expect(requests[0].url.path, '/api/v2/media/upload');

      // Verify transcribe request for voice
      final transcribeReq = requests[1] as http.Request;
      expect(transcribeReq.url.path, '/api/v2/media/uuid-001/transcribe');
      expect(transcribeReq.headers['Authorization'], 'Bearer test-token');

      // Verify drive_file_id stored locally
      final assets = await (db.select(db.mediaAssets)
            ..where((t) => t.clientUuid.equals('uuid-001')))
          .get();
      expect(assets.length, 1);
      expect(assets.first.driveFileId, 'drive-001');

      // Verify upload status is done
      final uploads = await db.getPendingMediaUploadsByStatus('done');
      expect(uploads.length, 1);

      await db.close();
      await tmpDir.delete(recursive: true);
    });

    test('does NOT trigger transcription for photo uploads', () async {
      final db = createTestDb();
      final tmpDir = await Directory.systemTemp.createTemp('upload_test');
      final testFile = File(p.join(tmpDir.path, 'photo.jpg'));
      await testFile.writeAsBytes([1, 2, 3]);

      await db.upsertMediaAsset(MediaAssetsCompanion.insert(
        clientUuid: 'uuid-photo-001',
        mediaType: const Value('photo'),
        aiAllowed: const Value(false),
      ));

      await db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
        clientUuid: 'uuid-photo-001',
        localPath: testFile.path,
        mediaType: 'photo',
        createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      ));

      final requests = <http.BaseRequest>[];
      final mockClient = http_testing.MockClient((request) async {
        requests.add(request);
        if (request.url.path == '/api/v2/media/upload') {
          return http.Response(
            jsonEncode({'drive_file_id': 'drive-photo-001', 'size_bytes': 3}),
            200,
          );
        }
        return http.Response('Not found', 404);
      });

      final service = MediaUploadService(
        db: db,
        baseUrl: 'http://localhost:8000',
        jwtToken: 'test-token',
        httpClient: mockClient,
      );

      await service.uploadPending();

      // Only upload, NO transcribe
      expect(requests.length, 1);
      expect(requests[0].url.path, '/api/v2/media/upload');

      await db.close();
      await tmpDir.delete(recursive: true);
    });

    test('transcription failure does not block upload cycle', () async {
      final db = createTestDb();
      final tmpDir = await Directory.systemTemp.createTemp('upload_test');
      final testFile = File(p.join(tmpDir.path, 'test.m4a'));
      await testFile.writeAsBytes([1, 2, 3]);

      await db.upsertMediaAsset(MediaAssetsCompanion.insert(
        clientUuid: 'uuid-002',
        mediaType: const Value('voice'),
        aiAllowed: const Value(true),
      ));

      await db.createPendingMediaUpload(PendingMediaUploadsCompanion.insert(
        clientUuid: 'uuid-002',
        localPath: testFile.path,
        mediaType: 'voice',
        createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
      ));

      final mockClient = http_testing.MockClient((request) async {
        if (request.url.path == '/api/v2/media/upload') {
          return http.Response(
            jsonEncode({'drive_file_id': 'drive-002', 'size_bytes': 3}),
            200,
          );
        }
        if (request.url.path == '/api/v2/media/uuid-002/transcribe') {
          throw Exception('Network error');
        }
        return http.Response('Not found', 404);
      });

      final service = MediaUploadService(
        db: db,
        baseUrl: 'http://localhost:8000',
        jwtToken: 'test-token',
        httpClient: mockClient,
      );

      // Should NOT throw even though transcription fails
      await service.uploadPending();

      // Upload still completed
      final uploads = await db.getPendingMediaUploadsByStatus('done');
      expect(uploads.length, 1);

      // drive_file_id still stored
      final assets = await (db.select(db.mediaAssets)
            ..where((t) => t.clientUuid.equals('uuid-002')))
          .get();
      expect(assets.first.driveFileId, 'drive-002');

      await db.close();
      await tmpDir.delete(recursive: true);
    });
  });
}
