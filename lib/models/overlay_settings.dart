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
