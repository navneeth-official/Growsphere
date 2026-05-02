import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/care_timing_service.dart';
import '../data/grow_storage.dart';
import '../domain/grow_enums.dart';
import '../domain/grow_session.dart';
import '../domain/grow_task.dart';
import '../domain/plant.dart';
import 'base_providers.dart';
import 'route_refresh.dart';

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class SessionController extends Notifier<GrowSession?> {
  GrowStorage get _storage => ref.read(growStorageProvider);
  RouteRefreshNotifier get _router => ref.read(routeRefreshProvider);

  @override
  GrowSession? build() => _storage.loadSessionSync();

  Future<void> _persist() async {
    await _storage.saveSession(state);
    _router.refresh();
  }

  /// Riverpod only notifies when [state] is replaced; session fields are often mutated in place.
  void _reEmitSession() {
    final s = state;
    if (s == null) return;
    state = GrowSession.fromJson(s.toJson());
  }

  Future<void> startGrow({
    required Plant plant,
    required GrowLocationType location,
    required SunlightLevel sunlight,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final rec = GrowSession.recommendationFor(
      wateringLevel: plant.wateringLevel,
      location: location,
      sun: sunlight,
    );
    state = GrowSession(
      plantId: plant.id,
      plantName: plant.name,
      difficulty: plant.difficulty,
      wateringLevel: plant.wateringLevel,
      climate: plant.climate,
      soil: plant.soil,
      fertilizers: plant.fertilizers,
      harvestDurationDays: plant.harvestDurationDays,
      nutrientHeavy: plant.nutrientHeavy,
      location: location,
      sunlight: sunlight,
      startedAt: start,
      tasks: GrowSession.generateTasks(start: start, harvestDays: plant.harvestDurationDays),
      waterLog: [],
      streak: 0,
      plantHealth: 85,
      streakByDay: {},
      earnedBadgeIds: [],
      wateringRecommendationText: rec,
    );
    await _persist();
  }

  Future<WaterFeedback> logWatered() async {
    final s = state;
    if (s == null) return WaterFeedback.suboptimal;
    final now = DateTime.now();
    final fb = CareTimingService.evaluate(
      now: now,
      waterLog: s.waterLog,
      wateringLevel: s.wateringLevel,
    );
    s.waterLog.add(now);
    switch (fb) {
      case WaterFeedback.perfect:
        s.streak += 1;
        s.plantHealth = (s.plantHealth + 6).clamp(0, 100);
        _awardBadges(s);
        break;
      case WaterFeedback.overwatering:
        s.streak = (s.streak - 2).clamp(0, 9999);
        s.plantHealth = (s.plantHealth - 14).clamp(0, 100);
        break;
      case WaterFeedback.missed:
        s.streak = (s.streak - 1).clamp(0, 9999);
        s.plantHealth = (s.plantHealth - 10).clamp(0, 100);
        break;
      case WaterFeedback.suboptimal:
        s.plantHealth = (s.plantHealth - 3).clamp(0, 100);
        break;
    }
    s.streakByDay[_dayKey(now)] = s.streak;
    _awardBadges(s);
    await _persist();
    _reEmitSession();
    return fb;
  }

  /// After manual sprinkler stop: update tasks / health; optionally log calendar "I watered".
  Future<WaterFeedback?> finishSprinklerSession({
    required bool overwatered,
    required int secondsWatered,
    required int idealSecondsMid,
    required bool logCareFromCalendar,
  }) async {
    final s = state;
    if (s == null) return null;
    if (overwatered && !logCareFromCalendar) {
      s.plantHealth = (s.plantHealth - 12).clamp(0, 100);
    } else if (!overwatered && secondsWatered >= (idealSecondsMid * 0.45).round()) {
      final today = DateTime.now();
      final todayD = DateTime(today.year, today.month, today.day);
      for (final t in s.tasks) {
        if (t.completed) continue;
        final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
        if (due != todayD) continue;
        final low = t.title.toLowerCase();
        if (low.contains('moist') ||
            low.contains('moisten') ||
            low.contains('watering') ||
            low.contains('water after') ||
            low.contains('water deeply')) {
          t.completed = true;
          t.completedAt = today;
        }
      }
    }
    WaterFeedback? fb;
    if (logCareFromCalendar) {
      if (overwatered || secondsWatered >= 25) {
        logWateredFromSprinkler(overwatered: overwatered);
        fb = overwatered ? WaterFeedback.overwatering : WaterFeedback.perfect;
      } else {
        fb = WaterFeedback.suboptimal;
      }
    } else {
      s.streakByDay[_dayKey(DateTime.now())] = s.streak;
    }
    _awardBadges(s);
    await _persist();
    _reEmitSession();
    return fb;
  }

  /// Calendar → sprinkler flow: mutates session; caller must persist.
  void logWateredFromSprinkler({required bool overwatered}) {
    final s = state;
    if (s == null) return;
    final now = DateTime.now();
    s.waterLog.add(now);
    if (overwatered) {
      s.streak = (s.streak - 2).clamp(0, 9999);
      s.plantHealth = (s.plantHealth - 14).clamp(0, 100);
    } else {
      s.streak += 1;
      s.plantHealth = (s.plantHealth + 6).clamp(0, 100);
    }
    s.streakByDay[_dayKey(now)] = s.streak;
  }

  void _awardBadges(GrowSession s) {
    void add(String id) {
      if (!s.earnedBadgeIds.contains(id)) s.earnedBadgeIds.add(id);
    }

    if (s.waterLog.isNotEmpty) add('badge_first_water');
    if (s.streak >= 7) add('badge_streak_7');
    if (s.streak >= 30) add('badge_streak_30');
    if (s.plantHealth >= 90) add('badge_thriving');
    final done = s.tasks.where((t) => t.completed).length;
    if (done >= 20) add('badge_task_master');
  }

  /// Returns streak multiplier message count (2 if double award).
  Future<int> completeTask(String taskId) async {
    final s = state;
    if (s == null) return 0;
    GrowTask? t;
    for (final x in s.tasks) {
      if (x.id == taskId) {
        t = x;
        break;
      }
    }
    if (t == null || t.completed) return 0;
    final today = DateTime.now();
    final due = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
    final todayD = DateTime(today.year, today.month, today.day);
    final onTime = due == todayD;
    t.completed = true;
    t.completedAt = today;
    var inc = 0;
    if (onTime) {
      inc = 2;
      s.streak += 2;
      s.plantHealth = (s.plantHealth + 4).clamp(0, 100);
    } else if (todayD.isBefore(due)) {
      inc = 1;
      s.streak += 1;
      s.plantHealth = (s.plantHealth + 2).clamp(0, 100);
    } else {
      s.plantHealth = (s.plantHealth - 5).clamp(0, 100);
    }
    s.streakByDay[_dayKey(today)] = s.streak;
    _awardBadges(s);
    await _persist();
    _reEmitSession();
    return inc;
  }

  Future<void> clearSession() async {
    state = null;
    await _storage.saveSession(null);
    _router.refresh();
  }
}
