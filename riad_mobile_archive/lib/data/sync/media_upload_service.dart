import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../local/database.dart';

class MediaUploadService {
  final RiadDatabase db;
  final String baseUrl;
  final String jwtToken;
  final http.Client _httpClient;

  MediaUploadService({
    required this.db,
    required this.baseUrl,
    required this.jwtToken,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  Future<void> uploadPending() async {
    await _retryFailedUploads();
    final pending = await db.getPendingMediaUploads();

    for (final upload in pending) {
      await db.updatePendingMediaUploadStatus(upload.id, 'inflight');

      try {
        final file = File(upload.localPath);
        if (!await file.exists()) {
          await db.updatePendingMediaUploadStatus(upload.id, 'failed');
          continue;
        }

        final bytes = await file.readAsBytes();
        final filename = p.basename(upload.localPath);

        final request = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/v2/media/upload'),
        );
        request.headers['Authorization'] = 'Bearer $jwtToken';
        request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
        request.fields['client_uuid'] = upload.clientUuid;
        request.fields['media_type'] = upload.mediaType;
        if (upload.tag != null) request.fields['tag'] = upload.tag!;
        if (upload.parentDoctype != null) request.fields['parent_doctype'] = upload.parentDoctype!;
        if (upload.parentName != null) request.fields['parent_name'] = upload.parentName!;

        final streamedResponse = await _httpClient.send(request);
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 200) {
          final body = _parseJson(response.body);
          final driveFileId = body['drive_file_id'] as String?;
          if (driveFileId != null) {
            await db.updateMediaAssetDriveFileId(upload.clientUuid, driveFileId);
          }
          await db.updatePendingMediaUploadStatus(upload.id, 'done');
          if (driveFileId != null) {
            await db.createPendingOp(PendingOpsCompanion.insert(
              doctype: 'Media Asset',
              name: upload.clientUuid,
              op: 'upsert',
              payload: jsonEncode({
                'scalars': {'drive_file_id': driveFileId},
                'additive': {},
              }),
              createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
            ));
          }

          // Trigger transcription for voice notes after confirmed upload
          if (upload.mediaType == 'voice') {
            try {
              final resp = await _httpClient.post(
                Uri.parse('$baseUrl/api/v2/media/${upload.clientUuid}/transcribe'),
                headers: {'Authorization': 'Bearer $jwtToken'},
              );
              if (resp.statusCode >= 400) {
                // TODO: mark locally needs_transcription_retry = true,
                // so next sync cycle retries
              }
            } catch (e) {
              // Log error — do not silently swallow, otherwise
              // transcription failures are undiagnosable
              print('[MediaUploadService] Transcription trigger failed for ${upload.clientUuid}: $e');
            }
          }
        } else {
          await db.updatePendingMediaUploadStatus(upload.id, 'failed');
        }
      } catch (e) {
        await db.updatePendingMediaUploadStatus(upload.id, 'failed');
      }
    }
  }

  Future<void> _retryFailedUploads() async {
    final failed = await db.getPendingMediaUploadsByStatus('failed');
    for (final upload in failed) {
      await db.updatePendingMediaUploadStatus(upload.id, 'pending');
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      return Map<String, dynamic>.from(
        jsonDecode(body) as Map,
      );
    } catch (_) {
      return {};
    }
  }
}
