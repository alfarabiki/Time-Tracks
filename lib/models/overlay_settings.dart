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

/// Gaya watermark kanan-atas (meniru Timemark).
/// - [kamera]: brand putih + sub-label "Kamera".
/// - [akurat]: brand dwiwarna ("mark" kuning) + sub-label "Foto 100% akurat".
enum WatermarkStyle {
  kamera('Kamera', false, 'Timemark Kamera'),
  akurat('Foto 100% akurat', true, 'Foto 100% akurat');

  /// Sub-label di bawah brand.
  final String sublabel;

  /// Apakah bagian "mark" pada brand diwarnai aksen (kuning).
  final bool twoTone;

  /// Label pilihan di layar Pengaturan.
  final String optionLabel;

  const WatermarkStyle(this.sublabel, this.twoTone, this.optionLabel);
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

  /// Ukuran & jenis font overlay.
  final FontSizeOption fontSize;
  final String fontFamily;

  /// Ukuran khusus label "Verified" vertikal (kanan), independen dari fontSize.
  final FontSizeOption verifiedSize;

  /// Watermark kanan-atas (brand + sub-label). Bisa dimatikan ("Remove Watermark").
  final bool showWatermark;

  /// Ukuran watermark kanan-atas, independen dari fontSize blok info.
  final FontSizeOption brandSize;

  /// Gaya watermark kanan-atas.
  final WatermarkStyle watermarkStyle;

  /// Nama staf/marketing (profil) — muncul otomatis di overlay.
  final String staffName;

  /// Tampilkan header Radjak di atas foto.
  final bool showHeader;

  /// Tampilkan baris info kunjungan (staf · jenis · faskes).
  final bool showVisitInfo;

  const OverlaySettings({
    this.showTime = true,
    this.showAddress = true,
    this.showCoordinate = true,
    this.showVerification = false,
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
    this.showWatermark = true,
    this.brandSize = FontSizeOption.medium,
    this.watermarkStyle = WatermarkStyle.kamera,
    this.staffName = '',
    this.showHeader = true,
    this.showVisitInfo = true,
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
    bool? showWatermark,
    FontSizeOption? brandSize,
    WatermarkStyle? watermarkStyle,
    String? staffName,
    bool? showHeader,
    bool? showVisitInfo,
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
      showWatermark: showWatermark ?? this.showWatermark,
      brandSize: brandSize ?? this.brandSize,
      watermarkStyle: watermarkStyle ?? this.watermarkStyle,
      staffName: staffName ?? this.staffName,
      showHeader: showHeader ?? this.showHeader,
      showVisitInfo: showVisitInfo ?? this.showVisitInfo,
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
        'showWatermark': showWatermark,
        'brandSize': brandSize.name,
        'watermarkStyle': watermarkStyle.name,
        'staffName': staffName,
        'showHeader': showHeader,
        'showVisitInfo': showVisitInfo,
      };

  factory OverlaySettings.fromJson(Map<String, Object?> j) {
    return OverlaySettings(
      showTime: (j['showTime'] ?? true) as bool,
      showAddress: (j['showAddress'] ?? true) as bool,
      showCoordinate: (j['showCoordinate'] ?? true) as bool,
      showVerification: (j['showVerification'] ?? false) as bool,
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
      showWatermark: (j['showWatermark'] ?? true) as bool,
      brandSize: FontSizeOption.values.firstWhere(
        (f) => f.name == j['brandSize'],
        orElse: () => FontSizeOption.medium,
      ),
      watermarkStyle: WatermarkStyle.values.firstWhere(
        (w) => w.name == j['watermarkStyle'],
        orElse: () => WatermarkStyle.kamera,
      ),
      staffName: (j['staffName'] ?? '') as String,
      showHeader: (j['showHeader'] ?? true) as bool,
      showVisitInfo: (j['showVisitInfo'] ?? true) as bool,
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
