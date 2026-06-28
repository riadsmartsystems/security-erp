import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/auth/auth_models.dart';
import '../../core/auth/auth_notifier.dart';
import 'providers/object_provider.dart';

class ObjectPassportScreen extends ConsumerWidget {
  final String objectId;
  const ObjectPassportScreen({super.key, required this.objectId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final object = ref.watch(objectByIdProvider(objectId));
    final role =
        (ref.watch(authProvider).value as AuthAuthenticated?)?.user.role ??
            'installer';
    final isEngineer = role != 'installer';

    return Scaffold(
      appBar: AppBar(
        title: const Text("Паспорт обʼєкта"),
        actions: [
          if (isEngineer)
            IconButton(
              icon: const Icon(Icons.map_outlined),
              onPressed: () => context.push('/map/$objectId'),
              tooltip: 'Карта монтажу',
            ),
        ],
      ),
      body: object.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Помилка: $e')),
        data: (obj) {
          if (obj == null) return const Center(child: Text('Не знайдено'));
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _MandatorySection(obj: obj),
              const SizedBox(height: 16),
              _OperationalSection(obj: obj, isEngineer: isEngineer),
              if (isEngineer) ...[
                const SizedBox(height: 16),
                _FinancialSection(obj: obj),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MandatorySection extends StatelessWidget {
  final Map<String, dynamic> obj;
  const _MandatorySection({required this.obj});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                obj['name'] as String? ?? '—',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              _InfoRow(
                  icon: Icons.location_on_outlined,
                  label: obj['address'] as String? ?? '—'),
              _InfoRow(
                  icon: Icons.business_outlined,
                  label: obj['customer_name'] as String? ?? '—'),
            ],
          ),
        ),
      );
}

class _OperationalSection extends StatefulWidget {
  final Map<String, dynamic> obj;
  final bool isEngineer;
  const _OperationalSection({required this.obj, required this.isEngineer});

  @override
  State<_OperationalSection> createState() => _OperationalSectionState();
}

class _OperationalSectionState extends State<_OperationalSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: [
            ListTile(
              title: const Text('Операційні дані'),
              trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _InfoRow(
                      icon: Icons.sensors_outlined,
                      label: widget.obj['system_type'] as String? ?? '—',
                    ),
                    if (widget.isEngineer)
                      _InfoRow(
                        icon: Icons.info_outline,
                        label:
                            widget.obj['technical_notes'] as String? ?? '—',
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
}

class _FinancialSection extends StatefulWidget {
  final Map<String, dynamic> obj;
  const _FinancialSection({required this.obj});

  @override
  State<_FinancialSection> createState() => _FinancialSectionState();
}

class _FinancialSectionState extends State<_FinancialSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) => Card(
        child: Column(
          children: [
            ListTile(
              title: const Text('Фінанси'),
              trailing: Icon(_expanded ? Icons.expand_less : Icons.expand_more),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
            if (_expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(
                  widget.obj['financial_summary'] as String? ?? 'Немає даних',
                ),
              ),
          ],
        ),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.white54),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
          ],
        ),
      );
}
