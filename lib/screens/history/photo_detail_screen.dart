import 'dart:io';

import 'package:flutter/material.dart';

import '../../models/photo_record.dart';
import '../../services/database_service.dart';
import '../../services/gallery_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/format_utils.dart';

class PhotoDetailScreen extends StatelessWidget {
  final PhotoRecord record;
  const PhotoDetailScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final file = File(record.imagePath);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Foto'),
        actions: [
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: file.existsSync()
                ? InteractiveViewer(
                    child: Image.file(file, fit: BoxFit.contain),
                  )
                : Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(Icons.broken_image,
                          color: Colors.white38, size: 56),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.schedule, 'Waktu',
                    FormatUtils.fullDate(record.timestamp)),
                if (record.address.isNotEmpty)
                  _row(Icons.location_on_outlined, 'Alamat', record.address),
                _row(Icons.my_location, 'Koordinat',
                    FormatUtils.coordinates(record.latitude, record.longitude)),
                if (record.accuracy > 0)
                  _row(Icons.gps_fixed, 'Akurasi',
                      FormatUtils.accuracy(record.accuracy)),
                if (record.customText.isNotEmpty)
                  _row(Icons.text_fields, 'Catatan', record.customText),
                _row(Icons.qr_code_2, 'Kode Verifikasi',
                    record.verificationCode),
                _row(Icons.fingerprint, 'SHA256 (integritas)',
                    record.imageHash.isEmpty ? '–' : record.imageHash),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final ok = await GalleryService.instance
                          .saveToGallery(record.imagePath);
                      if (context.mounted) {
                        showAppMessage(
                          context,
                          ok
                              ? 'Disimpan ulang ke galeri.'
                              : 'Gagal menyimpan ke galeri.',
                          error: !ok,
                        );
                      }
                    },
                    icon: const Icon(Icons.save_alt),
                    label: const Text('Simpan ke Galeri'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.accent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12)),
                const SizedBox(height: 2),
                SelectableText(
                  value,
                  style: const TextStyle(color: AppTheme.textPrimary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Hapus foto?'),
        content: const Text(
            'Foto akan dihapus dari riwayat aplikasi. Salinan di galeri tidak ikut terhapus.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseService.instance.delete(record.id);
    try {
      final f = File(record.imagePath);
      if (await f.exists()) await f.delete();
    } catch (_) {/* abaikan */}
    if (context.mounted) Navigator.of(context).pop();
  }
}
