import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'api_service.dart';
import 'sync_queue_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';

class SyncManager {
  static final SyncManager _instance = SyncManager._internal();
  factory SyncManager() => _instance;
  SyncManager._internal();

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void start() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        syncPendingRequests();
      }
    });
    syncPendingRequests();
  }

  void stop() {
    _connectivitySubscription?.cancel();
  }

  Future<void> syncPendingRequests() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = await syncQueue.getQueue();
      if (queue.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (var request in queue) {
        final id = request['id'] as int;
        final url = request['url'] as String;
        final method = request['method'] as String;
        final body = jsonDecode(request['body'] as String) as Map<String, dynamic>;
        final filePath = request['file_path'] as String?;

        try {
          if (filePath != null) {
            // Handle Multipart Upload
            final multipartRequest = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}$url'));
            
            final storage = FlutterSecureStorage();
            final tokenStr = await storage.read(key: 'token');
            if (tokenStr != null) {
              multipartRequest.headers['Authorization'] = 'Bearer $tokenStr';
            }

            body.forEach((k, v) => multipartRequest.fields[k] = v.toString());
            
            final file = File(filePath);
            if (await file.exists()) {
              multipartRequest.files.add(await http.MultipartFile.fromPath('file', filePath));
            } else {
              throw Exception('File not found at $filePath');
            }

            final streamedResponse = await multipartRequest.send();
            final response = await http.Response.fromStream(streamedResponse);
            
            if (response.statusCode != 200 && response.statusCode != 201) {
              throw Exception('Upload failed: ${response.statusCode}');
            }
          } else {
            // Handle Standard JSON Upload
            if (method == 'POST') {
              await api.post(url, body);
            } else if (method == 'PUT') {
              // Not implemented yet, but could be added here
            }
          }
          
          await syncQueue.removeFromQueue(id);
        } catch (e) {
          await syncQueue.incrementAttempts(id);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }


      final storage = const FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      for (var request in queue) {
        final id = request['id'] as int;
        final url = request['url'] as String;
        final method = request['method'] as String;
        final body = jsonDecode(request['body'] as String) as Map<String, dynamic>;
        final filePath = request['filePath'] as String?;

        try {
          if (method == 'POST') {
            if (filePath != null) {
              // Handle Multipart Request for files
              final multipartRequest = http.MultipartRequest('POST', Uri.parse('${ApiService.baseUrl}$url'));
              if (token != null) {
                multipartRequest.headers['Authorization'] = 'Bearer $token';
              }
              multipartRequest.fields.addAll(body);
              multipartRequest.files.add(await http.MultipartFile.fromPath('file', filePath));
              
              final streamedResponse = await multipartRequest.send();
              final response = await http.Response.fromStream(streamedResponse);
              if (response.statusCode != 200 && response.statusCode != 201) throw Exception('Upload failed');
            } else {
              // Handle JSON Request
              await api.post(url, body);
            }
          }
          
          await syncQueue.removeFromQueue(id);
        } catch (e) {
          await syncQueue.incrementAttempts(id);
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}

final syncManager = SyncManager();

