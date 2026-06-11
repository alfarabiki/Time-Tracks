import 'package:flutter_test/flutter_test.dart';
import 'package:timeproof/services/tracking_service.dart';

void main() {
  group('TrackingService.format', () {
    test('zero-pads to 6 digits with year', () {
      expect(TrackingService.format(2026, 17), 'TP-2026-000017');
      expect(TrackingService.format(2026, 1), 'TP-2026-000001');
      expect(TrackingService.format(2026, 123456), 'TP-2026-123456');
    });
  });

  group('TrackingService.nextSeq (pure increment)', () {
    test('first of a fresh year starts at 1', () {
      final r = TrackingService.nextSeq(storedYear: 0, storedSeq: 0, currentYear: 2026);
      expect(r.year, 2026);
      expect(r.seq, 1);
    });

    test('same year increments', () {
      final r = TrackingService.nextSeq(storedYear: 2026, storedSeq: 17, currentYear: 2026);
      expect(r.year, 2026);
      expect(r.seq, 18);
    });

    test('new year resets to 1', () {
      final r = TrackingService.nextSeq(storedYear: 2026, storedSeq: 999, currentYear: 2027);
      expect(r.year, 2027);
      expect(r.seq, 1);
    });
  });
}
