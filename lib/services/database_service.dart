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
      version: 1,
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
            image_hash TEXT
          )
        ''');
        // Index untuk history cepat (target < 1 detik utk ribuan data).
        await db.execute(
          'CREATE INDEX idx_timestamp ON $_table(timestamp DESC)',
        );
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
}
