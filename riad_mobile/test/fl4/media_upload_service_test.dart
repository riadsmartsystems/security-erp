import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riad_mobile/core/api/dio_client.dart';
import 'package:riad_mobile/core/connectivity/connectivity_service.dart';
import 'package:riad_mobile/core/db/database.dart';
import 'package:riad_mobile/core/sync/media_upload_service.dart';
import 'package:sqlite3/open.dart';

class MockDio extends Mock implements Dio {}

AppDatabase _testDb() => AppDatabase.forTesting(NativeDatabase.memory());

Response<dynamic> _okResp(String path, Map<String, dynamic> data) =>
    Response(requestOptions: RequestOptions(path: path), statusCode: 200, data: data);

void main() {
  late MockDio mockDio;
  late AppDatabase db;

  setUpAll(() {
    if (Platform.isLinux) {
      // System has libsqlite3.so.0 (versioned), not unversioned libsqlite3.so
      open.overrideFor(OperatingSystem.linux,
          () => DynamicLibrary.open('libsqlite3.so.0'));
    }
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());
  });

  setUp(() {
    mockDio = MockDio();
    db = _testDb();
  });
  tearDown(() => db.close());

  ProviderContainer _container({bool online = true}) {
    return ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      dioProvider.overrideWithValue(mockDio),
      connectivityProvider.overrideWith((_) => Stream.value(online)),
    ]);
  }

  group('saveAndQueue', () {
    test('inserts media_assets row with aiAllowed=false', () async {
      final c = _container();
      addTearDown(c.dispose);
      final svc = c.read(mediaUploadProvider);

      await svc.saveAndQueue(
        mediaId: 'uuid-1',
        localPath: '/data/media/uuid-1.jpg',
        parentDoctype: 'Engineer Visit',
        parentName: 'EV-001',
        tag: 'before',
        mediaType: 'photo',
      );

      final assets = await db.select(db.mediaAssets).get();
      expect(assets, hasLength(1));
      expect(assets.first.aiAllowed, false);  // CRITICAL: always false
      expect(assets.first.tag, 'before');
      expect(assets.first.parentDoctype, 'Engineer Visit');
      expect(assets.first.driveId, isNull);
    });

    test('inserts pending_media_uploads row with status=pending', () async {
      final c = _container();
      addTearDown(c.dispose);
      final svc = c.read(mediaUploadProvider);

      await svc.saveAndQueue(
        mediaId: 'uuid-2',
        localPath: '/data/media/uuid-2.aac',
        parentDoctype: 'Engineer Visit',
        parentName: 'EV-002',
        tag: 'audio',
        mediaType: 'audio',
      );

      final pending = await db.select(db.pendingMediaUploads).get();
      expect(pending, hasLength(1));
      expect(pending.first.status, 'pending');
      expect(pending.first.mediaType, 'audio');
    });
  });

  group('uploadPending', () {
    test('uploads pending file and updates driveId', () async {
      final c = _container(online: true);
      addTearDown(c.dispose);
      final svc = c.read(mediaUploadProvider);

      // Pre-seed DB without auto-trigger
      await db.into(db.mediaAssets).insert(MediaAssetsCompanion.insert(
        id: 'uuid-3',
        clientUuid: 'uuid-3',
        parentDoctype: 'Engineer Visit',
        parentName: 'EV-003',
        mediaType: 'photo',
        tag: const Value('before'),
        localPath: const Value('/tmp/test.jpg'),
      ));
      await db.into(db.pendingMediaUploads).insert(PendingMediaUploadsCompanion.insert(
        clientUuid: 'uuid-3',
        localPath: '/tmp/test.jpg',
        mediaType: 'photo',
        parentDoctype: 'Engineer Visit',
        parentName: 'EV-003',
      ));

      when(() => mockDio.post('/media/upload', data: any(named: 'data')))
          .thenAnswer((_) async => _okResp('/media/upload', {
                'id': 'server-id-3',
                'drive_id': 'drive-abc',
                'filename': 'uuid-3.jpg',
              }));

      await svc.uploadPending();

      final asset = await (db.select(db.mediaAssets)
            ..where((t) => t.clientUuid.equals('uuid-3')))
          .getSingle();
      expect(asset.driveId, 'drive-abc');

      final pending = await (db.select(db.pendingMediaUploads)
            ..where((t) => t.clientUuid.equals('uuid-3')))
          .getSingle();
      expect(pending.status, 'done');
    });

    test('increments attempts on upload failure', () async {
      final c = _container(online: true);
      addTearDown(c.dispose);
      final svc = c.read(mediaUploadProvider);

      await db.into(db.mediaAssets).insert(MediaAssetsCompanion.insert(
        id: 'uuid-4',
        clientUuid: 'uuid-4',
        parentDoctype: 'Engineer Visit',
        parentName: 'EV-004',
        mediaType: 'photo',
        tag: const Value('after'),
        localPath: const Value('/tmp/missing.jpg'),
      ));
      await db.into(db.pendingMediaUploads).insert(PendingMediaUploadsCompanion.insert(
        clientUuid: 'uuid-4',
        localPath: '/tmp/missing.jpg',
        mediaType: 'photo',
        parentDoctype: 'Engineer Visit',
        parentName: 'EV-004',
      ));

      when(() => mockDio.post('/media/upload', data: any(named: 'data')))
          .thenThrow(DioException(
            requestOptions: RequestOptions(path: '/media/upload'),
            message: 'network error',
          ));

      await svc.uploadPending();

      final pending = await (db.select(db.pendingMediaUploads)
            ..where((t) => t.clientUuid.equals('uuid-4')))
          .getSingle();
      expect(pending.attempts, 1);
      expect(pending.status, 'pending');  // stays pending for retry
    });
  });
}
