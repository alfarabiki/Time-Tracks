import 'package:gal/gal.dart';

import '../utils/constants.dart';
import 'log_service.dart';

/// Simpan foto ke galeri pada album /DCIM/TimeProof (Feature: Export).
/// Mendukung scoped storage Android 10+ (tanpa izin) & izin WRITE utk <= 9.
class GalleryService {
  GalleryService._();
  static final GalleryService instance = GalleryService._();

  /// Simpan file [path] ke galeri. Mengembalikan true bila berhasil.
  Future<bool> saveToGallery(String path) async {
    try {
      final hasAccess = await Gal.hasAccess(toAlbum: true);
      if (!hasAccess) {
        final granted = await Gal.requestAccess(toAlbum: true);
        if (!granted) {
          await LogService.instance.log('Gallery Access Denied');
          return false;
        }
      }
      await Gal.putImage(path, album: K.galleryAlbum);
      await LogService.instance.log('Saved To Gallery', detail: path);
      return true;
    } catch (e) {
      // GalException (mis. akses ditolak) — jangan crash.
      await LogService.instance.log('Gallery Save Failed', detail: e.toString());
      return false;
    }
  }
}
