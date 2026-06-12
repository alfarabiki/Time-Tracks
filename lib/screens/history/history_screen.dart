import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/photo_record.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../widgets/luxe/visit_tile.dart';
import 'photo_detail_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<PhotoRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.getAll();
  }

  void _reload() {
    setState(() => _future = DatabaseService.instance.getAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Riwayat')),
      body: FutureBuilder<List<PhotoRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          final items = snapshot.data ?? const <PhotoRecord>[];
          if (items.isEmpty) {
            return _emptyState();
          }
          return RefreshIndicator(
            color: AppTheme.primary,
            onRefresh: () async => _reload(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                for (final r in items)
                  VisitTile(
                    facility: r.facility.isEmpty ? '—' : r.facility,
                    meta:
                        '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(r.timestamp)} · ${r.visitType.isEmpty ? "Kunjungan" : r.visitType}',
                    trackingNumber: r.trackingNumber,
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => PhotoDetailScreen(record: r)),
                      );
                      _reload();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.photo_outlined, size: 72, color: AppTheme.textSecondary),
          SizedBox(height: 14),
          Text('Belum ada foto',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
