import 'package:shared_preferences/shared_preferences.dart';

import '../models/overlay_settings.dart';
import '../utils/constants.dart';

/// Simpan & muat OverlaySettings (Settings Screen).
class SettingsService {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  OverlaySettings _cache = const OverlaySettings();
  OverlaySettings get current => _cache;

  Future<OverlaySettings> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(K.prefSettings);
      _cache = raw == null ? const OverlaySettings() : OverlaySettings.decode(raw);
    } catch (_) {
      _cache = const OverlaySettings();
    }
    return _cache;
  }

  Future<void> save(OverlaySettings settings) async {
    _cache = settings;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(K.prefSettings, settings.encode());
    } catch (_) {/* abaikan */}
  }
}
