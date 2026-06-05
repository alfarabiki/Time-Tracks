import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timeproof/models/capture_data.dart';
import 'package:timeproof/models/overlay_settings.dart';
import 'package:timeproof/widgets/timemark_overlay.dart';

/// Render-test untuk memverifikasi tampilan overlay (transparansi "Kode Foto",
/// gaya watermark Kamera/Akurat, ukuran watermark independen, Remove Watermark)
/// secara deterministik tanpa kamera/emulator.

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(
        ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
    await _loadFont('Roboto', 'assets/fonts/Roboto.ttf');
  });

  final data = CaptureData(
    rawImagePath: '',
    latitude: -6.184983,
    longitude: 106.863437,
    accuracy: 5,
    address:
        'Gg. S No.7, RT.4/RW.13, Cemp. Putih Bar., Kec. Cemp. Putih, Kota Jakarta Pusat, DKI Jakarta 10520',
    timestampMs: DateTime(2026, 6, 5, 18, 37).millisecondsSinceEpoch,
    verificationCode: 'RCTU9LT3L3EDD4',
    locationAvailable: true,
  );

  Widget frame(OverlaySettings s) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              height: 480,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFF4A4A4A)),
                  TimemarkOverlay(data: data, settings: s),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('A: gaya Kamera (default)', (t) async {
    await t.pumpWidget(frame(const OverlaySettings()));
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/overlay_kamera.png'));
  });

  testWidgets('B: gaya Akurat + watermark BESAR + info KECIL', (t) async {
    await t.pumpWidget(frame(const OverlaySettings(
      watermarkStyle: WatermarkStyle.akurat,
      brandSize: FontSizeOption.xlarge,
      fontSize: FontSizeOption.small,
      verifiedSize: FontSizeOption.small,
    )));
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/overlay_akurat.png'));
  });

  testWidgets('C: Remove Watermark (kanan-atas hilang)', (t) async {
    await t.pumpWidget(frame(const OverlaySettings(showWatermark: false)));
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/overlay_nowm.png'));
  });
}
