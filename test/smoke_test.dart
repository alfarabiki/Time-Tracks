import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:timeproof/models/capture_data.dart';
import 'package:timeproof/models/overlay_settings.dart';
import 'package:timeproof/models/photo_record.dart';
import 'package:timeproof/services/settings_service.dart';
import 'package:timeproof/utils/format_utils.dart';
import 'package:timeproof/widgets/timemark_overlay.dart';

/// Data contoh meniru foto referensi Timemark.
CaptureData sampleCapture() => CaptureData(
      rawImagePath: '',
      latitude: -6.185037,
      longitude: 106.863431,
      accuracy: 5,
      address:
          'Gg. S No.7, RT.4/RW.13, Cemp. Putih Bar., Kec. Cemp. Putih, Kota Jakarta Pusat, Daerah Khusus Ibukota Jakarta 10520',
      timestampMs: DateTime(2026, 6, 2, 22, 21).millisecondsSinceEpoch,
      verificationCode: 'PDMM1DM1YHEYRG',
      locationAvailable: true,
    );

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Unit — format', () {
    test('tanggal Indonesia', () {
      final s = FormatUtils.fullDate(DateTime(2026, 6, 2, 22, 21));
      expect(s, 'Selasa, 02 Juni 2026 22:21');
    });

    test('koordinat S/E', () {
      expect(FormatUtils.coordinates(-6.185037, 106.863431),
          '6.185037°S, 106.863431°E');
    });

    test('akurasi', () {
      expect(FormatUtils.accuracy(5), 'Akurasi: 5 m');
    });
  });

  group('Unit — model round-trip', () {
    test('OverlaySettings encode/decode', () {
      const s = OverlaySettings(
        customText: 'Sales Visit',
        template: OverlayTemplate.b,
        imageQuality: ImageQuality.high,
      );
      final back = OverlaySettings.decode(s.encode());
      expect(back.customText, 'Sales Visit');
      expect(back.template, OverlayTemplate.b);
      expect(back.imageQuality, ImageQuality.high);
      expect(back.brandName, 'Radjak');
    });

    test('PhotoRecord toMap/fromMap', () {
      final r = PhotoRecord(
        id: 'ABC123',
        imagePath: '/x/y.jpg',
        address: 'Jl. Test',
        latitude: -6.1,
        longitude: 106.8,
        accuracy: 7,
        timestamp: DateTime(2026, 6, 2, 22, 21),
        verificationCode: 'ABC123',
        customText: 'Audit',
        imageHash: 'DEADBEEF',
      );
      final back = PhotoRecord.fromMap(r.toMap());
      expect(back.id, 'ABC123');
      expect(back.latitude, -6.1);
      expect(back.imageHash, 'DEADBEEF');
      expect(back.timestamp, r.timestamp);
    });

    test('CaptureData encode/decode', () {
      final c = sampleCapture();
      final back = CaptureData.decode(c.encode())!;
      expect(back.verificationCode, 'PDMM1DM1YHEYRG');
      expect(back.locationAvailable, isTrue);
      expect(back.latitude, -6.185037);
    });
  });

  group('Widget — overlay Timemark', () {
    testWidgets('menampilkan semua elemen template', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 1200,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFBFA38C)),
                  TimemarkOverlay(
                    data: sampleCapture(),
                    // showVerification kini default false (MVP Radjak pakai
                    // nomor tracking); aktifkan eksplisit agar tes "semua
                    // elemen template" tetap memverifikasi kode verifikasi.
                    settings: const OverlaySettings(showVerification: true),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Brand + sub (Radjak)
      expect(find.text('Radjak'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
      // Waktu
      expect(find.text('Selasa, 02 Juni 2026 22:21'), findsOneWidget);
      // Koordinat
      expect(find.text('6.185037°S, 106.863431°E'), findsOneWidget);
      // Kode verifikasi (teks vertikal)
      expect(find.textContaining('PDMM1DM1YHEYRG'), findsWidgets);
      // Alamat (wrap)
      expect(find.textContaining('Cemp. Putih'), findsOneWidget);
    });

    testWidgets('toggle off menyembunyikan koordinat & verifikasi',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 900,
              height: 1200,
              child: Stack(
                children: [
                  Container(color: const Color(0xFFBFA38C)),
                  TimemarkOverlay(
                    data: sampleCapture(),
                    settings: const OverlaySettings(
                      showCoordinate: false,
                      showVerification: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('6.185037°S, 106.863431°E'), findsNothing);
      expect(find.textContaining('Kode Foto'), findsNothing);
    });
  });

  group('Widget — settings persist', () {
    testWidgets('ubah custom text tersimpan ke prefs', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await SettingsService.instance.load();
      await SettingsService.instance.save(
        SettingsService.instance.current.copyWith(customText: 'Maintenance'),
      );
      final reloaded = await SettingsService.instance.load();
      expect(reloaded.customText, 'Maintenance');
    });
  });
}
