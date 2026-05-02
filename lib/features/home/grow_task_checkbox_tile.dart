import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/grow_task.dart';
import '../../providers/providers.dart';

DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isToday(DateTime d) {
  final t = DateTime.now();
  return d.year == t.year && d.month == t.month && d.day == t.day;
}

/// Checkbox task row used on the activity calendar / stage views.
class GrowTaskCheckboxTile extends ConsumerWidget {
  const GrowTaskCheckboxTile({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    if (session == null) return const SizedBox.shrink();
    GrowTask? task;
    for (final t in session.tasks) {
      if (t.id == taskId) {
        task = t;
        break;
      }
    }
    if (task == null) return const SizedBox.shrink();

    final due = _dOnly(task.dueDate);
    final editable = _isToday(due) && !task.completed;
    return CheckboxListTile(
      dense: true,
      value: task.completed,
      onChanged: editable
          ? (v) async {
              if (v != true) return;
              final inc = await ref.read(sessionControllerProvider.notifier).completeTask(taskId);
              if (!context.mounted) return;
              if (inc == 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfect day — streak +1. Check badges in Streaks.')),
                );
              } else if (inc == 1) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task saved')));
              }
            }
          : null,
      title: Text(
        task.title,
        style: GoogleFonts.inter(
          fontSize: 14,
          decoration: task.completed ? TextDecoration.lineThrough : null,
        ),
      ),
      subtitle: Text(
        'Scheduled: ${due.month}/${due.day}/${due.year} · reminder ${task.dueHour}:00',
        style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
      ),
    );
  }
}
