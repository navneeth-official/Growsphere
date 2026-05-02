import 'package:flutter_test/flutter_test.dart';
import 'package:growspehere_v1/core/services/care_timing_service.dart';

void main() {
  test('perfect timing in morning window with empty log', () {
    final now = DateTime(2024, 5, 1, 7, 20);
    expect(
      CareTimingService.evaluate(now: now, waterLog: [], wateringLevel: 'medium'),
      WaterFeedback.perfect,
    );
  });

  test('overwatering when last water too recent', () {
    final last = DateTime(2024, 5, 1, 7, 0);
    final now = DateTime(2024, 5, 1, 8, 0);
    expect(
      CareTimingService.evaluate(now: now, waterLog: [last], wateringLevel: 'high'),
      WaterFeedback.overwatering,
    );
  });
}
