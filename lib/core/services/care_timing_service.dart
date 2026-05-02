/// Rules for "I watered" feedback. Server-side validation can mirror this in Cloud Functions later.
enum WaterFeedback {
  perfect,
  overwatering,
  missed,
  suboptimal,
}

class CareTimingService {
  CareTimingService._();

  static const morningHour = 7;
  static const eveningHour = 17;
  static const windowMinutes = 90;

  static int minHoursBetweenWaters(String wateringLevel) {
    switch (wateringLevel.toLowerCase()) {
      case 'high':
        return 10;
      case 'low':
        return 36;
      default:
        return 20;
    }
  }

  static bool inIdealWindow(DateTime now) {
    return _nearHour(now, morningHour) || _nearHour(now, eveningHour);
  }

  static bool _nearHour(DateTime now, int hour) {
    final minutes = now.hour * 60 + now.minute;
    final center = hour * 60;
    return (minutes - center).abs() <= windowMinutes;
  }

  /// Evaluate a new water event at [now] given existing sorted [waterLog].
  static WaterFeedback evaluate({
    required DateTime now,
    required List<DateTime> waterLog,
    required String wateringLevel,
  }) {
    final minH = minHoursBetweenWaters(wateringLevel);
    if (waterLog.isNotEmpty) {
      final last = waterLog.last;
      final hours = now.difference(last).inHours;
      if (hours < minH) {
        return WaterFeedback.overwatering;
      }
    }
    if (inIdealWindow(now)) {
      return WaterFeedback.perfect;
    }
    if (waterLog.isNotEmpty) {
      final gap = now.difference(waterLog.last).inHours;
      if (gap > 48) {
        return WaterFeedback.missed;
      }
    }
    return WaterFeedback.suboptimal;
  }
}
