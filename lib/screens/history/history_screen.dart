import 'dart:io';

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

  String _typeFilter = 'Semua';
  String _search = '';

  static const _types = ['Semua', 'Sales Visit', 'Maintenance', 'Follow-up', 'Survey'];

  @override
  void initState() {
    super.initState();
    _future = DatabaseService.instance.getAll();
  }

  void _reload() {
    setState(() => _future = DatabaseService.instance.getAll());
  }

  List<PhotoRecord> _filter(List<PhotoRecord> items) {
    return items.where((r) {
      final matchesType = _typeFilter == 'Semua' || r.visitType == _typeFilter;
      final matchesSearch = _search.isEmpty ||
          r.facility.toLowerCase().contains(_search.toLowerCase());
      return matchesType && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Riwayat')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: TextField(
                onChanged: (v) => setState(() => _search = v),
                decoration: InputDecoration(
                  hintText: 'Cari faskes / tujuan...',
                  prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.line)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.line)),
                ),
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _dateChip(),
                  const SizedBox(width: 8),
                  ..._types.map((t) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(t),
                          selected: _typeFilter == t,
                          onSelected: (_) => setState(() => _typeFilter = t),
                          labelStyle: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _typeFilter == t ? Colors.white : AppTheme.textPrimary,
                          ),
                          selectedColor: AppTheme.primary,
                          backgroundColor: AppTheme.surface,
                          side: const BorderSide(color: AppTheme.line),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: FutureBuilder<List<PhotoRecord>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary),
                    );
                  }
                  final items = _filter(snapshot.data ?? const <PhotoRecord>[]);
                  if (items.isEmpty) {
                    return _emptyState();
                  }
                  return RefreshIndicator(
                    color: AppTheme.primary,
                    onRefresh: () async => _reload(),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        for (final r in items)
                          VisitTile(
                            facility: r.facility.isEmpty ? '—' : r.facility,
                            meta:
                                '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(r.timestamp)} · ${r.visitType.isEmpty ? "Kunjungan" : r.visitType}',
                            trackingNumber: r.trackingNumber,
                            thumbnail: r.imagePath.isNotEmpty && File(r.imagePath).existsSync()
                                ? Image.file(File(r.imagePath), fit: BoxFit.cover)
                                : null,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateChip() => InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.line),
          ),
          child: const Row(children: [
            Icon(Icons.calendar_today_outlined, size: 15, color: AppTheme.primary),
            SizedBox(width: 6),
            Text('Tanggal', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
            Icon(Icons.arrow_drop_down, size: 18, color: AppTheme.textSecondary),
          ]),
        ),
      );

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
