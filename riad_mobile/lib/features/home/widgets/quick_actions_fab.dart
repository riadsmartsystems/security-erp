import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth/auth_models.dart';
import '../../../core/auth/auth_notifier.dart';

class QuickActionsFab extends ConsumerStatefulWidget {
  const QuickActionsFab({super.key});

  @override
  ConsumerState<QuickActionsFab> createState() => _QuickActionsFabState();
}

class _QuickActionsFabState extends ConsumerState<QuickActionsFab> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider).value;
    final role =
        (authState is AuthAuthenticated) ? authState.user.role : 'installer';
    final actions = _actionsForRole(role);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_open)
          ...actions.reversed.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.small(
                  heroTag: a.label,
                  onPressed: () {
                    setState(() => _open = false);
                    a.onTap(context);
                  },
                  tooltip: a.label,
                  child: Icon(a.icon),
                ),
              )),
        FloatingActionButton(
          onPressed: () => setState(() => _open = !_open),
          child: Icon(_open ? Icons.close : Icons.add),
        ),
      ],
    );
  }

  List<_FabAction> _actionsForRole(String role) {
    final all = <_FabAction>[
      _FabAction(Icons.drive_eta_outlined, 'Новий виїзд',
          (ctx) => ctx.push('/visit/new')),
      _FabAction(Icons.build_outlined, 'Сервісна заявка',
          (ctx) => ctx.push('/service/new')),
    ];

    if (role != 'installer') {
      all.addAll([
        _FabAction(Icons.calculate_outlined, 'Прорахунок',
            (ctx) => ctx.push('/estimate/new')),
        _FabAction(Icons.videocam_outlined, 'Огляд',
            (ctx) => ctx.push('/remote-inspection/new')),
        _FabAction(Icons.person_add_outlined, 'Новий лід',
            (ctx) => ctx.push('/lead/new')),
      ]);
    }
    return all;
  }
}

class _FabAction {
  final IconData icon;
  final String label;
  final void Function(BuildContext) onTap;
  const _FabAction(this.icon, this.label, this.onTap);
}
