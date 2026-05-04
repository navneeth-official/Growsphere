import 'dart:convert';

import '../core/farm_plan_templates.dart';
import '../core/services/gemini_generative_service.dart';
import '../domain/activity_stage.dart';
import '../domain/farm_plan_ai_result.dart';
import '../domain/grow_task.dart';
import 'ai_tool_ids.dart';
import 'grow_storage.dart';

/// Asks Gemini for a JSON farm plan (stages, tasks, streak milestones) for a crop.
class GeminiFarmPlanRepository {
  GeminiFarmPlanRepository({
    required GeminiGenerativeService gemini,
    required GrowStorage storage,
  })  : _gemini = gemini,
        _storage = storage;

  final GeminiGenerativeService _gemini;
  final GrowStorage _storage;

  static const _sys = '''
You are an agronomy assistant. Output ONLY valid JSON (no markdown fences) with this shape:
{
  "summary": "one short paragraph",
  "streakMilestones": [list of distinct positive integers, sorted ascending, each <= harvestDays, 3 to 8 values, tied to realistic perfect-task-day goals for THIS crop length],
  "stages": [
    {"name":"human readable","startDay":0,"endDay":6,"stage":"soilPrep|seeding|fertilizing|harvesting"}
  ],
  "tasks": [
    {"id":"unique_string","title":"short task","dayOffset":0,"stage":"soilPrep|seeding|fertilizing|harvesting","dueHour":17}
  ]
}
Rules:
- startDay/endDay are 0-based from grow start; cover 0..harvestDays-1 without gaps; stages must align with task dayOffsets.
- Include enough tasks (roughly 1-2 every few days) so the farmer has clear work; never empty tasks array.
- streakMilestones must be meaningful for the crop duration (shorter crops → smaller milestones).
- stage must be one of: soilPrep, seeding, fertilizing, harvesting.
''';

  Future<FarmPlanAiResult?> tryBuildPlan({
    required String plantName,
    required int harvestDays,
    required String climate,
    required String soil,
    required String fertilizers,
    required int farmStartMonth1To12,
    required String locationName,
    required String sunlightName,
  }) async {
    final mem = _storage.buildAiToolContextBlock(AiToolIds.farmPlan);
    final user = '''
${mem.isNotEmpty ? 'PRIOR_TOOL_MEMORY (same tool, earlier requests — stay consistent when relevant):\n$mem\n\n' : ''}Plant: $plantName
Total grow days (harvest window): $harvestDays
Planned farm start month (1-12): $farmStartMonth1To12
Location: $locationName
Sunlight: $sunlightName
Climate requirements: $climate
Soil requirements: $soil
Fertilizer needs: $fertilizers
Build the JSON plan.
''';
    try {
      final raw = await _gemini.generateText(systemInstruction: _sys, userText: user);
      final parsed = _parse(raw, harvestDays);
      if (parsed != null) {
        await _storage.recordAiToolExchange(
          AiToolIds.farmPlan,
          'Plan request: $plantName, ${harvestDays}d, $locationName / $sunlightName',
          raw.length > 2000 ? '${raw.substring(0, 2000)}…' : raw,
        );
      }
      return parsed;
    } catch (_) {
      return null;
    }
  }

  FarmPlanAiResult? _parse(String raw, int harvestDays) {
    var t = raw.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```json?\s*'), '').replaceFirst(RegExp(r'\s*```\s*$'), '');
    }
    final map = jsonDecode(t) as Map<String, dynamic>;
    final summary = map['summary'] as String? ?? '';
    final m = (map['streakMilestones'] as List<dynamic>? ?? [])
        .map((e) => (e as num).toInt())
        .where((x) => x > 0 && x <= harvestDays)
        .toSet()
        .toList()
      ..sort();
    final stages = (map['stages'] as List<dynamic>? ?? [])
        .map((e) => FarmStageRange.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final taskMaps = map['tasks'] as List<dynamic>? ?? [];
    final tasks = <GrowTask>[];
    for (final e in taskMaps) {
      final o = Map<String, dynamic>.from(e as Map);
      final id = o['id'] as String? ?? 't_${tasks.length}';
      final title = o['title'] as String? ?? 'Care task';
      final off = (o['dayOffset'] as num?)?.toInt() ?? 0;
      final d = off.clamp(0, harvestDays - 1);
      final stageStr = o['stage'] as String? ?? 'soilPrep';
      final stage = ActivityStage.values.firstWhere(
        (x) => x.name == stageStr,
        orElse: () => ActivityStage.soilPrep,
      );
      final hour = (o['dueHour'] as num?)?.toInt().clamp(0, 23) ?? 17;
      tasks.add(GrowTask(
        id: id,
        title: title,
        dueDate: DateTime(2000, 1, 1).add(Duration(days: d)),
        stage: stage,
        dueHour: hour,
      ));
    }
    if (tasks.isEmpty) return null;
    return FarmPlanAiResult(
      summary: summary,
      streakMilestoneDays: m.isEmpty ? FarmPlanTemplates.defaultStreakMilestones(harvestDays) : m,
      stages: stages.isEmpty ? FarmPlanTemplates.stagesFromStaticTemplate(harvestDays) : stages,
      tasks: tasks,
    );
  }

  /// Fixes placeholder due dates using [start] calendar day.
  FarmPlanAiResult materializeDates(FarmPlanAiResult plan, DateTime start) => plan.materializeTaskAnchors(start);
}
