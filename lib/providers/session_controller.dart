import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/farm_plan_bootstrap.dart';
import '../core/farm_plan_templates.dart';
import '../core/services/care_timing_service.dart';
import '../data/grow_storage.dart';
import '../domain/activity_stage.dart';
import '../domain/farm_plan_ai_result.dart';
import '../domain/grow_enums.dart';
import '../domain/grow_session.dart';
import '../domain/grow_task.dart';
import '../domain/plant.dart';
import 'base_providers.dart';
import 'route_refresh.dart';

String _dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _newGardenInstanceId(Plant plant) => 'g_${plant.id}_${DateTime.now().microsecondsSinceEpoch}';

class SessionController extends Notifier<GrowSession?> {
  GrowStorage get _storage => ref.read(growStorageProvider);
  RouteRefreshNotifier get _router => ref.read(routeRefreshProvider);

  @override
  GrowSession? build() => _storage.loadActiveSessionFromGarden();

  Future<void> _persist() async {
    final s = state;
    if (s == null) {
      await _storage.saveGardenList([]);
      await _storage.setActiveGardenInstanceId(null);
    } else {
      await _storage.mergeSessionIntoGardenList(s);
      await _storage.setActiveGardenInstanceId(s.gardenInstanceId);
    }
    ref.read(localDataRevisionProvider.notifier).state++;
    _router.refresh();
  }

  /// Riverpod only notifies when [state] is replaced; session fields are often mutated in place.
  void _reEmitSession() {
    final s = state;
    if (s == null) return;
    state = GrowSession.fromJson(s.toJson());
  }

