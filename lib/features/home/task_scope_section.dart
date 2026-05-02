import 'dart:math';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/grow_session.dart';
import '../../domain/grow_task.dart';
import '../../providers/providers.dart';

DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

bool _isToday(DateTime d) {
  final t = DateTime.now();
  return d.year == t.year && d.month == t.month && d.day == t.day;
}

enum _TaskScope { day, week, month }

class FarmStreakCard extends StatelessWidget {
  const FarmStreakCard({super.key, required this.session});

  final GrowSession session;

  static const _streakBadgeIds = {
    'badge_streak_chain_3',
    'badge_streak_7',
    'badge_streak_chain_14',
    'badge_streak_30',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final muted = cs.onSurfaceVariant;
    final recent = session.perfectStreakDayLog.reversed.take(7).toList();
    final streakBadges = session.earnedBadgeIds.where(_streakBadgeIds.contains).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 26),
                const SizedBox(width: 8),
                Text(
                  'Streak',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Current streak: ${session.streak} perfect day(s) in a row',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'Best for this crop: ${session.bestStreak} · Plant vitality: ${session.plantHealth}%',
              style: GoogleFonts.inter(fontSize: 13, color: muted, height: 1.35),
            ),
            const SizedBox(height: 6),
            Text(
              'A perfect day means every task due that calendar day is completed. '
              'Badges unlock at 3, 7, 14, and 30 consecutive perfect days.',
              style: GoogleFonts.inter(fontSize: 12, color: muted, height: 1.35),
            ),
            if (streakBadges.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Streak badges earned', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: streakBadges
                    .map(
                      (id) => Chip(
                        label: Text(id.replaceFirst('badge_', '').replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: cs.primaryContainer.withValues(alpha: 0.5),
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 10),
            Text('Recent perfect days', style: GoogleFonts.inter(fontSize: 12, color: muted)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: recent.isEmpty
                  ? [
                      Text(
                        'Finish every task due today to start your chain.',
                        style: GoogleFonts.inter(fontSize: 12, color: muted.withValues(alpha: 0.85)),
                      ),
                    ]
                  : recent.map((k) {
                      return Chip(
                        label: Text(k, style: GoogleFonts.inter(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: GrowColors.green100.withValues(alpha: 0.6),
                      );
                    }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskScopeSection extends ConsumerStatefulWidget {
  const TaskScopeSection({super.key, required this.session});

  final GrowSession session;

  @override
  ConsumerState<TaskScopeSection> createState() => _TaskScopeSectionState();
}

class _TaskScopeSectionState extends ConsumerState<TaskScopeSection> {
  _TaskScope _scope = _TaskScope.day;
  final Set<int> _openWeeks = {};
  final Set<String> _openDays = {};

  Map<DateTime, List<GrowTask>> _tasksByDay() {
    final m = <DateTime, List<GrowTask>>{};
    for (final t in widget.session.tasks) {
      final k = _dOnly(t.dueDate);
      m.putIfAbsent(k, () => []).add(t);
    }
    for (final e in m.entries) {
      e.value.sort((a, b) => a.title.compareTo(b.title));
    }
    return m;
  }

  int _weekIndexFromOffset(int dayOffset) => dayOffset ~/ 7;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final byDay = _tasksByDay();
    final start = _dOnly(widget.session.startedAt);
    final n = widget.session.harvestDurationDays;
    final today = _dOnly(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(l.tasks, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
            const Spacer(),
            DropdownButton<_TaskScope>(
              value: _scope,
              items: const [
                DropdownMenuItem(value: _TaskScope.day, child: Text('Day')),
                DropdownMenuItem(value: _TaskScope.week, child: Text('Week')),
                DropdownMenuItem(value: _TaskScope.month, child: Text('Month')),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _scope = v;
                  _openWeeks.clear();
                  _openDays.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        switch (_scope) {
          _TaskScope.day => _buildDayView(context, l, byDay, today),
          _TaskScope.week => _buildWeekView(context, l, byDay, start, n),
          _TaskScope.month => _buildMonthView(context, l, byDay),
        },
      ],
    );
  }

  Widget _buildDayView(
    BuildContext context,
    AppLocalizations l,
    Map<DateTime, List<GrowTask>> byDay,
    DateTime today,
  ) {
    final list = byDay[today] ?? [];
    final n = list.length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              n == 0 ? "Today's tasks" : "Today's tasks · $n ${n == 1 ? 'task' : 'tasks'}",
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            const SizedBox(height: 8),
            if (list.isEmpty)
              Text('Nothing scheduled for today.', style: GoogleFonts.inter(color: GrowColors.gray600))
            else
              ...list.map((t) => _taskTile(context, t)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekView(
    BuildContext context,
    AppLocalizations l,
    Map<DateTime, List<GrowTask>> byDay,
    DateTime start,
    int n,
  ) {
    final weekCount = (n + 6) ~/ 7;
    return Column(
      children: List.generate(weekCount, (wi) {
        final dayStart = start.add(Duration(days: wi * 7));
        final dayEnd = start.add(Duration(days: min(n - 1, wi * 7 + 6)));
        var weekTasks = 0;
        for (var di = 0; di < 7; di++) {
          final off = wi * 7 + di;
          if (off >= n) break;
          weekTasks += (byDay[_dOnly(start.add(Duration(days: off)))] ?? []).length;
        }
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            key: PageStorageKey('w$wi'),
            title: Text(
              'Week ${wi + 1} · $weekTasks ${weekTasks == 1 ? 'task' : 'tasks'} · ${dayStart.month}/${dayStart.day}–${dayEnd.month}/${dayEnd.day}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            initiallyExpanded: _openWeeks.contains(wi),
            onExpansionChanged: (v) => setState(() {
              if (v) {
                _openWeeks.add(wi);
              } else {
                _openWeeks.remove(wi);
              }
            }),
            children: () {
              final out = <Widget>[];
              for (var di = 0; di < 7; di++) {
                final off = wi * 7 + di;
                if (off >= n) break;
                final day = start.add(Duration(days: off));
                final key = day.toIso8601String().split('T').first;
                final tasks = byDay[_dOnly(day)] ?? [];
                final tc = tasks.length;
                final dOpen = _openDays.contains(key);
                out.add(
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Text(
                        '${day.month}/${day.day} · $tc ${tc == 1 ? 'task' : 'tasks'}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      initiallyExpanded: dOpen,
                      onExpansionChanged: (v) => setState(() {
                        if (v) {
                          _openDays.add(key);
                        } else {
                          _openDays.remove(key);
                        }
                      }),
                      children: tasks.isEmpty
                          ? [
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  'No tasks',
                                  style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
                                ),
                              ),
                            ]
                          : tasks.map((t) => _taskTile(context, t)).toList(),
                    ),
                  ),
                );
              }
              return out;
            }(),
          ),
        );
      }),
    );
  }

  Widget _buildMonthView(
    BuildContext context,
    AppLocalizations l,
    Map<DateTime, List<GrowTask>> byDay,
  ) {
    final months = <String, List<MapEntry<DateTime, List<GrowTask>>>>{};
    for (final e in byDay.entries) {
      final label = '${e.key.year}-${e.key.month.toString().padLeft(2, '0')}';
      months.putIfAbsent(label, () => []).add(e);
    }
    final sortedKeys = months.keys.toList()..sort();
    return Column(
      children: sortedKeys.map((mk) {
        final entries = months[mk]!..sort((a, b) => a.key.compareTo(b.key));
        final monthTasks = entries.fold<int>(0, (s, e) => s + e.value.length);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ExpansionTile(
            title: Text(
              '$mk · $monthTasks ${monthTasks == 1 ? 'task' : 'tasks'}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
            ),
            children: entries.map((e) {
              final key = e.key.toIso8601String().split('T').first;
              final dOpen = _openDays.contains(key);
              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 12),
                title: Text(
                  '${e.key.month}/${e.key.day} · ${e.value.length} ${e.value.length == 1 ? 'task' : 'tasks'}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                initiallyExpanded: dOpen,
                onExpansionChanged: (v) => setState(() {
                  if (v) {
                    _openDays.add(key);
                  } else {
                    _openDays.remove(key);
                  }
                }),
                children: e.value.map((t) => _taskTile(context, t)).toList(),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }

  Widget _taskTile(BuildContext context, GrowTask task) {
    final due = _dOnly(task.dueDate);
    final editable = _isToday(due) && !task.completed;
    return CheckboxListTile(
      dense: true,
      value: task.completed,
      onChanged: editable
          ? (v) async {
              if (v != true) return;
              final inc = await ref.read(sessionControllerProvider.notifier).completeTask(task.id);
              if (!context.mounted) return;
              setState(() {});
              if (inc == 2) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Perfect day — streak +1. Check badges in Streaks.')),
                );
              } else if (inc == 1) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task saved')));
              }
            }
          : null,
      title: Text(task.title, style: GoogleFonts.inter(fontSize: 14)),
      subtitle: Text(
        'Due ${due.month}/${due.day} · reminder ${task.dueHour}:00',
        style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
      ),
    );
  }
}
