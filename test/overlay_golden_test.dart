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
/// gaya watermark Kamera/Akurat, ukuran watermark independen, Remove Watermark,
/// header Radjak "Layout B") secara deterministik tanpa kamera/emulator.

Future<void> _loadFont(String family, String path) async {
  final bytes = File(path).readAsBytesSync();
  final loader = FontLoader(family)
    ..addFont(Future<ByteData>.value(
        ByteData.view(Uint8List.fromList(bytes).buffer)));
  await loader.load();
}

/// Pump [widget] lalu precache semua [Image] (mis. logo Radjak) agar
/// ter-render sebelum golden snapshot diambil.
Future<void> _pumpAndPrecache(WidgetTester tester, Widget widget) async {
  await tester.runAsync(() async {
    await tester.pumpWidget(widget);
    for (final e in find.byType(Image).evaluate()) {
      final img = e.widget as Image;
      await precacheImage(img.image, e);
    }
  });
  await tester.pumpAndSettle();
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

  Widget frame(CaptureData d, OverlaySettings s) => MaterialApp(
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
                  TimemarkOverlay(data: d, settings: s),
                ],
              ),
            ),
          ),
        ),
      );

  testWidgets('A: gaya Kamera (default)', (t) async {
    await _pumpAndPrecache(t, frame(data, const OverlaySettings()));
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/overlay_kamera.png'));
  });

  testWidgets('B: gaya Akurat + watermark BESAR + info KECIL', (t) async {
    await _pumpAndPrecache(
      t,
      frame(
        data,
        const OverlaySettings(
          watermarkStyle: WatermarkStyle.akurat,
          brandSize: FontSizeOption.xlarge,
          fontSize: FontSizeOption.small,
          verifiedSize: FontSizeOption.small,
        ),
      ),
    );
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/overlay_akurat.png'));
  });

  testWidgets('C: Remove Watermark (kanan-atas hilang)', (t) async {
    await _pumpAndPrecache(
        t, frame(data, const OverlaySettings(showWatermark: false)));
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/overlay_nowm.png'));
  });

  testWidgets('D: Layout B Radjak (header + visit info + tracking)',
      (t) async {
    const settings = OverlaySettings(
      staffName: 'Budi S.',
      showHeader: true,
      showVisitInfo: true,
    );
    final layoutBData = CaptureData(
      rawImagePath: '',
      latitude: -6.185037,
      longitude: 106.863431,
      accuracy: 5,
      address: 'Jl. Salemba Raya No.1, Jakarta Pusat, DKI Jakarta',
      timestampMs: DateTime(2026, 6, 11, 14, 32).millisecondsSinceEpoch,
      verificationCode: 'PDMM1DM1YHEYRG',
      locationAvailable: true,
      facility: 'RS Mitra Keluarga',
      visitType: 'Sales Visit',
      trackingNumber: 'TP-2026-000017',
    );

    await _pumpAndPrecache(t, frame(layoutBData, settings));
    await expectLater(find.byType(TimemarkOverlay),
        matchesGoldenFile('goldens/radjak_layout_b.png'));
  });
}
