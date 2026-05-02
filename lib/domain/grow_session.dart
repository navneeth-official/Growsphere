import '../core/farm_plan_templates.dart';
import 'activity_stage.dart';
import 'farm_plan_ai_result.dart';
import 'grow_enums.dart';
import 'grow_task.dart';

/// Serialized user grow journey.
/// Firestore: `users/{uid}/sessions/current` (single doc) or embedded fields.
class GrowSession {
  GrowSession({
    required this.gardenInstanceId,
    required this.plantId,
    required this.plantName,
    required this.difficulty,
    required this.wateringLevel,
    required this.climate,
    required this.soil,
    required this.fertilizers,
    required this.harvestDurationDays,
    required this.nutrientHeavy,
    required this.location,
    required this.sunlight,
    required this.startedAt,
    required this.tasks,
    required this.waterLog,
    required this.streak,
    required this.bestStreak,
    required this.lastStreakCreditDayKey,
    required this.perfectStreakDayLog,
    required this.plantHealth,
    required this.streakByDay,
    required this.earnedBadgeIds,
    required this.wateringRecommendationText,
    required this.farmPlanStartMonth,
    required this.farmPlanJson,
  });

  /// Stable id for this grow in the multi-plant garden list (persisted).
  final String gardenInstanceId;
  final String plantId;
  final String plantName;
  final String difficulty;
  final String wateringLevel;
  final String climate;
  final String soil;
  final String fertilizers;
  final int harvestDurationDays;
  final bool nutrientHeavy;
  final GrowLocationType location;
  final SunlightLevel sunlight;
  final DateTime startedAt;
  final List<GrowTask> tasks;
  final List<DateTime> waterLog;
  int streak;
  /// Longest consecutive "perfect task days" chain for this grow.
  int bestStreak;
  /// `YYYY-MM-DD` of the last calendar day that received a +1 streak credit (all due tasks done).
  String? lastStreakCreditDayKey;
  /// Recent days (keys) where every due task was completed; newest last. Capped in session logic.
  List<String> perfectStreakDayLog;
  int plantHealth;
  Map<String, int> streakByDay;
  List<String> earnedBadgeIds;
  final String wateringRecommendationText;
  /// Month (1–12) when the user plans to start / anchor the farm calendar.
  final int farmPlanStartMonth;
  /// Serialized [FarmPlanAiResult] (stages, tasks, streak milestones, summary).
  final String farmPlanJson;

