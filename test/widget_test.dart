import 'package:flutter_test/flutter_test.dart';
import 'package:timeproof/services/verification_service.dart';

void main() {
  test('verification code: 14 karakter alfanumerik kapital', () {
    final code = VerificationService.generate();
    expect(code.length, 14);
    expect(RegExp(r'^[A-Z0-9]+$').hasMatch(code), isTrue);
  });

  test('verification code unik antar pemanggilan', () {
    final a = VerificationService.generate();
    final b = VerificationService.generate();
    expect(a == b, isFalse);
  });
}
