import '../domain/activity_stage.dart';
import '../domain/farm_plan_ai_result.dart';
import '../domain/grow_session.dart';
import '../domain/grow_task.dart';

/// Fallback farm plan when Gemini is unavailable or JSON parsing fails.
class FarmPlanTemplates {
  FarmPlanTemplates._();

  static List<int> defaultStreakMilestones(int harvestDays) {
    final n = harvestDays.clamp(1, 9999);
    const seeds = [2, 3, 5, 7, 10, 14, 21, 30, 45, 60, 90, 120];
    final out = seeds.where((x) => x <= n).toList();
    if (out.isEmpty) return [n];
    return out;
  }

  static List<FarmStageRange> stagesFromStaticTemplate(int totalDays) {
    final n = totalDays < 1 ? 1 : totalDays;
    ActivityStage stFor(int d) => GrowSession.stageForDayIndex(d, n);
    if (n == 0) return [];
    final out = <FarmStageRange>[];
    var start = 0;
    var cur = stFor(0);
    var name = _stageLabel(cur);
    for (var d = 1; d < n; d++) {
      final next = stFor(d);
      if (next != cur) {
        out.add(FarmStageRange(name: name, startDay: start, endDay: d - 1, stage: cur));
        start = d;
        cur = next;
        name = _stageLabel(cur);
      }
    }
    out.add(FarmStageRange(name: name, startDay: start, endDay: n - 1, stage: cur));
    return out;
  }

  static String _stageLabel(ActivityStage s) => switch (s) {
        ActivityStage.soilPrep => 'Soil preparation',
        ActivityStage.seeding => 'Establishment',
        ActivityStage.fertilizing => 'Feeding & care',
        ActivityStage.harvesting => 'Finish & harvest',
      };

  /// [anchor] defaults to `2000-01-01` so the same [materializeTaskAnchors] pipeline as Gemini works.
  static FarmPlanAiResult buildFallback({
    DateTime anchor = const DateTime(2000, 1, 1),
    required int harvestDays,
    String plantName = 'crop',
  }) {
    final tasks = GrowSession.generateTasks(start: anchor, harvestDays: harvestDays);
    return FarmPlanAiResult(
      summary:
          'Template plan for $plantName — week-based soil block, then establishment, feeding, and harvest. '
          'Connect Gemini for a crop-specific AI calendar.',
      streakMilestoneDays: defaultStreakMilestones(harvestDays),
      stages: stagesFromStaticTemplate(harvestDays),
      tasks: tasks,
    );
  }
}
