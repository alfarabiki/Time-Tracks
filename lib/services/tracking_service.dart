import 'package:shared_preferences/shared_preferences.dart';

/// Hasil hitung urutan tracking (tahun + nomor urut).
class TrackingSeq {
  final int year;
  final int seq;
  const TrackingSeq(this.year, this.seq);
}

/// Nomor tracking lokal berurutan: TP-YYYY-NNNNNN.
/// Counter disimpan di shared_preferences, reset otomatis tiap tahun.
class TrackingService {
  TrackingService._();
  static final TrackingService instance = TrackingService._();

  static const String _kYear = 'tracking_year';
  static const String _kSeq = 'tracking_seq';

  /// Format nomor tracking final.
  static String format(int year, int seq) =>
      'TP-$year-${seq.toString().padLeft(6, '0')}';

  /// Inti murni (mudah dites): hitung urutan berikutnya.
  static TrackingSeq nextSeq({
    required int storedYear,
    required int storedSeq,
    required int currentYear,
  }) {
    if (storedYear != currentYear) return TrackingSeq(currentYear, 1);
    return TrackingSeq(currentYear, storedSeq + 1);
  }

  /// Ambil nomor tracking berikutnya & simpan counter. [year] dari timestamp foto.
  Future<String> next(int year) async {
    final prefs = await SharedPreferences.getInstance();
    final storedYear = prefs.getInt(_kYear) ?? 0;
    final storedSeq = prefs.getInt(_kSeq) ?? 0;
    final r = nextSeq(storedYear: storedYear, storedSeq: storedSeq, currentYear: year);
    await prefs.setInt(_kYear, r.year);
    await prefs.setInt(_kSeq, r.seq);
    return format(r.year, r.seq);
  }
}
