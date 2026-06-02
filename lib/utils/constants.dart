/// Konstanta global aplikasi.
class K {
  K._();

  static const String appName = 'TimeProof';
  static const String galleryAlbum = 'TimeProof';

  // Location reliability (Quality requirements)
  static const Duration gpsTimeout = Duration(seconds: 15);

  // Storage management
  static const int lowStorageThresholdBytes = 500 * 1024 * 1024; // 500 MB

  // Logging retention
  static const int logRetentionDays = 30;

  // Verification code
  static const int verificationCodeLength = 14;

  // SharedPreferences keys
  static const String prefSettings = 'overlay_settings_v1';
  static const String prefDraft = 'capture_draft_v1';
}
