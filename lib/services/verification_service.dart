import 'dart:math';

import '../utils/constants.dart';

/// Generate kode verifikasi acak (Feature 5).
/// Format: 14 karakter alfanumerik kapital, mis. "PDMM1DM1YHEYRG".
class VerificationService {
  VerificationService._();

  // Tanpa karakter ambigu (0/O, 1/I) agar mudah dibaca? Contoh memakai 1 & M,
  // jadi kita pertahankan set penuh A-Z 0-9 sesuai contoh.
  static const String _charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  static final Random _rng = Random.secure();

  static String generate({int length = K.verificationCodeLength}) {
    final buf = StringBuffer();
    for (var i = 0; i < length; i++) {
      buf.write(_charset[_rng.nextInt(_charset.length)]);
    }
    return buf.toString();
  }
}
