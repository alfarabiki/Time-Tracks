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
}
