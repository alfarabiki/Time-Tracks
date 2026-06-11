import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/capture_data.dart';
import '../models/overlay_settings.dart';
import '../models/photo_record.dart';
import 'database_service.dart';
import 'gallery_service.dart';
import 'log_service.dart';
import 'storage_service.dart';

/// Jenis kegagalan simpan yang ramah ditampilkan ke user.
enum SaveErrorType { storageFull, encodeFailed, unknown }

class SaveException implements Exception {
  final SaveErrorType type;
  SaveException(this.type);

  String get message {
    switch (type) {
      case SaveErrorType.storageFull:
        return 'Foto gagal disimpan.\nPenyimpanan tidak mencukupi.';
      case SaveErrorType.encodeFailed:
        return 'Gagal memproses gambar. Silakan coba lagi.';
      default:
        return 'Foto gagal disimpan. Silakan coba lagi.';
    }
  }
}

/// Finalisasi: composite overlay (ui.Image) -> JPEG -> hash -> galeri -> DB.
class PhotoSaveService {
  PhotoSaveService._();
  static final PhotoSaveService instance = PhotoSaveService._();

  Future<PhotoRecord> finalize({
    required ui.Image composited,
    required CaptureData data,
    required OverlaySettings settings,
  }) async {
    try {
      // 1) Ambil pixel mentah dari hasil capture overlay.
      final byteData =
          await composited.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) throw SaveException(SaveErrorType.encodeFailed);

      // 2) Bungkus jadi img.Image lalu encode JPEG sesuai kualitas terpilih.
      final raw = img.Image.fromBytes(
        width: composited.width,
        height: composited.height,
        bytes: byteData.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      final Uint8List jpg = Uint8List.fromList(
        img.encodeJpg(raw, quality: settings.imageQuality.jpegQuality),
      );
      await LogService.instance.log('Overlay Generated',
          detail: '${composited.width}x${composited.height}, ${jpg.length} B');

      // 3) Cek storage sebelum menulis (warning < 500 MB ditangani di UI).
      final free = await StorageService.instance.freeBytes();
      if (free >= 0 && free < jpg.length + (5 * 1024 * 1024)) {
        throw SaveException(SaveErrorType.storageFull);
      }

      // 4) SHA256 untuk integritas (anti-ubah).
      final hash = sha256.convert(jpg).toString().toUpperCase();

      // 5) Tulis salinan permanen milik aplikasi.
      final fileName = _fileName(data.timestamp);
      final docs = await getApplicationDocumentsDirectory();
      final photosDir = Directory(p.join(docs.path, 'photos'));
      if (!await photosDir.exists()) {
        await photosDir.create(recursive: true);
      }
      final outPath = p.join(photosDir.path, fileName);
      try {
        await File(outPath).writeAsBytes(jpg, flush: true);
      } on FileSystemException {
        throw SaveException(SaveErrorType.storageFull);
      }

      // 6) Ekspor ke galeri /DCIM/TimeProof (best-effort, tidak fatal).
      await GalleryService.instance.saveToGallery(outPath);

      // 7) Simpan ke database.
      final record = PhotoRecord(
        id: data.verificationCode, // kode unik = id
        imagePath: outPath,
        address: data.address,
        latitude: data.latitude,
        longitude: data.longitude,
        accuracy: data.accuracy,
        timestamp: data.timestamp,
        verificationCode: data.verificationCode,
        customText: settings.showCustomText ? settings.customText : '',
        imageHash: hash,
        staffName: settings.staffName,
        facility: data.facility,
        visitType: data.visitType,
        trackingNumber: data.trackingNumber,
      );
      await DatabaseService.instance.insert(record);
      await LogService.instance.log('Image Saved', detail: outPath);

      return record;
    } on SaveException {
      rethrow;
    } catch (e) {
      await LogService.instance.log('Save Failed', detail: e.toString());
      throw SaveException(SaveErrorType.unknown);
    }
  }

  String _fileName(DateTime dt) {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(dt);
    return 'IMG_$stamp.jpg';
  }
}
