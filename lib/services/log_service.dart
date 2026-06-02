import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../utils/constants.dart';

/// Logging internal (Quality > Logging).
/// Menyimpan event 30 hari terakhir untuk troubleshooting.
/// Semua operasi defensif — TIDAK pernah melempar exception ke pemanggil.
class LogService {
  LogService._();
  static final LogService instance = LogService._();

  File? _file;
  bool _ready = false;

  Future<void> init() async {
    try {
      final dir = await getApplicationSupportDirectory();
      _file = File(p.join(dir.path, 'timeproof.log'));
      if (!await _file!.exists()) {
        await _file!.create(recursive: true);
      }
      _ready = true;
      await _prune();
      await log('App started');
    } catch (_) {
      _ready = false; // logging tidak boleh menghentikan aplikasi
    }
  }

  Future<void> log(String event, {String detail = ''}) async {
    if (!_ready || _file == null) return;
    try {
      final ts = DateTime.now().toIso8601String();
      final line = detail.isEmpty ? '$ts\t$event\n' : '$ts\t$event\t$detail\n';
      await _file!.writeAsString(line, mode: FileMode.append, flush: false);
      // ignore: avoid_print
      print('[TimeProof] $event ${detail.isEmpty ? '' : '- $detail'}');
    } catch (_) {
      /* abaikan */
    }
  }

  /// Hapus baris log lebih tua dari [K.logRetentionDays].
  Future<void> _prune() async {
    if (_file == null) return;
    try {
      if (!await _file!.exists()) return;
      final cutoff = DateTime.now().subtract(
        const Duration(days: K.logRetentionDays),
      );
      final lines = await _file!.readAsLines();
      final kept = <String>[];
      for (final line in lines) {
        final tab = line.indexOf('\t');
        if (tab <= 0) continue;
        final ts = DateTime.tryParse(line.substring(0, tab));
        if (ts == null || ts.isAfter(cutoff)) kept.add(line);
      }
      await _file!.writeAsString(kept.isEmpty ? '' : '${kept.join('\n')}\n');
    } catch (_) {
      /* abaikan */
    }
  }

  Future<String> readAll() async {
    try {
      if (_file != null && await _file!.exists()) {
        return await _file!.readAsString();
      }
    } catch (_) {/* abaikan */}
    return '';
  }
}
