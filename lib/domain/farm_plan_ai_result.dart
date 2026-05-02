import 'dart:convert';

import 'activity_stage.dart';
import 'grow_task.dart';

/// One stage row in an AI (or fallback) farm calendar.
class FarmStageRange {
  const FarmStageRange({
    required this.name,
    required this.startDay,
    required this.endDay,
    required this.stage,
  });

  final String name;
  final int startDay;
  final int endDay;
  final ActivityStage stage;

  Map<String, dynamic> toJson() => {
        'name': name,
        'startDay': startDay,
        'endDay': endDay,
        'stage': stage.name,
      };

  factory FarmStageRange.fromJson(Map<String, dynamic> json) {
    final s = json['stage'] as String? ?? 'soilPrep';
    return FarmStageRange(
      name: json['name'] as String? ?? 'Stage',
      startDay: (json['startDay'] as num?)?.toInt() ?? 0,
      endDay: (json['endDay'] as num?)?.toInt() ?? 0,
      stage: ActivityStage.values.firstWhere((e) => e.name == s, orElse: () => ActivityStage.soilPrep),
    );
  }
}

/// Parsed farm plan + streak milestones + concrete tasks for a grow.
class FarmPlanAiResult {
  const FarmPlanAiResult({
    required this.summary,
    required this.streakMilestoneDays,
    required this.stages,
    required this.tasks,
  });

  final String summary;
  final List<int> streakMilestoneDays;
  final List<FarmStageRange> stages;
  final List<GrowTask> tasks;

  Map<String, dynamic> toJson() => {
        'summary': summary,
        'streakMilestoneDays': streakMilestoneDays,
        'stages': stages.map((e) => e.toJson()).toList(),
        'tasks': tasks.map((e) => e.toJson()).toList(),
      };

  factory FarmPlanAiResult.fromJson(Map<String, dynamic> json) {
    return FarmPlanAiResult(
      summary: json['summary'] as String? ?? '',
      streakMilestoneDays: List<int>.from(
        (json['streakMilestoneDays'] as List<dynamic>? ?? []).map((e) => (e as num).toInt()),
      ),
      stages: (json['stages'] as List<dynamic>? ?? [])
          .map((e) => FarmStageRange.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((e) => GrowTask.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  String serialize() => jsonEncode(toJson());

  static FarmPlanAiResult? tryDeserialize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return FarmPlanAiResult.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Maps placeholder due dates (offsets from `2000-01-01`, as produced by Gemini parsing)
  /// onto the real grow calendar starting at [growStart] (calendar day).
  FarmPlanAiResult materializeTaskAnchors(DateTime growStart) {
    final startDay = DateTime(growStart.year, growStart.month, growStart.day);
    final epoch = DateTime(2000, 1, 1);
    final fixed = tasks.map((t) {
      final off = t.dueDate.difference(epoch).inDays;
      final day = startDay.add(Duration(days: off.clamp(0, 9999)));
      return GrowTask(
        id: t.id,
        title: t.title,
        dueDate: day,
        stage: t.stage,
        dueHour: t.dueHour,
        completed: t.completed,
        completedAt: t.completedAt,
      );
    }).toList();
    return FarmPlanAiResult(
      summary: summary,
      streakMilestoneDays: streakMilestoneDays,
      stages: stages,
      tasks: fixed,
    );
  }
}
