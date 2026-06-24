import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../local/database.dart';
import 'sync_client.dart';
import 'media_upload_service.dart';

class SyncService {
  final SyncClient _syncClient;
  final MediaUploadService _mediaUploadService;
  final RiadDatabase _db;
  final Connectivity _connectivity;

  Timer? _periodicTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isDisposed = false;

  static const int _maxRetryCount = 5;
  static const Duration _syncInterval = Duration(minutes: 5);

  SyncService({
    required SyncClient syncClient,
    required MediaUploadService mediaUploadService,
    required RiadDatabase db,
    Connectivity? connectivity,
  })  : _syncClient = syncClient,
        _mediaUploadService = mediaUploadService,
        _db = db,
        _connectivity = connectivity ?? Connectivity();

  void start() {
    if (_isDisposed) return;

    _periodicTimer = Timer.periodic(_syncInterval, (_) => _onTimer());

    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        syncOnce();
      }
    });

    _checkInitialConnectivity();
  }

  void dispose() {
    _isDisposed = true;
    _periodicTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      await syncOnce();
    }
  }

  void _onTimer() {
    if (_isDisposed) return;
    syncOnce();
  }

  Future<void> syncOnce() async {
    await retryFailedOps();

    try {
      await _syncClient.pushPending();
    } catch (_) {}

    try {
      await _syncClient.pullDelta();
    } catch (_) {}

    try {
      await _mediaUploadService.uploadPending();
    } catch (_) {}
  }

  Future<void> retryFailedOps() async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final retryableOps = await _db.getRetryablePendingOps();

    for (final op in retryableOps) {
      if (op.retryCount >= _maxRetryCount) continue;

      final newRetryCount = op.retryCount + 1;
      final backoffMs = _calculateBackoff(newRetryCount);
      final nextRetryAt = now + backoffMs;

      await _db.updatePendingOpRetry(op.id, newRetryCount, nextRetryAt);
      await _db.updatePendingOpStatus(op.id, 'pending');
    }
  }

  int _calculateBackoff(int retryCount) {
    final baseMs = 1000;
    final backoff = baseMs * (1 << (retryCount - 1));
    return backoff.clamp(1000, 300000);
  }
}
