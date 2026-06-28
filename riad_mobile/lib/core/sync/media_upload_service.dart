import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/dio_client.dart';
import '../connectivity/connectivity_service.dart';
import '../db/database.dart';

class MediaUploadService {
  final AppDatabase _db;
  final Dio _dio;
  final Ref _ref;

  MediaUploadService(this._db, this._dio, this._ref);

  Future<void> saveAndQueue({
    required String mediaId,
    required String localPath,
    required String parentDoctype,
    required String parentName,
    required String tag,
    required String mediaType,
  }) async {
    await _db.into(_db.mediaAssets).insertOnConflictUpdate(
      MediaAssetsCompanion.insert(
        id: mediaId,
        clientUuid: mediaId,
        parentDoctype: parentDoctype,
        parentName: parentName,
        mediaType: mediaType,
        tag: Value(tag),
        aiAllowed: const Value(false), // HARDCODED — Constitution §6
        localPath: Value(localPath),
      ),
    );

    await _db.into(_db.pendingMediaUploads).insert(
      PendingMediaUploadsCompanion.insert(
        clientUuid: mediaId,
        localPath: localPath,
        mediaType: mediaType,
        parentDoctype: parentDoctype,
        parentName: parentName,
        tag: Value(tag),
      ),
    );

    // Trigger upload immediately if online
    final isOnline = _ref.read(connectivityProvider).value ?? false;
    if (isOnline) await uploadPending();
  }

  Future<void> uploadPending() async {
    final pending = await (
      _db.select(_db.pendingMediaUploads)
        ..where((t) => t.status.equals('pending'))
        ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
    ).get();

    for (final item in pending) {
      try {
        final asset = await (_db.select(_db.mediaAssets)
              ..where((t) => t.clientUuid.equals(item.clientUuid)))
            .getSingleOrNull();
        if (asset == null) continue;

        final formData = FormData.fromMap({
          'file': MultipartFile.fromString(
            item.localPath,
            filename: '${item.clientUuid}.${_ext(item.mediaType)}',
          ),
          'doc_type':   asset.parentDoctype,
          'doc_name':   asset.parentName,
          'tag':        asset.tag,
          'ai_allowed': 'false', // HARDCODED — Constitution §6
        });

        final resp = await _dio.post('/media/upload', data: formData);
        final data = resp.data as Map<String, dynamic>;
        final driveId = data['drive_id'] as String;

        await (_db.update(_db.mediaAssets)
              ..where((t) => t.clientUuid.equals(item.clientUuid)))
            .write(MediaAssetsCompanion(driveId: Value(driveId)));

        await (_db.update(_db.pendingMediaUploads)
              ..where((t) => t.id.equals(item.id)))
            .write(const PendingMediaUploadsCompanion(status: Value('done')));
      } catch (_) {
        await (_db.update(_db.pendingMediaUploads)
              ..where((t) => t.id.equals(item.id)))
            .write(PendingMediaUploadsCompanion(
              attempts: Value(item.attempts + 1),
            ));
      }
    }
  }

  static String _ext(String mediaType) =>
      mediaType == 'audio' ? 'aac' : 'jpg';
}

final mediaUploadProvider = Provider<MediaUploadService>((ref) =>
    MediaUploadService(ref.read(databaseProvider), ref.read(dioProvider), ref));