  /// Adds a new plant to the garden list and makes it the active session (does not remove others).
  Future<void> addGardenPlant({
    required Plant plant,
    required GrowLocationType location,
    required SunlightLevel sunlight,
    required int farmPlanStartMonth1To12,
    required FarmPlanAiResult farmPlan,
  }) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final rec = GrowSession.recommendationFor(
      wateringLevel: plant.wateringLevel,
      location: location,
      sun: sunlight,
    );
    state = GrowSession(
      gardenInstanceId: _newGardenInstanceId(plant),
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
      tasks: farmPlan.tasks,
      waterLog: [],
      streak: 0,
      bestStreak: 0,
      lastStreakCreditDayKey: null,
      perfectStreakDayLog: [],
      plantHealth: 85,
      streakByDay: {},
      earnedBadgeIds: [],
      wateringRecommendationText: rec,
      farmPlanStartMonth: farmPlanStartMonth1To12.clamp(1, 12),
      farmPlanJson: farmPlan.serialize(),
    );
    await _persist();
  }

  /// Saves [plant] as a custom catalog entry, builds a template or AI farm plan, and appends a new garden grow.
  Future<void> addToolPlantToGarden(Plant plant) async {
    await _storage.addCustomPlant(plant);
    final month = DateTime.now().month;
    await _storage.setFarmPlanStartMonth(plant.id, month);
    FarmPlanAiResult raw;
    try {
      final repo = ref.read(geminiFarmPlanRepositoryProvider);
      raw = await FarmPlanBootstrap.loadOrBuild(
        repo: repo,
        plant: plant,
        farmStartMonth1To12: month,
        location: GrowLocationType.balcony,
        sunlight: SunlightLevel.medium,
      );
    } catch (e, st) {
      debugPrint('addToolPlantToGarden plan build failed, using template: $e\n$st');
      raw = FarmPlanTemplates.buildFallback(
        harvestDays: plant.harvestDurationDays.clamp(1, 999),
        plantName: plant.name,
      );
    }
    final start = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final plan = FarmPlanBootstrap.anchorToGrowStart(raw, start);
    await addGardenPlant(
      plant: plant,
      location: GrowLocationType.balcony,
      sunlight: SunlightLevel.medium,
      farmPlanStartMonth1To12: month,
      farmPlan: plan,
    );
  }

  /// Legacy name — same as [addGardenPlant].
  Future<void> startGrow({
    required Plant plant,
    required GrowLocationType location,
    required SunlightLevel sunlight,
    required int farmPlanStartMonth1To12,
    required FarmPlanAiResult farmPlan,
  }) =>
      addGardenPlant(
        plant: plant,
        location: location,
        sunlight: sunlight,
        farmPlanStartMonth1To12: farmPlanStartMonth1To12,
        farmPlan: farmPlan,
      );

  Future<void> setActiveGardenPlant(String gardenInstanceId) async {
    final list = _storage.loadGardenListSync();
    GrowSession? found;
    for (final e in list) {
      if (e.gardenInstanceId == gardenInstanceId) {
        found = e;
        break;
      }
    }
    if (found == null) return;
    state = GrowSession.fromJson(found.toJson());
    await _storage.setActiveGardenInstanceId(gardenInstanceId);
    ref.read(localDataRevisionProvider.notifier).state++;
    _router.refresh();
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
        s.plantHealth = (s.plantHealth + 6).clamp(0, 100);
        break;
      case WaterFeedback.overwatering:
        s.plantHealth = (s.plantHealth - 14).clamp(0, 100);
        break;
      case WaterFeedback.missed:
        s.plantHealth = (s.plantHealth - 10).clamp(0, 100);
        break;
      case WaterFeedback.suboptimal:
        s.plantHealth = (s.plantHealth - 3).clamp(0, 100);
        break;
    }
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
      _maybeCreditPerfectDayStreak(s, todayD);
    }
    WaterFeedback? fb;
    if (logCareFromCalendar) {
      if (overwatered || secondsWatered >= 25) {
        logWateredFromSprinkler(overwatered: overwatered);
        fb = overwatered ? WaterFeedback.overwatering : WaterFeedback.perfect;
      } else {
        fb = WaterFeedback.suboptimal;
      }
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
      s.plantHealth = (s.plantHealth - 14).clamp(0, 100);
    } else {
      s.plantHealth = (s.plantHealth + 6).clamp(0, 100);
    }
  }

  void _awardBadges(GrowSession s) {
    void add(String id) {
      if (!s.earnedBadgeIds.contains(id)) s.earnedBadgeIds.add(id);
    }

    if (s.waterLog.isNotEmpty) add('badge_first_water');
    for (final m in s.streakMilestoneDays) {
      if (s.streak >= m) add('badge_streak_day_$m');
    }
    if (s.plantHealth >= 90) add('badge_thriving');
    final done = s.tasks.where((t) => t.completed).length;
    if (done >= 20) add('badge_task_master');
  }

  /// +1 streak only when every task due that calendar day is done; [creditDay] is the due date (calendar day).
  bool _maybeCreditPerfectDayStreak(GrowSession s, DateTime creditDay) {
    if (!GrowSession.allDueTasksCompleteForDay(s, creditDay)) return false;
    final key = _dayKey(creditDay);
    if (s.lastStreakCreditDayKey == key) return false;

    final start = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day);
    final y = creditDay.subtract(const Duration(days: 1));
    if (y.isBefore(start)) {
      s.streak = 1;
    } else if (GrowSession.allDueTasksCompleteForDay(s, y)) {
      s.streak += 1;
    } else {
      s.streak = 1;
    }
    s.lastStreakCreditDayKey = key;
    if (s.bestStreak < s.streak) s.bestStreak = s.streak;
    s.perfectStreakDayLog.add(key);
    while (s.perfectStreakDayLog.length > 40) {
      s.perfectStreakDayLog.removeAt(0);
    }
    s.streakByDay[key] = s.streak;
    return true;
  }

  /// Returns `2` when today became a perfect streak day, `1` when task saved only, `0` if no-op.
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
    if (onTime) {
      s.plantHealth = (s.plantHealth + 4).clamp(0, 100);
    } else if (todayD.isBefore(due)) {
      s.plantHealth = (s.plantHealth + 2).clamp(0, 100);
    } else {
      s.plantHealth = (s.plantHealth - 5).clamp(0, 100);
    }
    final streakDay = _maybeCreditPerfectDayStreak(s, due);
    _awardBadges(s);
    await _persist();
    _reEmitSession();
    return streakDay ? 2 : 1;
  }

  /// Adds a one-off reminder to the active grow’s task list (e.g. soil recovery challenge).
  /// Returns false when there is no active session.
  Future<bool> appendCustomCalendarTask({
    required String title,
    int daysFromToday = 3,
  }) async {
    final s = state;
    if (s == null) return false;
    final today = DateTime.now();
    final base = DateTime(today.year, today.month, today.day);
    final d = daysFromToday;
    final offset = d < 0 ? 0 : (d > 3650 ? 3650 : d);
    final due = base.add(Duration(days: offset));
    final id = 'cal_${DateTime.now().microsecondsSinceEpoch}';
    s.tasks.add(GrowTask(
      id: id,
      title: title,
      dueDate: due,
      stage: ActivityStage.soilPrep,
    ));
    await _persist();
    _reEmitSession();
    return true;
  }

  Future<void> clearSession() async {
    final list = _storage.loadGardenListSync();
    for (final s in list) {
      await _storage.appendGrowArchive(s.toJson());
    }
    state = null;
    await _storage.saveGardenList([]);
    await _storage.setActiveGardenInstanceId(null);
    ref.read(localDataRevisionProvider.notifier).state++;
    _router.refresh();
  }
}

final sessionControllerProvider = NotifierProvider<SessionController, GrowSession?>(SessionController.new);
