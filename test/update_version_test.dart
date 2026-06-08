import 'package:flutter_test/flutter_test.dart';
import 'package:timeproof/services/update_service.dart';

void main() {
  group('UpdateService.compareVersion', () {
    test('versi lebih baru terdeteksi', () {
      expect(UpdateService.compareVersion('1.3.0', '1.2.2'), greaterThan(0));
      expect(UpdateService.compareVersion('1.2.10', '1.2.9'), greaterThan(0));
      expect(UpdateService.compareVersion('2.0.0', '1.9.9'), greaterThan(0));
    });

    test('versi sama = 0', () {
      expect(UpdateService.compareVersion('1.2.2', '1.2.2'), 0);
      expect(UpdateService.compareVersion('v1.2.2', '1.2.2'), 0);
      expect(UpdateService.compareVersion('1.3.0+5', '1.3.0'), 0);
    });

    test('versi lebih lama negatif', () {
      expect(UpdateService.compareVersion('1.2.2', '1.3.0'), lessThan(0));
      expect(UpdateService.compareVersion('1.0.0', '1.0.1'), lessThan(0));
    });

    test('toleran prefix v & metadata build', () {
      expect(UpdateService.compareVersion('v1.3.0', 'v1.2.2'), greaterThan(0));
      expect(UpdateService.compareVersion('1.3.0+2008', '1.2.2+2007'),
          greaterThan(0));
    });
  });

  group('UpdateService.selectApkAssetName', () {
    const assets = [
      'TimeProof-arm64-v8a.apk',
      'TimeProof-armeabi-v7a.apk',
      'TimeProof-x86_64.apk',
      'TimeProof-universal.apk',
    ];

    test('arm64 device -> arm64 APK (BUKAN universal)', () {
      final r = UpdateService.selectApkAssetName(
          ['arm64-v8a', 'armeabi-v7a'], assets);
      expect(r, 'TimeProof-arm64-v8a.apk');
    });

    test('perangkat 32-bit -> armeabi-v7a', () {
      final r = UpdateService.selectApkAssetName(['armeabi-v7a'], assets);
      expect(r, 'TimeProof-armeabi-v7a.apk');
    });

    test('emulator x86_64 -> x86_64', () {
      final r =
          UpdateService.selectApkAssetName(['x86_64', 'arm64-v8a'], assets);
      // arm64 didahulukan bila tersedia (perangkat x86_64 modern juga jalankan arm64 via terjemahan? tidak) -
      // di sini x86_64 murni:
      final r2 = UpdateService.selectApkAssetName(['x86_64'], assets);
      expect(r2, 'TimeProof-x86_64.apk');
      expect(r, 'TimeProof-arm64-v8a.apk'); // arm64 hadir -> diutamakan
    });

    test('ABI tak dikenal/kosong -> fallback arm64 lalu universal', () {
      expect(UpdateService.selectApkAssetName([], assets),
          'TimeProof-arm64-v8a.apk');
      expect(
        UpdateService.selectApkAssetName([], ['TimeProof-universal.apk']),
        'TimeProof-universal.apk',
      );
    });
  });
}
