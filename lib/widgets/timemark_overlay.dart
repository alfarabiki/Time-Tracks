import 'package:flutter/material.dart';

import '../models/capture_data.dart';
import '../models/overlay_settings.dart';
import '../utils/format_utils.dart';

/// Overlay foto yang meniru template "Timemark" pada gambar contoh.
///
/// DINAMIS (Quality > Dynamic Layout): semua ukuran proporsional terhadap lebar
/// area foto, teks alamat otomatis WRAP (tidak terpotong), dan rapi pada layar
/// kecil, besar, maupun tablet. Tidak ada nilai yang di-hardcode dalam piksel.
class TimemarkOverlay extends StatelessWidget {
  final CaptureData data;
  final OverlaySettings settings;

  const TimemarkOverlay({
    super.key,
    required this.data,
    required this.settings,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        double s(double frac) => w * frac;

        final shadows = <Shadow>[
          Shadow(
            blurRadius: s(0.007),
            color: Colors.black.withOpacity(0.55),
            offset: Offset(s(0.0015), s(0.0018)),
          ),
        ];

        final fontScale = settings.fontSize.scale;
        TextStyle style(double frac, {FontWeight weight = FontWeight.w400}) {
          return TextStyle(
            color: Colors.white,
            fontSize: s(frac) * fontScale,
            fontWeight: weight,
            height: 1.25,
            shadows: shadows,
            // Font di-bundle (assets/fonts) agar konsisten di semua HP.
            fontFamily: settings.fontFamily,
          );
        }

        final code = data.verificationCode;

        return Stack(
          children: [
            // ===== TOP-RIGHT: Watermark (brand + sub-label) =====
            // Ukuran independen (brandSize) & bisa dimatikan ("Remove Watermark").
            if (settings.showWatermark)
              Positioned(
                top: s(0.03),
                right: s(0.035),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _brand(s, shadows),
                    Padding(
                      padding: EdgeInsets.only(top: s(0.004)),
                      child: Text(
                        settings.watermarkStyle.sublabel,
                        style: style(0.032).copyWith(
                          fontSize: s(0.032) * settings.brandSize.scale,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ===== RIGHT EDGE: Verified vertikal =====
            // Ukuran label "Verified" independen dari fontSize global
            // (pakai verifiedSize), agar bisa dikecil/besarkan sendiri.
            if (settings.showVerification)
              Positioned(
                top: 0,
                bottom: 0,
                right: s(0.012),
                child: Center(
                  child: RotatedBox(
                    quarterTurns: 3,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: s(0.030) * settings.verifiedSize.scale,
                          color: Colors.white.withOpacity(0.9),
                          shadows: shadows,
                        ),
                        SizedBox(width: s(0.012)),
                        Flexible(
                          child: Text(
                            '$code   ${settings.verifiedLabel}',
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: style(0.024).copyWith(
                              fontSize: s(0.024) * settings.verifiedSize.scale,
                              color: Colors.white.withOpacity(0.92),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // ===== BOTTOM-LEFT: Info block =====
            Positioned(
              left: s(0.04),
              right: s(0.11),
              bottom: s(0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Amber accent bar
                        Container(
                          width: s(0.009),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5A623),
                            borderRadius: BorderRadius.circular(s(0.006)),
                          ),
                        ),
                        SizedBox(width: s(0.028)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: _infoLines(context, s, style),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Divider + Kode Foto
                  if (settings.showVerification) ...[
                    SizedBox(height: s(0.028)),
                    Container(
                      height: s(0.003),
                      width: s(0.46),
                      color: Colors.white.withOpacity(0.45),
                    ),
                    SizedBox(height: s(0.022)),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          size: s(0.040),
                          color: Colors.white.withOpacity(0.6),
                          shadows: shadows,
                        ),
                        SizedBox(width: s(0.020)),
                        Flexible(
                          // Wording "Kode Foto" semi-transparan (mengikuti contoh).
                          child: RichText(
                            text: TextSpan(
                              style: style(0.034).copyWith(
                                color: Colors.white.withOpacity(0.62),
                              ),
                              children: [
                                const TextSpan(text: 'Kode Foto: '),
                                TextSpan(
                                  text: code,
                                  style: style(0.034, weight: FontWeight.w700)
                                      .copyWith(
                                    color: Colors.white.withOpacity(0.82),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Brand watermark kanan-atas. Bila gaya dwiwarna, bagian "mark" diberi aksen.
  Widget _brand(double Function(double) s, List<Shadow> shadows) {
    final scale = settings.brandSize.scale;
    final base = TextStyle(
      color: Colors.white,
      fontSize: s(0.050) * scale,
      fontWeight: FontWeight.w700,
      height: 1.05,
      shadows: shadows,
      fontFamily: settings.fontFamily,
    );
    final name = settings.brandName;
    final idx = settings.watermarkStyle.twoTone
        ? name.toLowerCase().lastIndexOf('mark')
        : -1;
    if (idx < 0) return Text(name, style: base);
    return RichText(
      textAlign: TextAlign.end,
      text: TextSpan(
        style: base,
        children: [
          // "Time" (sebelum "mark") = kuning, "mark" & sisanya = putih.
          TextSpan(
            text: name.substring(0, idx),
            style: const TextStyle(color: Color(0xFFF5A623)),
          ),
          TextSpan(text: name.substring(idx, idx + 4)),
          TextSpan(text: name.substring(idx + 4)),
        ],
      ),
    );
  }

  /// Baris info di dalam block (urutan mengikuti template terpilih).
  List<Widget> _infoLines(
    BuildContext context,
    double Function(double) s,
    TextStyle Function(double, {FontWeight weight}) style,
  ) {
    final lines = <Widget>[];
    void gap() => lines.add(SizedBox(height: s(0.022)));

    // Custom text (judul) — bila aktif & terisi.
    if (settings.showCustomText && settings.customText.trim().isNotEmpty) {
      lines.add(Text(
        settings.customText.trim(),
        style: style(0.042, weight: FontWeight.w700),
      ));
      gap();
    }

    // Waktu
    if (settings.showTime) {
      lines.add(Text(
        FormatUtils.fullDate(data.timestamp),
        style: style(0.038, weight: FontWeight.w500),
      ));
    }

    // Nama pegawai (Template B)
    if (settings.template == OverlayTemplate.b &&
        settings.employeeName.trim().isNotEmpty) {
      gap();
      lines.add(Text(settings.employeeName.trim(), style: style(0.035)));
    }

    // Alamat (WRAP otomatis, max 4 baris agar rapi)
    if (settings.showAddress && data.address.trim().isNotEmpty) {
      if (lines.isNotEmpty) gap();
      lines.add(Text(
        data.address.trim(),
        style: style(0.032),
        softWrap: true,
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ));
    } else if (settings.showAddress && !data.locationAvailable) {
      // Offline-first: tanpa internet, tampilkan info ringkas.
      if (lines.isNotEmpty) gap();
      lines.add(Text('Alamat tidak tersedia (offline)', style: style(0.030)));
    }

    // Koordinat
    if (settings.showCoordinate && data.locationAvailable) {
      if (lines.isNotEmpty) gap();
      lines.add(Text(
        FormatUtils.coordinates(data.latitude, data.longitude),
        style: style(0.036, weight: FontWeight.w500),
      ));
    }

    if (lines.isEmpty) {
      lines.add(Text(FormatUtils.fullDate(data.timestamp), style: style(0.038)));
    }
    return lines;
  }
}
