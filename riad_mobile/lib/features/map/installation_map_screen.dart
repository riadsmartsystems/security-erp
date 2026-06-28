import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import 'providers/map_provider.dart';
import 'widgets/floor_plan_editor.dart';
import 'widgets/territory_map.dart';

class InstallationMapScreen extends ConsumerWidget {
  final String objectId;
  const InstallationMapScreen({super.key, required this.objectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapData = ref.watch(mapDataProvider(objectId));
    final role = (ref.watch(authProvider).value as AuthAuthenticated?)
            ?.user
            .role ??
        'installer';
    final canEdit = role != 'installer';

    return Scaffold(
      appBar: AppBar(title: const Text('Карта монтажу')),
      body: mapData.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (data) {
          if (data == null) return const Center(child: Text('Немає карти'));
          final mapKind = data['map_kind'] as String? ?? 'floor';
          final points = data['points'] as List? ?? [];

          return switch (mapKind) {
            'floor' => FloorPlanEditor(
                objectId: objectId,
                basePlanUrl: data['base_plan_url'] as String?,
                points: points,
                canEdit: canEdit,
              ),
            'territory' => TerritoryMap(
                objectId: objectId,
                points: points,
                canEdit: canEdit,
              ),
            _ => const Center(child: Text('Невідомий тип карти')),
          };
        },
      ),
    );
  }
}
