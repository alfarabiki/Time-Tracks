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
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Detail Kunjungan'),
        actions: [
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _confirmDelete(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 3 / 4,
              child: file.existsSync()
                  ? InteractiveViewer(
                      child: Image.file(file, fit: BoxFit.cover),
                    )
                  : Container(
                      color: AppTheme.surface,
                      child: const Center(
                        child: Icon(Icons.broken_image,
                            color: AppTheme.textSecondary, size: 56),
                      ),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(Icons.schedule, 'Waktu',
                    FormatUtils.fullDate(record.timestamp)),
                if (record.trackingNumber.isNotEmpty)
                  _row(Icons.confirmation_number_outlined, 'Nomor Tracking',
                      record.trackingNumber),
                if (record.staffName.isNotEmpty)
                  _row(Icons.badge_outlined, 'Nama Staf', record.staffName),
                if (record.facility.isNotEmpty)
                  _row(Icons.local_hospital_outlined, 'Faskes / Tujuan',
                      record.facility),
                if (record.visitType.isNotEmpty)
                  _row(Icons.assignment_outlined, 'Jenis Kunjungan',
                      record.visitType),
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
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12.5)),
                const SizedBox(height: 3),
                SelectableText(
                  value,
                  style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35),
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
