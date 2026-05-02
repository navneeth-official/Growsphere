import 'activity_stage.dart';
import 'grow_enums.dart';
import 'grow_task.dart';

/// Serialized user grow journey.
/// Firestore: `users/{uid}/sessions/current` (single doc) or embedded fields.
class GrowSession {
  GrowSession({
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
    required this.plantHealth,
    required this.streakByDay,
    required this.earnedBadgeIds,
    required this.wateringRecommendationText,
  });

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
  int plantHealth;
  Map<String, int> streakByDay;
  List<String> earnedBadgeIds;
  final String wateringRecommendationText;

  Map<String, dynamic> toJson() => {
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
        'plantHealth': plantHealth,
        'streakByDay': streakByDay,
        'earnedBadgeIds': earnedBadgeIds,
        'wateringRecommendationText': wateringRecommendationText,
      };

  factory GrowSession.fromJson(Map<String, dynamic> json) {
    return GrowSession(
      plantId: json['plantId'] as String,
      plantName: json['plantName'] as String,
      difficulty: json['difficulty'] as String,
      wateringLevel: json['wateringLevel'] as String,
      climate: json['climate'] as String,
      soil: json['soil'] as String,
      fertilizers: json['fertilizers'] as String,
      harvestDurationDays: (json['harvestDurationDays'] as num).toInt(),
      nutrientHeavy: json['nutrientHeavy'] as bool? ?? false,
      location: GrowLocationType.values
          .firstWhere((e) => e.name == json['location'], orElse: () => GrowLocationType.balcony),
      sunlight: SunlightLevel.values
          .firstWhere((e) => e.name == json['sunlight'], orElse: () => SunlightLevel.medium),
      startedAt: DateTime.parse(json['startedAt'] as String),
      tasks: (json['tasks'] as List<dynamic>).map((e) => GrowTask.fromJson(e as Map<String, dynamic>)).toList(),
      waterLog: (json['waterLog'] as List<dynamic>? ?? [])
          .map((e) => DateTime.parse(e as String))
          .toList(),
      streak: (json['streak'] as num?)?.toInt() ?? 0,
      plantHealth: (json['plantHealth'] as num?)?.toInt() ?? 80,
      streakByDay: Map<String, int>.from(
        (json['streakByDay'] as Map<dynamic, dynamic>? ?? {}).map((k, v) => MapEntry(k as String, (v as num).toInt())),
      ),
      earnedBadgeIds: List<String>.from((json['earnedBadgeIds'] as List<dynamic>? ?? []).cast<String>()),
      wateringRecommendationText: json['wateringRecommendationText'] as String? ?? '',
    );
  }

  static ActivityStage stageForDayIndex(int dayIndex, int totalDays) {
    final p = dayIndex / totalDays;
    if (p < 0.15) return ActivityStage.soilPrep;
    if (p < 0.40) return ActivityStage.seeding;
    if (p < 0.75) return ActivityStage.fertilizing;
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
        ActivityStage.soilPrep => 'Moisten seedbed evenly (day ${day + 1})',
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
