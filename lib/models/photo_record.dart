/// Satu baris riwayat foto (tabel photo_history).
class PhotoRecord {
  final String id;
  final String imagePath;
  final String address;
  final double latitude;
  final double longitude;
  final double accuracy; // meter, akurasi GPS saat foto diambil
  final DateTime timestamp;
  final String verificationCode;
  final String customText;
  final String imageHash; // SHA256 untuk integritas (anti-ubah)
  final String staffName;
  final String facility;
  final String visitType;
  final String trackingNumber;

  const PhotoRecord({
    required this.id,
    required this.imagePath,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
    required this.verificationCode,
    required this.customText,
    required this.imageHash,
    this.staffName = '',
    this.facility = '',
    this.visitType = '',
    this.trackingNumber = '',
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'image_path': imagePath,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'verification_code': verificationCode,
      'custom_text': customText,
      'image_hash': imageHash,
      'staff_name': staffName,
      'facility': facility,
      'visit_type': visitType,
      'tracking_number': trackingNumber,
    };
  }

  factory PhotoRecord.fromMap(Map<String, Object?> map) {
    return PhotoRecord(
      id: (map['id'] ?? '') as String,
      imagePath: (map['image_path'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      latitude: ((map['latitude'] ?? 0) as num).toDouble(),
      longitude: ((map['longitude'] ?? 0) as num).toDouble(),
      accuracy: ((map['accuracy'] ?? 0) as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        ((map['timestamp'] ?? 0) as num).toInt(),
      ),
      verificationCode: (map['verification_code'] ?? '') as String,
      customText: (map['custom_text'] ?? '') as String,
      imageHash: (map['image_hash'] ?? '') as String,
      staffName: (map['staff_name'] ?? '') as String,
      facility: (map['facility'] ?? '') as String,
      visitType: (map['visit_type'] ?? '') as String,
      trackingNumber: (map['tracking_number'] ?? '') as String,
    );
  }
}
