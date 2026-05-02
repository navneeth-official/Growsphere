import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/activity_stage.dart';
import '../../domain/grow_session.dart';
import '../../domain/grow_task.dart';
import '../../providers/providers.dart';
import 'grow_task_checkbox_tile.dart';

DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

ActivityStage _stageForToday(GrowSession s) {
  final t = DateTime.now();
  final start = _dOnly(s.startedAt);
  final diff = _dOnly(t).difference(start).inDays;
  if (diff < 0) return ActivityStage.soilPrep;
  final idx = diff.clamp(0, s.harvestDurationDays - 1);
  return s.activityStageForGrowDay(idx);
}

IconData _iconForStage(ActivityStage st) {
  return switch (st) {
    ActivityStage.soilPrep => Icons.landscape_outlined,
    ActivityStage.seeding => Icons.spa_outlined,
    ActivityStage.fertilizing => Icons.science_outlined,
    ActivityStage.harvesting => Icons.agriculture_outlined,
  };
}

String _shortLabel(ActivityStage st) {
  return switch (st) {
    ActivityStage.soilPrep => 'Soil prep',
    ActivityStage.seeding => 'Seeding',
    ActivityStage.fertilizing => 'Feeding',
    ActivityStage.harvesting => 'Harvest',
  };
}

String _stageDescription(GrowSession s, ActivityStage stage) {
  final plan = s.farmPlanOrNull;
  if (plan != null && plan.stages.isNotEmpty) {
    final ranges = plan.stages.where((r) => r.stage == stage).toList();
    if (ranges.isNotEmpty) {
      final r = ranges.first;
      return '${r.name} (days ${r.startDay + 1}–${r.endDay + 1}): follow the checklist below to stay on track for this block.';
    }
  }
  return switch (stage) {
    ActivityStage.soilPrep =>
      'Bed prep, compost, drainage, and pH checks set the foundation before you sow or transplant.',
    ActivityStage.seeding =>
      'Keep seedbeds evenly moist, protect from pests, and thin or transplant as seedlings establish.',
    ActivityStage.fertilizing =>
      'Side-dress, foliar feeds, and steady watering move the crop through vigorous growth.',
    ActivityStage.harvesting =>
      'Harvest on time, watch quality, and ease watering slightly as the crop finishes.',
  };
}

(int done, int total) _countsForStage(GrowSession s, ActivityStage stage) {
  var t = 0;
  var d = 0;
  for (final x in s.tasks) {
    if (x.stage != stage) continue;
    t++;
    if (x.completed) d++;
  }
  return (d, t);
}

/// Horizontal stage strip, stage blurb, and tasks for the selected stage.
class ActivityFarmingStagesSection extends ConsumerStatefulWidget {
  const ActivityFarmingStagesSection({super.key, required this.session});

  final GrowSession session;

  @override
  ConsumerState<ActivityFarmingStagesSection> createState() => _ActivityFarmingStagesSectionState();
}

class _ActivityFarmingStagesSectionState extends ConsumerState<ActivityFarmingStagesSection> {
  ActivityStage? _picked;

  @override
  void didUpdateWidget(covariant ActivityFarmingStagesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.gardenInstanceId != widget.session.gardenInstanceId) {
      _picked = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider) ?? widget.session;
    final auto = _stageForToday(session);
    final stage = _picked ?? auto;
    final cs = Theme.of(context).colorScheme;
    final stages = ActivityStage.values;
    final (done, total) = _countsForStage(session, stage);
    final stageTasks = session.tasks.where((t) => t.stage == stage).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Column(
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
          '${session.plantName} · ${session.harvestDurationDays}-day grow · tap a stage icon',
          style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 118,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: stages.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final st = stages[i];
              final sel = st == stage;
              final (d, t) = _countsForStage(session, st);
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => setState(() => _picked = st),
                child: SizedBox(
                  width: 86,
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: sel ? cs.primary : cs.surfaceContainerHighest,
                              border: Border.all(
                                color: sel ? cs.primary : cs.outline.withValues(alpha: 0.4),
                                width: sel ? 2.5 : 1,
                              ),
                            ),
                            child: Icon(
                              _iconForStage(st),
                              size: 32,
                              color: sel ? cs.onPrimary : cs.onSurface,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade700,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white, width: 1),
                              ),
                              child: Text(
                                t == 0 ? '0/0' : '$d/$t',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
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
                        _shortLabel(st),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                          color: sel ? cs.primary : cs.onSurface.withValues(alpha: 0.85),
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
                  _shortLabel(stage),
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 8),
                Text(
                  _stageDescription(session, stage),
                  style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: cs.onSurface),
                ),
                const SizedBox(height: 6),
                Text(
                  '$done of $total tasks done in this stage',
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
            Text(
              'Tasks: ${_shortLabel(stage)}',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (stageTasks.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No tasks tagged for this stage.',
                style: GoogleFonts.inter(color: GrowColors.gray600),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (var i = 0; i < stageTasks.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: cs.outline.withValues(alpha: 0.2)),
                  GrowTaskCheckboxTile(key: ValueKey(stageTasks[i].id), taskId: stageTasks[i].id),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
