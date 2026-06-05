import 'dart:convert';

/// Template overlay (CLAUDE.md Feature 7).
enum OverlayTemplate {
  /// Tanggal, Alamat, Koordinat, Kode (default — sama seperti contoh gambar).
  a,

  /// Tanggal, Nama Pegawai, Lokasi, Koordinat.
  b,

  /// Custom layout — sepenuhnya mengikuti toggle.
  c,
}

/// Kualitas JPEG hasil simpan (Quality > Image Quality).
enum ImageQuality {
  high(95),
  medium(90),
  low(80);

  final int jpegQuality;
  const ImageQuality(this.jpegQuality);
}

/// Ukuran font overlay (faktor skala terhadap default).
enum FontSizeOption {
  small(0.82, 'Kecil'),
  medium(1.0, 'Sedang'),
  large(1.22, 'Besar'),
  xlarge(1.45, 'Besar+');

  final double scale;
  final String label;
  const FontSizeOption(this.scale, this.label);
}

/// Jenis font overlay yang tersedia (di-bundle di assets/fonts).
const List<String> kOverlayFonts = ['Roboto', 'Inter', 'Montserrat', 'Oswald'];

/// Konfigurasi overlay + preferensi aplikasi. Disimpan via shared_preferences.
class OverlaySettings {
  final bool showTime;
  final bool showAddress;
  final bool showCoordinate;
  final bool showVerification;
  final bool showCustomText;

  final OverlayTemplate template;
  final String customText;
  final String employeeName;

  /// Branding pada overlay (default mengikuti contoh: "Timemark").
  final String brandName;
  final String cameraLabel;
  final String verifiedLabel;

  final ImageQuality imageQuality;

  /// Ukuran & jenis font overlay.
  final FontSizeOption fontSize;
  final String fontFamily;

  /// Ukuran khusus label "Verified" vertikal (kanan), independen dari fontSize.
  final FontSizeOption verifiedSize;

  const OverlaySettings({
    this.showTime = true,
    this.showAddress = true,
    this.showCoordinate = true,
    this.showVerification = true,
    this.showCustomText = true,
    this.template = OverlayTemplate.a,
    this.customText = '',
    this.employeeName = '',
    this.brandName = 'Timemark',
    this.cameraLabel = 'Kamera',
    this.verifiedLabel = 'Timemark Verified',
    this.imageQuality = ImageQuality.medium,
    this.fontSize = FontSizeOption.medium,
    this.fontFamily = 'Roboto',
    this.verifiedSize = FontSizeOption.medium,
  });

  OverlaySettings copyWith({
    bool? showTime,
    bool? showAddress,
    bool? showCoordinate,
    bool? showVerification,
    bool? showCustomText,
    OverlayTemplate? template,
    String? customText,
    String? employeeName,
    String? brandName,
    String? cameraLabel,
    String? verifiedLabel,
    ImageQuality? imageQuality,
    FontSizeOption? fontSize,
    String? fontFamily,
    FontSizeOption? verifiedSize,
  }) {
    return OverlaySettings(
      showTime: showTime ?? this.showTime,
      showAddress: showAddress ?? this.showAddress,
      showCoordinate: showCoordinate ?? this.showCoordinate,
      showVerification: showVerification ?? this.showVerification,
      showCustomText: showCustomText ?? this.showCustomText,
      template: template ?? this.template,
      customText: customText ?? this.customText,
      employeeName: employeeName ?? this.employeeName,
      brandName: brandName ?? this.brandName,
      cameraLabel: cameraLabel ?? this.cameraLabel,
      verifiedLabel: verifiedLabel ?? this.verifiedLabel,
      imageQuality: imageQuality ?? this.imageQuality,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      verifiedSize: verifiedSize ?? this.verifiedSize,
    );
  }

  Map<String, Object?> toJson() => {
        'showTime': showTime,
        'showAddress': showAddress,
        'showCoordinate': showCoordinate,
        'showVerification': showVerification,
        'showCustomText': showCustomText,
        'template': template.name,
        'customText': customText,
        'employeeName': employeeName,
        'brandName': brandName,
        'cameraLabel': cameraLabel,
        'verifiedLabel': verifiedLabel,
        'imageQuality': imageQuality.name,
        'fontSize': fontSize.name,
        'fontFamily': fontFamily,
        'verifiedSize': verifiedSize.name,
      };

  factory OverlaySettings.fromJson(Map<String, Object?> j) {
    return OverlaySettings(
      showTime: (j['showTime'] ?? true) as bool,
      showAddress: (j['showAddress'] ?? true) as bool,
      showCoordinate: (j['showCoordinate'] ?? true) as bool,
      showVerification: (j['showVerification'] ?? true) as bool,
      showCustomText: (j['showCustomText'] ?? true) as bool,
      template: OverlayTemplate.values.firstWhere(
        (t) => t.name == j['template'],
        orElse: () => OverlayTemplate.a,
      ),
      customText: (j['customText'] ?? '') as String,
      employeeName: (j['employeeName'] ?? '') as String,
      brandName: (j['brandName'] ?? 'Timemark') as String,
      cameraLabel: (j['cameraLabel'] ?? 'Kamera') as String,
      verifiedLabel: (j['verifiedLabel'] ?? 'Timemark Verified') as String,
      imageQuality: ImageQuality.values.firstWhere(
        (q) => q.name == j['imageQuality'],
        orElse: () => ImageQuality.medium,
      ),
      fontSize: FontSizeOption.values.firstWhere(
        (f) => f.name == j['fontSize'],
        orElse: () => FontSizeOption.medium,
      ),
      fontFamily: kOverlayFonts.contains(j['fontFamily'])
          ? j['fontFamily'] as String
          : 'Roboto',
      verifiedSize: FontSizeOption.values.firstWhere(
        (f) => f.name == j['verifiedSize'],
        orElse: () => FontSizeOption.medium,
      ),
    );
  }

  String encode() => jsonEncode(toJson());

  factory OverlaySettings.decode(String s) {
    try {
      return OverlaySettings.fromJson(jsonDecode(s) as Map<String, Object?>);
    } catch (_) {
      return const OverlaySettings();
    }
  }
}
