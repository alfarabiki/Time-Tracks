import 'package:flutter/material.dart';

/// Tema gelap ringan untuk UI aplikasi (bukan overlay foto).
class AppTheme {
  AppTheme._();

  static const Color accent = Color(0xFFF5A623); // amber seperti bar overlay
  static const Color bg = Color(0xFF0E1726);
  static const Color surface = Color(0xFF18233A);

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accent,
        surface: surface,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
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
        backgroundColor: error ? const Color(0xFFB3261E) : AppTheme.surface,
        duration: const Duration(seconds: 3),
      ),
    );
}
