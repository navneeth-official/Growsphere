import 'activity_stage.dart';

class GrowTask {
  GrowTask({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.stage,
    this.completed = false,
    this.completedAt,
    this.dueHour = 18,
  });

  final String id;
  final String title;
  final DateTime dueDate;
  final ActivityStage stage;
  /// Local reminder hour (0–23) for deadline notifications.
  final int dueHour;
  bool completed;
  DateTime? completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'stage': stage.name,
        'dueHour': dueHour,
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory GrowTask.fromJson(Map<String, dynamic> json) {
    return GrowTask(
      id: json['id'] as String,
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      stage: ActivityStage.values.firstWhere(
        (e) => e.name == json['stage'],
        orElse: () => ActivityStage.soilPrep,
      ),
      dueHour: (json['dueHour'] as num?)?.toInt().clamp(0, 23) ?? 18,
      completed: json['completed'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}
