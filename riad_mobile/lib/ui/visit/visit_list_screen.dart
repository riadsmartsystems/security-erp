import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/local/database.dart';

class VisitListScreen extends StatelessWidget {
  final RiadDatabase db;

  const VisitListScreen({super.key, required this.db});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Мої виїзди'),
        actions: [
          StreamBuilder<int>(
            stream: db.watchPendingCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              if (count == 0) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Center(
                  child: Badge(
                    label: Text('$count'),
                    child: const Icon(Icons.cloud_upload),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ConnectivityResult>>(
        stream: Connectivity().onConnectivityChanged,
        builder: (context, connSnap) {
          final isOffline = connSnap.data?.every((r) => r == ConnectivityResult.none) ?? true;
          return Column(
            children: [
              if (isOffline)
                Container(
                  width: double.infinity,
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(8),
                  child: const Text('OFFLINE — дані зберігаються локально', textAlign: TextAlign.center),
                ),
              Expanded(child: _buildVisitList(context)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/visit/new'),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildVisitList(BuildContext context) {
    return StreamBuilder<List<Visit>>(
      stream: db.watchVisits(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final visits = snapshot.data!;
        if (visits.isEmpty) return const Center(child: Text('Немає виїздів'));
        return ListView.builder(
          itemCount: visits.length,
          itemBuilder: (context, index) => _VisitCard(visit: visits[index]),
        );
      },
    );
  }
}

class _VisitCard extends StatelessWidget {
  final Visit visit;
  const _VisitCard({required this.visit});

  Color _statusColor(String? status) {
    switch (status) {
      case 'в_роботі': return Colors.blue;
      case 'завершено': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        title: Text(visit.summary ?? visit.serviceTicket ?? 'Виїзд'),
        subtitle: Text(visit.visitDate?.toLocal().toString().substring(0, 10) ?? ''),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(visit.status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(visit.status ?? 'чернетка', style: TextStyle(color: _statusColor(visit.status), fontSize: 12)),
        ),
        onTap: () => Navigator.pushNamed(context, '/visit/${visit.clientUuid}'),
      ),
    );
  }
}
