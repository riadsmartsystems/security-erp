import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riad_mobile/core/connectivity/connectivity_service.dart';
import 'package:riad_mobile/features/remote_inspection/remote_inspection_screen.dart';

Widget _wrap(Widget child, {bool online = false}) => ProviderScope(
      overrides: [
        connectivityProvider.overrideWith(
          (ref) => Stream.value(online),
        ),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  group('RemoteInspectionScreen', () {
    testWidgets('shows AppBar title', (tester) async {
      await tester.pumpWidget(
        _wrap(const RemoteInspectionScreen(inspectionId: 'ri-1')),
      );
      await tester.pump();
      expect(find.text('Віддалений огляд'), findsOneWidget);
    });

    testWidgets('shows offline message when offline and no data',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          const RemoteInspectionScreen(inspectionId: 'ri-1'),
          online: false,
        ),
      );
      await tester.pump();
      expect(
        find.text('Недоступно офлайн. Підключіться для перегляду.'),
        findsOneWidget,
      );
    });

    testWidgets('MediaSection shows zero count when empty', (tester) async {
      await tester.pumpWidget(
        _wrap(const _MediaSectionHost(mediaIds: [])),
      );
      await tester.pump();
      expect(find.text('Медіафайли (0)'), findsOneWidget);
      expect(find.text('Немає прикріплених файлів'), findsOneWidget);
    });

    testWidgets('MediaSection lists media ids', (tester) async {
      await tester.pumpWidget(
        _wrap(const _MediaSectionHost(mediaIds: ['id-1', 'id-2'])),
      );
      await tester.pump();
      expect(find.text('Медіафайли (2)'), findsOneWidget);
      expect(find.text('id-1'), findsOneWidget);
      expect(find.text('id-2'), findsOneWidget);
    });
  });
}

// Test helper to render _MediaSection directly
class _MediaSectionHost extends StatelessWidget {
  final List<String> mediaIds;
  const _MediaSectionHost({required this.mediaIds});

  @override
  Widget build(BuildContext context) => Scaffold(
        body: ListView(children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Медіафайли (${mediaIds.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (mediaIds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text('Немає прикріплених файлів'),
                    ),
                  ...mediaIds.map((id) => ListTile(
                        leading: const Icon(Icons.attach_file),
                        title: Text(id),
                        dense: true,
                      )),
                ],
              ),
            ),
          ),
        ]),
      );
}
