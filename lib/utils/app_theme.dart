import 'package:flutter/material.dart';

/// Tema "Light Luxe" korporat Radjak. (UI app, bukan overlay foto.)
class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF1E40AF); // Biru Radjak
  static const Color secondary = Color(0xFF3B82F6); // Hospital Blue
  static const Color accentBlue = Color(0xFF4F9DF7); // biru terang (di atas gelap)
  static const Color gold = Color(0xFFD4AF37);
  static const Color accent = gold; // alias mundur-kompatibel

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color line = Color(0xFFE8EDF5);
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  static const String fontHeading = 'Fraunces';
  static const String fontBody = 'Inter';

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);
    final scheme = base.colorScheme.copyWith(
      primary: primary, secondary: secondary, surface: surface,
      onPrimary: Colors.white, onSurface: textPrimary,
    );
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: scheme,
      textTheme: base.textTheme.apply(
        fontFamily: fontBody, bodyColor: textPrimary, displayColor: textPrimary,
      ).copyWith(
        headlineLarge: const TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, color: textPrimary),
        headlineMedium: const TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: const TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg, foregroundColor: textPrimary, elevation: 0, centerTitle: false,
        titleTextStyle: TextStyle(fontFamily: fontHeading, fontWeight: FontWeight.w600, fontSize: 20, color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary, foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 18),
          textStyle: const TextStyle(fontFamily: fontBody, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    );
  }

  /// Alias mundur-kompatibel (kode lama memanggil AppTheme.dark).
  static ThemeData get dark => light;
}

void showAppMessage(BuildContext context, String message, {bool error = false}) {
  if (!context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
    ?..clearSnackBars()
    ..showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? const Color(0xFFB3261E) : AppTheme.primary,
      duration: const Duration(seconds: 3),
    ));
}
