import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/ai_status_chip.dart';
import '../../core/widgets/offline_banner.dart';
import 'providers/home_provider.dart';
import 'widgets/quick_actions_fab.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingCount = ref.watch(pendingCountProvider).value ?? 0;
    final currentIndex =
        _locationToIndex(GoRouterState.of(context).matchedLocation);

    return Scaffold(
      appBar: AppBar(
        title: const Text('RIAD'),
        actions: const [
          AiStatusChip(),
          SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (i) => _goToIndex(context, i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task),
            label: 'Задачі',
          ),
          const NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business),
            label: "Об'єкти",
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.lock_outline),
            ),
            selectedIcon: const Icon(Icons.lock),
            label: 'Vault',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: pendingCount > 0,
              label: Text('$pendingCount'),
              child: const Icon(Icons.sync_outlined),
            ),
            selectedIcon: const Icon(Icons.sync),
            label: 'Синк',
          ),
        ],
      ),
      floatingActionButton:
          currentIndex == 0 ? const QuickActionsFab() : null,
    );
  }

  int _locationToIndex(String location) {
    if (location.startsWith('/home/objects')) return 1;
    if (location.startsWith('/home/vault')) return 2;
    if (location.startsWith('/home/sync')) return 3;
    return 0;
  }

  void _goToIndex(BuildContext ctx, int i) {
    switch (i) {
      case 0:
        ctx.go('/home/tasks');
      case 1:
        ctx.go('/home/objects');
      case 2:
        ctx.go('/home/vault');
      case 3:
        ctx.go('/home/sync');
    }
  }
}
