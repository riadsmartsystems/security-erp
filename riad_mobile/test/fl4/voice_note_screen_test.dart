import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riad_mobile/core/api/dio_client.dart';
import 'package:riad_mobile/core/sync/media_upload_service.dart';
import 'package:riad_mobile/features/media/voice_note_screen.dart';
import 'package:dio/dio.dart';

class MockMediaUploadService extends Mock implements MediaUploadService {}
class MockDio extends Mock implements Dio {}

Widget _buildVoice({
  String visitId = 'v1',
  MediaUploadService? svc,
  Dio? dio,
}) {
  return ProviderScope(
    overrides: [
      mediaUploadProvider.overrideWithValue(svc ?? MockMediaUploadService()),
      dioProvider.overrideWithValue(dio ?? MockDio()),
    ],
    child: MaterialApp(home: VoiceNoteScreen(visitId: visitId)),
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(RequestOptions(path: ''));
  });

  group('VoiceNoteScreen', () {
    testWidgets('shows mic button initially', (tester) async {
      await tester.pumpWidget(_buildVoice());
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.mic), findsOneWidget);
    });

    testWidgets('shows AppBar with correct title', (tester) async {
      await tester.pumpWidget(_buildVoice());
      await tester.pumpAndSettle();
      expect(find.text('Голосова нотатка'), findsOneWidget);
    });

    testWidgets('no transcription badge shown before recording', (tester) async {
      await tester.pumpWidget(_buildVoice());
      await tester.pumpAndSettle();
      expect(find.byType(TranscriptionStatusBadge), findsNothing);
    });
  });

  group('TranscriptionStatusBadge', () {
    testWidgets('pending — shows orange chip', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TranscriptionStatusBadge(status: 'pending')),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('очікує'), findsOneWidget);
    });

    testWidgets('ready — shows green chip', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TranscriptionStatusBadge(status: 'ready')),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('готова'), findsOneWidget);
    });

    testWidgets('none — shows grey chip', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: TranscriptionStatusBadge(status: 'none')),
      ));
      await tester.pumpAndSettle();
      expect(find.textContaining('немає'), findsOneWidget);
    });
  });
}
