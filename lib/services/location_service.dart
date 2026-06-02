import 'package:geolocator/geolocator.dart';

import 'log_service.dart';
import '../utils/constants.dart';

enum LocationErrorType {
  serviceDisabled,
  permissionDenied,
  permissionDeniedForever,
  timeout,
  unknown,
}

/// Hasil permintaan lokasi. Tidak pernah melempar — selalu dibungkus.
class LocationResult {
  final Position? position;
  final LocationErrorType? error;

  const LocationResult.success(this.position) : error = null;
  const LocationResult.failure(this.error) : position = null;

  bool get ok => position != null;

  String get message {
    switch (error) {
      case LocationErrorType.serviceDisabled:
        return 'GPS sedang nonaktif. Aktifkan lokasi atau pilih lokasi manual.';
      case LocationErrorType.permissionDenied:
        return 'Izin lokasi ditolak. Berikan izin atau pilih lokasi manual.';
      case LocationErrorType.permissionDeniedForever:
        return 'Izin lokasi diblokir permanen. Aktifkan lewat Pengaturan aplikasi.';
      case LocationErrorType.timeout:
        return 'Tidak dapat memperoleh lokasi.\nSilakan pilih lokasi manual.';
      default:
        return 'Lokasi tidak ditemukan. Silakan coba lagi.';
    }
  }
}

/// Layanan GPS (Feature 3). GPS hanya aktif saat diperlukan (hemat baterai —
/// tanpa continuous tracking).
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<LocationResult> getCurrent() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return const LocationResult.failure(LocationErrorType.serviceDisabled);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        return const LocationResult.failure(LocationErrorType.permissionDenied);
      }
      if (permission == LocationPermission.deniedForever) {
        return const LocationResult.failure(
          LocationErrorType.permissionDeniedForever,
        );
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: K.gpsTimeout, // 15 detik, lalu lempar TimeoutException
        ),
      );
      await LogService.instance.log(
        'GPS Acquired',
        detail: '${pos.latitude},${pos.longitude} ±${pos.accuracy}m',
      );
      return LocationResult.success(pos);
    } on Exception catch (e) {
      // TimeoutException atau LocationServiceDisabledException, dll.
      final isTimeout = e.toString().toLowerCase().contains('time');
      await LogService.instance.log('GPS Failed', detail: e.toString());
      return LocationResult.failure(
        isTimeout ? LocationErrorType.timeout : LocationErrorType.unknown,
      );
    } catch (_) {
      return const LocationResult.failure(LocationErrorType.unknown);
    }
  }

  Future<void> openAppSettings() async {
    try {
      await Geolocator.openAppSettings();
    } catch (_) {/* abaikan */}
  }

  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (_) {/* abaikan */}
  }
}
