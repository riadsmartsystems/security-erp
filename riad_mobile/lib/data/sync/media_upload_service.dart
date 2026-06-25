import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../local/database.dart';

class MediaUploadService {
  final RiadDatabase db;
  final String baseUrl;
  final String jwtToken;

  MediaUploadService({
    required this.db,
    required this.baseUrl,
    required this.jwtToken,
  });

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

        final streamedResponse = await request.send();
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
        _SimpleJsonDecoder().convert(body) as Map,
      );
    } catch (_) {
      return {};
    }
  }
}

class _SimpleJsonDecoder {
  dynamic convert(String source) {
    return _parseValue(source, 0).$1;
  }

  (dynamic, int) _parseValue(String s, int i) {
    i = _skipWhitespace(s, i);
    if (i >= s.length) return (null, i);
    final c = s[i];
    if (c == '"') return _parseString(s, i);
    if (c == '{') return _parseObject(s, i);
    if (c == '[') return _parseArray(s, i);
    if (c == 't') return (true, i + 4);
    if (c == 'f') return (false, i + 5);
    if (c == 'n') return (null, i + 4);
    return _parseNumber(s, i);
  }

  int _skipWhitespace(String s, int i) {
    while (i < s.length && (s[i] == ' ' || s[i] == '\n' || s[i] == '\r' || s[i] == '\t')) i++;
    return i;
  }

  (String, int) _parseString(String s, int i) {
    i++;
    final buf = StringBuffer();
    while (i < s.length && s[i] != '"') {
      if (s[i] == '\\') {
        i++;
        if (i < s.length) {
          switch (s[i]) {
            case 'n': buf.write('\n'); break;
            case 't': buf.write('\t'); break;
            case '\\': buf.write('\\'); break;
            case '"': buf.write('"'); break;
            default: buf.write(s[i]);
          }
        }
      } else {
        buf.write(s[i]);
      }
      i++;
    }
    return (buf.toString(), i + 1);
  }

  (Map<String, dynamic>, int) _parseObject(String s, int i) {
    i++;
    final map = <String, dynamic>{};
    i = _skipWhitespace(s, i);
    if (i < s.length && s[i] == '}') return (map, i + 1);
    while (true) {
      i = _skipWhitespace(s, i);
      final (key, j) = _parseString(s, i);
      i = _skipWhitespace(s, j + 1);
      i++;
      final (value, k) = _parseValue(s, i);
      map[key] = value;
      i = _skipWhitespace(s, k);
      if (i < s.length && s[i] == ',') { i++; continue; }
      break;
    }
    return (map, i + 1);
  }

  (List<dynamic>, int) _parseArray(String s, int i) {
    i++;
    final list = <dynamic>[];
    i = _skipWhitespace(s, i);
    if (i < s.length && s[i] == ']') return (list, i + 1);
    while (true) {
      final (value, j) = _parseValue(s, i);
      list.add(value);
      i = _skipWhitespace(s, j);
      if (i < s.length && s[i] == ',') { i++; continue; }
      break;
    }
    return (list, i + 1);
  }

  (num, int) _parseNumber(String s, int i) {
    var j = i;
    while (j < s.length && (s[j].codeUnitAt(0) >= 48 && s[j].codeUnitAt(0) <= 57 || s[j] == '.' || s[j] == '-' || s[j] == '+' || s[j] == 'e' || s[j] == 'E')) j++;
    final numStr = s.substring(i, j);
    final n = num.parse(numStr);
    return (n, j);
  }
}
