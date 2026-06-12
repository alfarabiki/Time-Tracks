import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeproof/models/photo_record.dart';
import 'package:timeproof/services/database_service.dart';
import 'package:timeproof/services/settings_service.dart';
import 'package:timeproof/screens/home/home_screen.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit(); databaseFactory = databaseFactoryFfi;
    await initializeDateFormatting('id_ID', null);
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('dashboard shows CTA + recent visit', (t) async {
    // DatabaseService/SharedPreferences use real async I/O (sqflite_common_ffi
    // isolate + platform channels), which must run via runAsync — the
    // fake-async zone used by pump() never drives that real event loop.
    await t.runAsync(() => DatabaseService.instance.debugReset());
    await t.runAsync(() => SettingsService.instance.load());
    await t.runAsync(() => DatabaseService.instance.insert(PhotoRecord(id: 'a', imagePath: '/x.jpg', address: '',
      latitude: 0, longitude: 0, accuracy: 0, timestamp: DateTime.now(), verificationCode: 'a',
      customText: '', imageHash: 'H', facility: 'RS Mitra Keluarga', visitType: 'Sales Visit',
      trackingNumber: 'TP-2026-000017')));
    await t.pumpWidget(const MaterialApp(home: Scaffold(body: HomeScreen())));
    // HomeScreen.initState kicks off an async _load() (also real I/O). Give
    // it a few real-event-loop turns to resolve and rebuild via setState.
    for (var i = 0; i < 10; i++) {
      await t.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    expect(find.text('Mulai Kunjungan'), findsOneWidget);
    expect(find.text('RS Mitra Keluarga'), findsOneWidget);
    expect(find.text('TP-2026-000017'), findsOneWidget);
  });
}
