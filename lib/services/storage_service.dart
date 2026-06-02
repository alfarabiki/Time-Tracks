import 'package:flutter/services.dart';

import '../utils/constants.dart';

/// Cek sisa penyimpanan (Quality > Storage Management).
/// Memakai StatFs native via MethodChannel — gratis & andal di semua vendor.
class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  static const MethodChannel _channel = MethodChannel('timeproof/storage');

  /// Sisa byte penyimpanan internal, atau -1 jika tidak diketahui.
  Future<int> freeBytes() async {
    try {
      final result = await _channel.invokeMethod<int>('freeBytes');
      return result ?? -1;
    } catch (_) {
      return -1; // jangan crash kalau channel tak tersedia
    }
  }

  /// true jika sisa < 500 MB (atau tidak diketahui → false agar tidak ganggu).
  Future<bool> isLow() async {
    final bytes = await freeBytes();
    if (bytes < 0) return false;
    return bytes < K.lowStorageThresholdBytes;
  }

  String formatMb(int bytes) {
    if (bytes < 0) return '–';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
}
