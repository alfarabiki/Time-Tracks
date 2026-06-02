import 'dart:convert';

/// Data sementara hasil pengambilan foto sebelum overlay difinalisasi & disimpan.
/// Dipakai juga sebagai DRAFT untuk recovery (Quality > Recovery Mechanism).
class CaptureData {
  final String rawImagePath;
  final double latitude;
  final double longitude;
  final double accuracy;
  final String address; // kosong jika offline / geocoding gagal
  final int timestampMs;
  final String verificationCode;
  final bool locationAvailable;

  const CaptureData({
    required this.rawImagePath,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.address,
    required this.timestampMs,
    required this.verificationCode,
    required this.locationAvailable,
  });

  DateTime get timestamp => DateTime.fromMillisecondsSinceEpoch(timestampMs);

  CaptureData copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    String? address,
    bool? locationAvailable,
  }) {
    return CaptureData(
      rawImagePath: rawImagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      address: address ?? this.address,
      timestampMs: timestampMs,
      verificationCode: verificationCode,
      locationAvailable: locationAvailable ?? this.locationAvailable,
    );
  }

  Map<String, Object?> toJson() => {
        'rawImagePath': rawImagePath,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'address': address,
        'timestampMs': timestampMs,
        'verificationCode': verificationCode,
        'locationAvailable': locationAvailable,
      };

  factory CaptureData.fromJson(Map<String, Object?> j) => CaptureData(
        rawImagePath: (j['rawImagePath'] ?? '') as String,
        latitude: ((j['latitude'] ?? 0) as num).toDouble(),
        longitude: ((j['longitude'] ?? 0) as num).toDouble(),
        accuracy: ((j['accuracy'] ?? 0) as num).toDouble(),
        address: (j['address'] ?? '') as String,
        timestampMs: ((j['timestampMs'] ?? 0) as num).toInt(),
        verificationCode: (j['verificationCode'] ?? '') as String,
        locationAvailable: (j['locationAvailable'] ?? false) as bool,
      );

  String encode() => jsonEncode(toJson());

  static CaptureData? decode(String? s) {
    if (s == null || s.isEmpty) return null;
    try {
      return CaptureData.fromJson(jsonDecode(s) as Map<String, Object?>);
    } catch (_) {
      return null;
    }
  }
}
