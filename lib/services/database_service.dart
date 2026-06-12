import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/photo_record.dart';
import 'log_service.dart';

/// Penyimpanan lokal riwayat foto (tabel photo_history).
/// Offline penuh — tidak butuh backend.
class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();

  static const String _table = 'photo_history';
  Database? _db;

  Future<Database> get _database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dbDir = await getDatabasesPath();
    final path = p.join(dbDir, 'timeproof.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_table(
            id TEXT PRIMARY KEY,
            image_path TEXT NOT NULL,
            address TEXT,
            latitude REAL,
            longitude REAL,
            accuracy REAL,
            timestamp INTEGER NOT NULL,
            verification_code TEXT,
            custom_text TEXT,
            image_hash TEXT,
            staff_name TEXT,
            facility TEXT,
            visit_type TEXT,
            tracking_number TEXT
          )
        ''');
        // Index untuk history cepat (target < 1 detik utk ribuan data).
        await db.execute(
          'CREATE INDEX idx_timestamp ON $_table(timestamp DESC)',
        );
      },
      onUpgrade: (db, oldV, newV) async {
        if (oldV < 2) {
          for (final col in const [
            'staff_name',
            'facility',
            'visit_type',
            'tracking_number',
          ]) {
            try {
              await db.execute('ALTER TABLE $_table ADD COLUMN $col TEXT');
            } catch (_) {
              // kolom mungkin sudah ada — aman diabaikan
            }
          }
        }
      },
    );
  }

  Future<void> insert(PhotoRecord record) async {
    try {
      final db = await _database;
      await db.insert(
        _table,
        record.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      await LogService.instance.log('DB Insert Failed', detail: e.toString());
      rethrow;
    }
  }

  Future<List<PhotoRecord>> getAll() async {
    try {
      final db = await _database;
      final rows = await db.query(_table, orderBy: 'timestamp DESC');
      return rows.map(PhotoRecord.fromMap).toList();
    } catch (e) {
      await LogService.instance.log('DB Query Failed', detail: e.toString());
      return <PhotoRecord>[];
    }
  }

  Future<int> count() async {
    try {
      final db = await _database;
      final r = await db.rawQuery('SELECT COUNT(*) AS c FROM $_table');
      return (r.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> delete(String id) async {
    try {
      final db = await _database;
      await db.delete(_table, where: 'id = ?', whereArgs: [id]);
    } catch (e) {
      await LogService.instance.log('DB Delete Failed', detail: e.toString());
    }
  }

  Future<int> countToday({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day).millisecondsSinceEpoch;
    final end = start + const Duration(days: 1).inMilliseconds;
    return _countBetween(start, end);
  }

  Future<int> countThisMonth({DateTime? now}) async {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, 1).millisecondsSinceEpoch;
    final end = DateTime(n.year, n.month + 1, 1).millisecondsSinceEpoch;
    return _countBetween(start, end);
  }

  Future<int> _countBetween(int startMs, int endMs) async {
    try {
      final db = await _database;
      final r = await db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_table WHERE timestamp >= ? AND timestamp < ?',
        [startMs, endMs],
      );
      return (r.first['c'] as int?) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<PhotoRecord>> recent(int n) async {
    try {
      final db = await _database;
      final rows = await db.query(_table, orderBy: 'timestamp DESC', limit: n);
      return rows.map(PhotoRecord.fromMap).toList();
    } catch (_) {
      return <PhotoRecord>[];
    }
  }

  /// Khusus test: kosongkan tabel agar fresh.
  Future<void> debugReset() async {
    try {
      await (await _database).delete(_table);
    } catch (_) {}
  }
}
