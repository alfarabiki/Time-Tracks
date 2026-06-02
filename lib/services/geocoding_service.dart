import 'package:geocoding/geocoding.dart';

import 'log_service.dart';

/// Reverse geocoding (Feature 4). Memakai geocoder bawaan Android (gratis).
/// OFFLINE-FIRST: jika gagal (internet mati), kembalikan string kosong dan
/// aplikasi cukup menampilkan koordinat saja.
class GeocodingService {
  GeocodingService._();
  static final GeocodingService instance = GeocodingService._();

  Future<String> getAddress(double lat, double lng) async {
    try {
      // localeIdentifier mengikuti locale perangkat (umumnya id_ID di Indonesia).
      final placemarks = await placemarkFromCoordinates(
        lat,
        lng,
      ).timeout(const Duration(seconds: 8));

      if (placemarks.isEmpty) return '';
      final pm = placemarks.first;

      // Susun gaya Indonesia, abaikan bagian kosong/duplikat.
      final parts = <String>[
        pm.street ?? '',
        pm.subLocality ?? '',
        pm.locality ?? '',
        pm.subAdministrativeArea ?? '',
        _withPostal(pm.administrativeArea ?? '', pm.postalCode ?? ''),
      ];

      final seen = <String>{};
      final cleaned = <String>[];
      for (final part in parts) {
        final t = part.trim();
        if (t.isEmpty) continue;
        if (seen.contains(t.toLowerCase())) continue;
        seen.add(t.toLowerCase());
        cleaned.add(t);
      }

      final address = cleaned.join(', ');
      await LogService.instance.log('Address Resolved', detail: address);
      return address;
    } catch (e) {
      // Internet mati / layanan tidak tersedia → koordinat saja.
      await LogService.instance.log('Geocoding Failed', detail: e.toString());
      return '';
    }
  }

  String _withPostal(String admin, String postal) {
    if (admin.trim().isEmpty) return postal.trim();
    if (postal.trim().isEmpty) return admin.trim();
    return '${admin.trim()} ${postal.trim()}';
  }
}
