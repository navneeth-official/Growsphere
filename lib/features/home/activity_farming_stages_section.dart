import 'dart:math';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/farm_plan_template.dart';
import '../../core/theme/grow_colors.dart';
import '../../domain/grow_session.dart';
import '../../domain/grow_task.dart';
import '../../providers/providers.dart';
import 'grow_task_checkbox_tile.dart';

DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

int _clampDayIndex(int raw, int harvestDurationDays) {
  final hi = max(0, harvestDurationDays - 1);
  if (raw < 0) return 0;
  if (raw > hi) return hi;
  return raw;
}

int _clampListIndex(int v, int length) {
  if (length <= 0) return 0;
  if (v < 0) return 0;
  if (v >= length) return length - 1;
  return v;
}

int _growDayIndex(GrowSession s, DateTime due) {
  final start = _dOnly(s.startedAt);
  final d = _dOnly(due);
  return _clampDayIndex(d.difference(start).inDays, s.harvestDurationDays);
}

List<GrowTask> _tasksForFarmPlanRow(GrowSession s, FarmPlanTask row) {
  final w = parseWeekNumberFromLabel(row.weekLabel);
  if (w == null) return [];
  final start = (w - 1) * 7;
  final end = min(start + 6, s.harvestDurationDays - 1);
  if (start > s.harvestDurationDays - 1) return [];
  final list = s.tasks.where((t) {
    final di = _growDayIndex(s, t.dueDate);
    return di >= start && di <= end;
  }).toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  return list;
}

(int done, int total) _countsForSlot(GrowSession s, FarmPlanTask row) {
  final list = _tasksForFarmPlanRow(s, row);
  var d = 0;
  for (final t in list) {
    if (t.completed) d++;
  }
  return (d, list.length);
}

int _defaultSlotIndex(List<FarmPlanTask> flat, GrowSession s) {
  if (flat.isEmpty) return 0;
  final t = DateTime.now();
  final start = _dOnly(s.startedAt);
  final dayIdx = _clampDayIndex(_dOnly(t).difference(start).inDays, s.harvestDurationDays);
  final currentWeek = dayIdx ~/ 7 + 1;
  var best = 0;
  var bestDist = 9999;
  for (var i = 0; i < flat.length; i++) {
    final w = parseWeekNumberFromLabel(flat[i].weekLabel);
    if (w == null) continue;
    final dist = (w - currentWeek).abs();
    if (dist < bestDist) {
      bestDist = dist;
      best = i;
    }
  }
  return _clampListIndex(best, flat.length);
}

/// One icon per farm-plan template row (same count/order as [FarmPlanMonthCards]).
class ActivityFarmingStagesSection extends ConsumerStatefulWidget {
  const ActivityFarmingStagesSection({
    super.key,
    required this.session,
    required this.startMonth1To12,
    this.selectedSlotIndex,
    this.onSlotChanged,
    this.sectionAnchorKey,
  });

  final GrowSession session;
  final int startMonth1To12;

  /// When non-null, highlights this template slot (0-based flat index).
  final int? selectedSlotIndex;

  final ValueChanged<int>? onSlotChanged;

  /// Optional key on the root column for [Scrollable.ensureVisible].
  final GlobalKey? sectionAnchorKey;

  @override
  ConsumerState<ActivityFarmingStagesSection> createState() => _ActivityFarmingStagesSectionState();
}

class _ActivityFarmingStagesSectionState extends ConsumerState<ActivityFarmingStagesSection> {
  int? _localSlot;

  @override
  void didUpdateWidget(covariant ActivityFarmingStagesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.gardenInstanceId != widget.session.gardenInstanceId ||
        oldWidget.startMonth1To12 != widget.startMonth1To12) {
      _localSlot = null;
    }
  }

  int _effectiveSlot(List<FarmPlanTask> flat, GrowSession session) {
    if (flat.isEmpty) return 0;
    if (widget.selectedSlotIndex != null) {
      return _clampListIndex(widget.selectedSlotIndex!, flat.length);
    }
    if (_localSlot != null) return _clampListIndex(_localSlot!, flat.length);
    return _defaultSlotIndex(flat, session);
  }

  void _setSlot(int i, List<FarmPlanTask> flat) {
    final clamped = _clampListIndex(i, flat.length);
    setState(() => _localSlot = clamped);
    widget.onSlotChanged?.call(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider) ?? widget.session;
    final flat = flattenFarmPlanTemplate(widget.startMonth1To12);
    if (flat.isEmpty) {
      return const SizedBox.shrink();
    }
    final slot = _effectiveSlot(flat, session);
    final row = flat[slot];
    final cs = Theme.of(context).colorScheme;
    final (done, total) = _countsForSlot(session, row);
    final slotTasks = _tasksForFarmPlanRow(session, row);

    return Column(
      key: widget.sectionAnchorKey,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.layers_outlined, size: 22, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l.tasks,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${session.plantName} · ${session.harvestDurationDays}-day grow · ${flat.length} weekly stages',
          style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: flat.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final t = flat[i];
              final sel = i == slot;
              final (d, tot) = _countsForSlot(session, t);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _setSlot(i, flat),
                child: SizedBox(
                  width: 82,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 68,
                            height: 68,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel ? cs.primary : t.iconBg,
                              border: Border.all(
                                color: sel ? cs.primary : cs.outline.withValues(alpha: 0.35),
                                width: sel ? 2.5 : 1,
                              ),
                            ),
                            child: Icon(
                              t.icon,
                              size: 28,
                              color: sel ? cs.onPrimary : t.iconColor,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Text(
                                tot == 0 ? '0/0' : '$d/$tot',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        t.weekLabel,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          color: sel ? cs.primary : cs.onSurface.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  row.weekLabel,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: cs.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  row.subtitle,
                  style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  '$done of $total scheduled tasks in this window',
                  style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.task_alt_outlined, size: 20, color: cs.onSurface),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Tasks: ${row.title}',
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (slotTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No calendar tasks fall in ${row.weekLabel} yet.',
                style: GoogleFonts.inter(color: GrowColors.gray600),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < slotTasks.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  GrowTaskCheckboxTile(key: ValueKey(slotTasks[i].id), taskId: slotTasks[i].id),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
