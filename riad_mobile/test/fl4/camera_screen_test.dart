import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riad_mobile/core/sync/media_upload_service.dart';
import 'package:riad_mobile/features/media/camera_screen.dart';

class MockMediaUploadService extends Mock implements MediaUploadService {}

Widget _buildCamera({
  String docType = 'Engineer Visit',
  String docName = 'EV-001',
  PhotoTag defaultTag = PhotoTag.before,
  MediaUploadService? svc,
}) {
  final mockSvc = svc ?? MockMediaUploadService();
  return ProviderScope(
    overrides: [
      mediaUploadProvider.overrideWithValue(mockSvc),
    ],
    child: MaterialApp(
      home: CameraScreen(
        docType: docType,
        docName: docName,
        defaultTag: defaultTag,
      ),
    ),
  );
}

void main() {
  group('CameraScreen', () {
    testWidgets('shows loading when camera not initialized', (tester) async {
      await tester.pumpWidget(_buildCamera());
      await tester.pump();
      // Before camera init, shows loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    test('PhotoTag.before label is До', () {
      expect(PhotoTag.before.label, 'До');
    });

    test('PhotoTag.after label is Після', () {
      expect(PhotoTag.after.label, 'Після');
    });

    test('PhotoTag.cmm label is CMM', () {
      expect(PhotoTag.cmm.label, 'CMM');
    });

    testWidgets('shows AppBar with title Фото', (tester) async {
      // Can't test past loading without real camera; test initial state only
      await tester.pumpWidget(_buildCamera());
      await tester.pump();
      expect(find.text('Фото'), findsOneWidget);
    });
  });
}