  Map<String, dynamic> toJson() => {
        'gardenInstanceId': gardenInstanceId,
        'plantId': plantId,
        'plantName': plantName,
        'difficulty': difficulty,
        'wateringLevel': wateringLevel,
        'climate': climate,
        'soil': soil,
        'fertilizers': fertilizers,
        'harvestDurationDays': harvestDurationDays,
        'nutrientHeavy': nutrientHeavy,
        'location': location.name,
        'sunlight': sunlight.name,
        'startedAt': startedAt.toIso8601String(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
        'waterLog': waterLog.map((e) => e.toIso8601String()).toList(),
        'streak': streak,
        'bestStreak': bestStreak,
        'lastStreakCreditDayKey': lastStreakCreditDayKey,
        'perfectStreakDayLog': perfectStreakDayLog,
        'plantHealth': plantHealth,
        'streakByDay': streakByDay,
        'earnedBadgeIds': earnedBadgeIds,
        'wateringRecommendationText': wateringRecommendationText,
        'farmPlanStartMonth': farmPlanStartMonth,
        'farmPlanJson': farmPlanJson,
      };

  factory GrowSession.fromJson(Map<String, dynamic> json) {
    final startedAt = DateTime.parse(json['startedAt'] as String);
    final harvestDurationDays = (json['harvestDurationDays'] as num).toInt();
    final tasks = (json['tasks'] as List<dynamic>).map((e) => GrowTask.fromJson(e as Map<String, dynamic>)).toList();
    var farmPlanJson = json['farmPlanJson'] as String? ?? '';
    if (farmPlanJson.isEmpty) {
      final name = json['plantName'] as String? ?? 'crop';
      final startDay = DateTime(startedAt.year, startedAt.month, startedAt.day);
      farmPlanJson = FarmPlanAiResult(
        summary: 'Classic plan metadata was added for this saved grow.',
        streakMilestoneDays: FarmPlanTemplates.defaultStreakMilestones(harvestDurationDays),
        stages: FarmPlanTemplates.stagesFromStaticTemplate(harvestDurationDays),
        tasks: tasks,
      ).serialize();
    }
    final plantId = json['plantId'] as String;
    return GrowSession(
      gardenInstanceId:
          json['gardenInstanceId'] as String? ?? 'legacy_${plantId}_${startedAt.toIso8601String()}',
      plantId: plantId,
      plantName: json['plantName'] as String,
      difficulty: json['difficulty'] as String,
      wateringLevel: json['wateringLevel'] as String,
      climate: json['climate'] as String,
      soil: json['soil'] as String,
      fertilizers: json['fertilizers'] as String,
      harvestDurationDays: harvestDurationDays,
      nutrientHeavy: json['nutrientHeavy'] as bool? ?? false,
      location: GrowLocationType.values
          .firstWhere((e) => e.name == json['location'], orElse: () => GrowLocationType.balcony),
      sunlight: SunlightLevel.values
          .firstWhere((e) => e.name == json['sunlight'], orElse: () => SunlightLevel.medium),
      startedAt: startedAt,
      tasks: tasks,
      waterLog: (json['waterLog'] as List<dynamic>? ?? [])
          .map((e) => DateTime.parse(e as String))
          .toList(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['bestStreak'] as num?)?.toInt() ??
          (json['streak'] as num?)?.toInt() ??
          0,
      lastStreakCreditDayKey: json['lastStreakCreditDayKey'] as String?,
      perfectStreakDayLog: List<String>.from(
        (json['perfectStreakDayLog'] as List<dynamic>? ?? []).cast<String>(),
      ),
      plantHealth: (json['plantHealth'] as num?)?.toInt() ?? 80,
      streakByDay: Map<String, int>.from(
        (json['streakByDay'] as Map<dynamic, dynamic>? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      ),
      earnedBadgeIds: List<String>.from((json['earnedBadgeIds'] as List<dynamic>? ?? []).cast<String>()),
      wateringRecommendationText: json['wateringRecommendationText'] as String? ?? '',
      farmPlanStartMonth: (json['farmPlanStartMonth'] as num?)?.toInt().clamp(1, 12) ?? DateTime.now().month,
      farmPlanJson: farmPlanJson,
    );
  }

  FarmPlanAiResult? get farmPlanOrNull => FarmPlanAiResult.tryDeserialize(farmPlanJson);

  List<int> get streakMilestoneDays {
    final p = farmPlanOrNull;
    if (p != null && p.streakMilestoneDays.isNotEmpty) return p.streakMilestoneDays;
    return FarmPlanTemplates.defaultStreakMilestones(harvestDurationDays);
  }

  /// Stage colour driver for calendar: uses AI plan stages when present.
  ActivityStage activityStageForGrowDay(int dayIndex) {
    final plan = farmPlanOrNull;
    if (plan != null && plan.stages.isNotEmpty) {
      final d = dayIndex.clamp(0, harvestDurationDays - 1);
      for (final st in plan.stages) {
        if (d >= st.startDay && d <= st.endDay) return st.stage;
      }
    }
    return GrowSession.stageForDayIndex(dayIndex, harvestDurationDays);
  }

  /// At least one task due on [day] and every such task is completed.
  static bool allDueTasksCompleteForDay(GrowSession s, DateTime day) {
    final k = DateTime(day.year, day.month, day.day);
    final due = s.tasks.where((t) => DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day) == k).toList();
    if (due.isEmpty) return false;
    return due.every((t) => t.completed);
  }

  /// Calendar + task stages: **week 1 = soil prep only**, then **2-week** blocks for
  /// establishment → feeding → finish. Short crops compress after the soil week.
  static ActivityStage stageForDayIndex(int dayIndex, int totalDays) {
    final n = totalDays < 1 ? 1 : totalDays;
    final d = dayIndex.clamp(0, n - 1);
    if (n <= 10) {
      if (d < (n * 0.25).ceil()) return ActivityStage.soilPrep;
      if (d < (n * 0.55).ceil()) return ActivityStage.seeding;
      if (d < (n * 0.8).ceil()) return ActivityStage.fertilizing;
      return ActivityStage.harvesting;
    }
    if (d < 7) return ActivityStage.soilPrep;
    if (d < 21) return ActivityStage.seeding;
    if (d < 35) return ActivityStage.fertilizing;
    return ActivityStage.harvesting;
  }

  static String recommendationFor({
    required String wateringLevel,
    required GrowLocationType location,
    required SunlightLevel sun,
  }) {
    final base = switch (wateringLevel) {
      'high' => 'Water deeply most days; surface should stay lightly moist.',
      'low' => 'Water thoroughly then let top few cm dry between sessions.',
      _ => 'Water when top soil feels dry; avoid standing water.',
    };
    final loc = switch (location) {
      GrowLocationType.indoor => ' Indoors, reduce frequency slightly and watch drainage trays.',
      GrowLocationType.balcony => ' Balcony pots dry faster in wind—check daily in warm weather.',
      GrowLocationType.terrace => ' Terrace heat increases evaporation—morning or evening watering is best.',
    };
    final sunAdj = switch (sun) {
      SunlightLevel.low => ' Low light slows growth—ease back on water to prevent soggy roots.',
      SunlightLevel.high => ' High light increases thirst—paired windows may need an extra check mid-day.',
      _ => '',
    };
    return '$base$loc$sunAdj';
  }

  static List<GrowTask> generateTasks({
    required DateTime start,
    required int harvestDays,
  }) {
    final tasks = <GrowTask>[];
    for (var d = 0; d < harvestDays; d++) {
      final day = DateTime(start.year, start.month, start.day).add(Duration(days: d));
      final stage = stageForDayIndex(d, harvestDays);
      if (d % 3 == 0) {
        tasks.add(GrowTask(
          id: 't_${day.toIso8601String().split('T').first}_m',
          title: _titleFor(stage, d, moisture: true),
          dueDate: day,
          stage: stage,
          dueHour: 18,
        ));
      }
      if (d % 5 == 0) {
        tasks.add(GrowTask(
          id: 't_${day.toIso8601String().split('T').first}_p',
          title: _titleFor(stage, d, moisture: false),
          dueDate: day,
          stage: stage,
          dueHour: 17,
        ));
      }
    }
    return tasks;
  }

  static String _titleFor(ActivityStage stage, int day, {required bool moisture}) {
    if (moisture) {
      return switch (stage) {
        ActivityStage.soilPrep => 'Moisten seedbed evenly',
        ActivityStage.seeding => 'Check seedling moisture without disturbing roots',
        ActivityStage.fertilizing => 'Water after light feeding to move nutrients',
        ActivityStage.harvesting => 'Reduce water slightly as crop matures',
      };
    }
    return switch (stage) {
      ActivityStage.soilPrep => 'Loosen soil and remove debris',
      ActivityStage.seeding => 'Thin overcrowded seedlings if needed',
      ActivityStage.fertilizing => 'Side-dress or foliar feed per schedule',
      ActivityStage.harvesting => 'Harvest ripe produce; note quality',
    };
  }
}
