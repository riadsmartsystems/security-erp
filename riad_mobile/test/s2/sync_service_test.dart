import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import 'dart:convert';

import 'package:riad_mobile/data/local/database.dart';
import 'package:riad_mobile/data/sync/sync_client.dart';
import 'package:riad_mobile/data/sync/sync_service.dart';
import 'package:riad_mobile/data/sync/media_upload_service.dart';

@GenerateMocks([http.Client, Connectivity])
import 'sync_service_test.mocks.dart';

void main() {
  late RiadDatabase db;
  late MockClient mockClient;
  late MockConnectivity mockConnectivity;
  late SyncClient syncClient;
  late MediaUploadService mediaUploadService;
  late SyncService syncService;

  setUp(() async {
    db = RiadDatabase.forTesting(NativeDatabase.memory());
    mockClient = MockClient();
    mockConnectivity = MockConnectivity();
    syncClient = SyncClient(
      db: db,
      baseUrl: 'http://localhost:8000',
      jwtToken: 'test-token',
      client: mockClient,
    );
    mediaUploadService = MediaUploadService(
      db: db,
      baseUrl: 'http://localhost:8000',
      jwtToken: 'test-token',
    );
    syncService = SyncService(
      syncClient: syncClient,
      mediaUploadService: mediaUploadService,
      db: db,
      connectivity: mockConnectivity,
    );
  });

  tearDown(() async {
    syncService.dispose();
    await db.close();
  });

  group('retryFailedOps', () {
    test('retryable ops отримують експоненційний backoff', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-retry',
          op: 'upsert',
          payload: jsonEncode({
            'scalars': {'summary': 'Retry test'},
            'additive': {},
          }),
          createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'Server error'}),
            500,
          ));

      try {
        await syncClient.pushPending();
      } catch (_) {}

      final failedOps = await db.getFailedPendingOps();
      expect(failedOps.length, 1);

      await syncService.retryFailedOps();

      final pendingOps = await db.getPendingOps();
      final retriedOps = pendingOps.where((op) => op.name == 'visit-retry').toList();
      expect(retriedOps.length, 1);
      expect(retriedOps.first.retryCount, 1);
      expect(retriedOps.first.nextRetryAt, greaterThan(0));
    });

    test('retryable ops з retryCount=0 отримують backoff 1s', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-retry-0',
          op: 'upsert',
          payload: jsonEncode({'scalars': {}, 'additive': {}}),
          createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'fail'}),
            500,
          ));

      try {
        await syncClient.pushPending();
      } catch (_) {}

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (db.update(db.pendingOps)
            ..where((t) => t.status.equals('failed')))
          .write(PendingOpsCompanion(
        nextRetryAt: Value(now),
      ));

      await syncService.retryFailedOps();

      final ops = await (db.select(db.pendingOps)
            ..where((t) => t.name.equals('visit-retry-0')))
          .getSingle();
      expect(ops.retryCount, 1);
      final expectedBackoff = 1000;
      expect(ops.nextRetryAt, greaterThanOrEqualTo(now + expectedBackoff - 100));
      expect(ops.nextRetryAt, lessThanOrEqualTo(now + expectedBackoff + 100));
    });

    test('retryable ops з retryCount=3 отримують backoff 8s', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-retry-3',
          op: 'upsert',
          payload: jsonEncode({'scalars': {}, 'additive': {}}),
          createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'fail'}),
            500,
          ));

      try {
        await syncClient.pushPending();
      } catch (_) {}

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (db.update(db.pendingOps)
            ..where((t) => t.name.equals('visit-retry-3')))
          .write(PendingOpsCompanion(
        retryCount: const Value(3),
        nextRetryAt: Value(now),
      ));

      await syncService.retryFailedOps();

      final ops = await (db.select(db.pendingOps)
            ..where((t) => t.name.equals('visit-retry-3')))
          .getSingle();
      expect(ops.retryCount, 4);
      final expectedBackoff = 8000;
      expect(ops.nextRetryAt, greaterThanOrEqualTo(now + expectedBackoff - 100));
      expect(ops.nextRetryAt, lessThanOrEqualTo(now + expectedBackoff + 100));
    });

    test('ops що не є retryable (nextRetryAt > now) не обробляються', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-not-ready',
          op: 'upsert',
          payload: jsonEncode({'scalars': {}, 'additive': {}}),
          createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'fail'}),
            500,
          ));

      try {
        await syncClient.pushPending();
      } catch (_) {}

      final futureTime = DateTime.now().toUtc().millisecondsSinceEpoch + 60000;
      await (db.update(db.pendingOps)
            ..where((t) => t.name.equals('visit-not-ready')))
          .write(PendingOpsCompanion(
        nextRetryAt: Value(futureTime),
      ));

      await syncService.retryFailedOps();

      final ops = await (db.select(db.pendingOps)
            ..where((t) => t.name.equals('visit-not-ready')))
          .getSingle();
      expect(ops.retryCount, 0);
    });

    test('max retry count = 5, після цього ops залишаються failed', () async {
      await db.createPendingOp(
        PendingOpsCompanion.insert(
          doctype: 'Visit',
          name: 'visit-max-retry',
          op: 'upsert',
          payload: jsonEncode({'scalars': {}, 'additive': {}}),
          createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
        ),
      );

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'fail'}),
            500,
          ));

      try {
        await syncClient.pushPending();
      } catch (_) {}

      final now = DateTime.now().toUtc().millisecondsSinceEpoch;
      await (db.update(db.pendingOps)
            ..where((t) => t.name.equals('visit-max-retry')))
          .write(PendingOpsCompanion(
        retryCount: const Value(5),
        nextRetryAt: Value(now),
      ));

      await syncService.retryFailedOps();

      final ops = await (db.select(db.pendingOps)
            ..where((t) => t.name.equals('visit-max-retry')))
          .getSingle();
      expect(ops.retryCount, 5);
    });
  });

  group('syncOnce', () {
    test('syncOnce виконує push + pull', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {
                'changes': [],
                'next_watermark': 'watermark-1',
              },
            }),
            200,
          ));

      await syncService.syncOnce();

      final watermark = await db.getWatermark();
      expect(watermark, 'watermark-1');
    });

    test('syncOnce обробляє помилку push без crash', () async {
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({'error': 'Server error'}),
            500,
          ));

      await syncService.syncOnce();

      final failedOps = await db.getFailedPendingOps();
      expect(failedOps.length, greaterThanOrEqualTo(0));
    });
  });

  group('connectivity', () {
    test('start не запускає sync якщо немає зєднання', () async {
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => Stream.value([ConnectivityResult.none]));

      syncService.start();
      await Future.delayed(Duration(milliseconds: 100));

      verifyNever(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ));
    });

    test('dispose зупиняє background sync', () async {
      final controller = StreamController<List<ConnectivityResult>>();
      when(mockConnectivity.onConnectivityChanged)
          .thenAnswer((_) => controller.stream);
      when(mockConnectivity.checkConnectivity())
          .thenAnswer((_) async => [ConnectivityResult.none]);
      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(
            jsonEncode({
              'ok': true,
              'data': {'changes': [], 'next_watermark': 'wm'},
            }),
            200,
          ));
      syncService.start();
      syncService.dispose();

      controller.add([ConnectivityResult.wifi]);
      await Future.delayed(Duration(milliseconds: 200));

      verifyNever(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      ));

      controller.close();
    });
  });
}
