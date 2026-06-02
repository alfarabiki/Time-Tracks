import 'package:intl/intl.dart';

/// Helper format tanggal & koordinat (gaya Indonesia, sama seperti contoh).
class FormatUtils {
  FormatUtils._();

  /// "Selasa, 02 Juni 2026 22:21"
  static String fullDate(DateTime dt) {
    return DateFormat("EEEE, dd MMMM yyyy HH:mm", "id_ID").format(dt);
  }

  /// "02 Jun 2026 22:21" (untuk list history yang ringkas)
  static String shortDate(DateTime dt) {
    return DateFormat("dd MMM yyyy HH:mm", "id_ID").format(dt);
  }

  /// "6.185037°S, 106.863431°E"
  static String coordinates(double lat, double lng) {
    final latDir = lat >= 0 ? 'N' : 'S';
    final lngDir = lng >= 0 ? 'E' : 'W';
    final latAbs = lat.abs().toStringAsFixed(6);
    final lngAbs = lng.abs().toStringAsFixed(6);
    return '$latAbs°$latDir, $lngAbs°$lngDir';
  }

  /// "Akurasi: 5 m"
  static String accuracy(double meters) {
    return 'Akurasi: ${meters.toStringAsFixed(0)} m';
  }
}
