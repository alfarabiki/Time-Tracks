import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/photo_record.dart';
import '../../services/database_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';
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
      appBar: AppBar(title: const Text('Riwayat Foto')),
      body: FutureBuilder<List<PhotoRecord>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          }
          final items = snapshot.data ?? const <PhotoRecord>[];
          if (items.isEmpty) {
            return _emptyState();
          }
          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () async => _reload(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              itemBuilder: (context, i) => _tile(items[i]),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.photo_outlined, size: 72, color: AppTheme.textSecondary),
          const SizedBox(height: 14),
          const Text('Belum ada foto',
              style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _tile(PhotoRecord r) {
    final file = File(r.imagePath);
    return Material(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => PhotoDetailScreen(record: r)),
          );
          _reload();
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 64,
                  height: 64,
                  child: file.existsSync()
                      ? Image.file(
                          file,
                          fit: BoxFit.cover,
                          cacheWidth: 160, // hemat memori utk ribuan item
                          errorBuilder: (_, __, ___) => _thumbFallback(),
                        )
                      : _thumbFallback(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      FormatUtils.shortDate(r.timestamp),
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.address.isNotEmpty
                          ? r.address
                          : FormatUtils.coordinates(r.latitude, r.longitude),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      r.trackingNumber.isNotEmpty
                          ? r.trackingNumber
                          : r.verificationCode,
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _thumbFallback() => Container(
        color: Colors.black26,
        child: const Icon(Icons.image_not_supported_outlined,
            color: Colors.white38),
      );
}
