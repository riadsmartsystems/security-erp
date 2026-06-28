import 'dart:convert';
import 'package:flutter/material.dart';
import '../../data/local/database.dart';

class VisitDetailScreen extends StatefulWidget {
  final RiadDatabase db;
  final String visitUuid;

  const VisitDetailScreen({super.key, required this.db, required this.visitUuid});

  @override
  State<VisitDetailScreen> createState() => _VisitDetailScreenState();
}

class _VisitDetailScreenState extends State<VisitDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _changeStatus(String newStatus) async {
    await widget.db.updateVisitStatus(widget.visitUuid, newStatus);
    await widget.db.createPendingOp(PendingOpsCompanion.insert(
      doctype: 'Visit',
      name: widget.visitUuid,
      op: 'upsert',
      payload: jsonEncode({
        'scalars': {'status': newStatus},
        'additive': {},
      }),
      createdAt: DateTime.now().toUtc().millisecondsSinceEpoch,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Деталі виїзду'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Матеріали'),
            Tab(text: 'Фото'),
            Tab(text: 'Аудіо'),
            Tab(text: 'Чек-лист'),
          ],
        ),
      ),
      body: StreamBuilder<List<Visit>>(
        stream: widget.db.watchVisits(),
        builder: (context, snap) {
          final visits = snap.data ?? [];
          final visit = visits.where((v) => v.clientUuid == widget.visitUuid).firstOrNull;
          if (visit == null) return const Center(child: Text('Виїзд не знайдено'));
          return Column(
            children: [
              _buildStatusActions(visit),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _MaterialsTab(db: widget.db, visitUuid: widget.visitUuid),
                    _PhotosTab(db: widget.db, visitUuid: widget.visitUuid),
                    _AudioTab(db: widget.db, visitUuid: widget.visitUuid),
                    _ChecklistTab(db: widget.db, visitUuid: widget.visitUuid),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusActions(Visit visit) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          if (visit.status != 'в_роботі')
            ElevatedButton(
              onPressed: () => _changeStatus('в_роботі'),
              child: const Text('Розпочати'),
            ),
          const SizedBox(width: 12),
          if (visit.status == 'в_роботі')
            ElevatedButton(
              onPressed: () => _changeStatus('завершено'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Завершити'),
            ),
          const Spacer(),
          Text(visit.status ?? 'чернетка', style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _MaterialsTab extends StatelessWidget {
  final RiadDatabase db;
  final String visitUuid;
  const _MaterialsTab({required this.db, required this.visitUuid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VisitMaterial>>(
      stream: (db.select(db.visitMaterials)
        ..where((t) => t.visitUuid.equals(visitUuid))
        ..where((t) => t.riadDeleted.equals(false))).watch(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Немає матеріалів'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) => ListTile(
            title: Text(items[i].itemName ?? ''),
            subtitle: Text('SN: ${items[i].serialNo ?? "-"} × ${items[i].qty}'),
          ),
        );
      },
    );
  }
}

class _PhotosTab extends StatelessWidget {
  final RiadDatabase db;
  final String visitUuid;
  const _PhotosTab({required this.db, required this.visitUuid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<VisitPhoto>>(
      stream: (db.select(db.visitPhotos)
        ..where((t) => t.visitUuid.equals(visitUuid))
        ..where((t) => t.riadDeleted.equals(false))).watch(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Немає фото'));
        return GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: items.length,
          itemBuilder: (ctx, i) => Card(child: Center(child: Text(items[i].driveFileId ?? ''))),
        );
      },
    );
  }
}

class _AudioTab extends StatelessWidget {
  final RiadDatabase db;
  final String visitUuid;
  const _AudioTab({required this.db, required this.visitUuid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MediaAsset>>(
      stream: (db.select(db.mediaAssets)
        ..where((t) => t.mediaType.equals('audio'))
        ..where((t) => t.parentName.equals(visitUuid))
        ..where((t) => t.riadDeleted.equals(false))).watch(),
      builder: (context, snap) {
        final items = snap.data ?? [];
        if (items.isEmpty) return const Center(child: Text('Немає голосових нотаток'));
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (ctx, i) => ListTile(
            leading: const Icon(Icons.mic),
            title: Text('Нотатка ${i + 1}'),
            subtitle: Text(items[i].transcriptionStatus ?? 'очікує'),
          ),
        );
      },
    );
  }
}

class _ChecklistTab extends StatelessWidget {
  final RiadDatabase db;
  final String visitUuid;
  const _ChecklistTab({required this.db, required this.visitUuid});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/checklist/$visitUuid'),
        child: const Text('Відкрити чек-лист'),
      ),
    );
  }
}
