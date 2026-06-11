import 'package:flutter/material.dart';

/// Tema terang korporat Radjak (UI aplikasi, bukan overlay foto).
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1E40AF); // Biru Radjak
  static const Color secondary = Color(0xFF3B82F6); // Hospital Blue
  static const Color gold = Color(0xFFD4AF37); // Luxury Gold

  /// Token aksen lama (dipakai layar lain) -> emas Radjak.
  static const Color accent = gold;

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onPrimary: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Alias mundur-kompatibel: kode lama memanggil AppTheme.dark.
  static ThemeData get dark => light;
}

/// Helper tampil pesan ramah (tanpa stack trace ke user).
void showAppMessage(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  messenger
    ?..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? const Color(0xFFB3261E) : AppTheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
}
