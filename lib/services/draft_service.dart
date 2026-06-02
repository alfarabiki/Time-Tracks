import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/capture_data.dart';
import '../utils/constants.dart';
import 'log_service.dart';

/// Recovery mechanism (Quality > Recovery Mechanism).
/// Menyimpan draft foto yang belum selesai agar bisa dilanjutkan jika
/// aplikasi tertutup tiba-tiba / HP restart.
class DraftService {
  DraftService._();
  static final DraftService instance = DraftService._();

  Future<void> save(CaptureData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(K.prefDraft, data.encode());
      await LogService.instance.log('Draft Saved');
    } catch (_) {/* abaikan */}
  }

  /// Ambil draft jika ada DAN file fotonya masih ada.
  Future<CaptureData?> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draft = CaptureData.decode(prefs.getString(K.prefDraft));
      if (draft == null) return null;
      if (draft.rawImagePath.isEmpty || !File(draft.rawImagePath).existsSync()) {
        await clear();
        return null;
      }
      return draft;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(K.prefDraft);
    } catch (_) {/* abaikan */}
  }
}
