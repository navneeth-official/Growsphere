import '../data/gemini_farm_plan_repository.dart';
import '../domain/farm_plan_ai_result.dart';
import '../domain/grow_enums.dart';
import '../domain/plant.dart';
import 'farm_plan_templates.dart';

/// Builds an AI farm plan (or template) using saved crop requirements; task dates use the `2000-01-01` anchor until [anchorToGrowStart].
class FarmPlanBootstrap {
  FarmPlanBootstrap._();

  static String _locationLabel(GrowLocationType t) => switch (t) {
        GrowLocationType.indoor => 'Indoor',
        GrowLocationType.balcony => 'Balcony',
        GrowLocationType.terrace => 'Terrace',
      };

  static String _sunLabel(SunlightLevel s) => switch (s) {
        SunlightLevel.low => 'Low',
        SunlightLevel.medium => 'Medium',
        SunlightLevel.high => 'High',
      };

  static Future<FarmPlanAiResult> loadOrBuild({
    required GeminiFarmPlanRepository? repo,
    required Plant plant,
    required int farmStartMonth1To12,
    required GrowLocationType location,
    required SunlightLevel sunlight,
  }) async {
    final m = farmStartMonth1To12.clamp(1, 12);
    if (repo != null) {
      final ai = await repo.tryBuildPlan(
        plantName: plant.name,
        harvestDays: plant.harvestDurationDays,
        climate: plant.climate,
        soil: plant.soil,
        fertilizers: plant.fertilizers,
        farmStartMonth1To12: m,
        locationName: _locationLabel(location),
        sunlightName: _sunLabel(sunlight),
      );
      if (ai != null) return ai;
    }
    return FarmPlanTemplates.buildFallback(harvestDays: plant.harvestDurationDays, plantName: plant.name);
  }

  /// Maps epoch-anchored tasks onto the calendar day when the grow session starts.
  static FarmPlanAiResult anchorToGrowStart(FarmPlanAiResult plan, DateTime growCalendarStart) {
    if (plan.tasks.isEmpty) return plan;
    if (plan.tasks.first.dueDate.year == 2000) {
      return plan.materializeTaskAnchors(growCalendarStart);
    }
    return plan;
  }
}
