import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:timeproof/models/photo_record.dart';
import 'package:timeproof/services/database_service.dart';

PhotoRecord rec(String id, DateTime t) => PhotoRecord(
      id: id,
      imagePath: '/x.jpg',
      address: '',
      latitude: 0,
      longitude: 0,
      accuracy: 0,
      timestamp: t,
      verificationCode: id,
      customText: '',
      imageHash: 'H',
      trackingNumber: 'TP-x',
    );

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('countToday / countThisMonth / recent', () async {
    final now = DateTime(2026, 6, 12, 9);
    await DatabaseService.instance.debugReset();
    await DatabaseService.instance.insert(rec('a', now));
    await DatabaseService.instance.insert(rec('b', now.subtract(const Duration(days: 1))));
    await DatabaseService.instance.insert(rec('c', DateTime(2026, 5, 30)));

    expect(await DatabaseService.instance.countToday(now: now), 1);
    expect(await DatabaseService.instance.countThisMonth(now: now), 2);
    final r = await DatabaseService.instance.recent(2);
    expect(r.length, 2);
    expect(r.first.id, 'a');
  });
}
