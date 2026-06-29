import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _channels = [
  ('new_task', 'Нова задача призначена'),
  ('sync_conflict', 'Конфлікт синхронізації'),
  ('transcription', 'Транскрипція готова'),
  ('estimate_review', 'Кошторис на перевірку'),
  ('ai_degradation', 'Деградація AI'),
];

class NotifNotifier extends StateNotifier<Map<String, bool>> {
  NotifNotifier() : super({}) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = {
      for (final (k, _) in _channels)
        k: prefs.getBool('notif_$k') ?? true
    };
  }

  Future<void> toggle(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final newVal = !(state[key] ?? true);
    await prefs.setBool('notif_$key', newVal);
    state = {...state, key: newVal};
  }
}

final notifSettingsProvider =
    StateNotifierProvider<NotifNotifier, Map<String, bool>>(
  (_) => NotifNotifier(),
);

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(notifSettingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Сповіщення')),
      body: ListView(children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Секрети НІКОЛИ не надсилаються в сповіщеннях.',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ),
        ..._channels.map(
          (c) => SwitchListTile(
            title: Text(c.$2),
            value: settings[c.$1] ?? true,
            onChanged: (_) =>
                ref.read(notifSettingsProvider.notifier).toggle(c.$1),
          ),
        ),
      ]),
    );
  }
}
