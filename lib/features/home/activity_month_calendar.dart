import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/activity_stage.dart';
import '../../domain/grow_session.dart';

DateTime _dOnly(DateTime d) => DateTime(d.year, d.month, d.day);

Color _fillForGrowDay(int dayIndex, int totalDays) {
  final stage = GrowSession.stageForDayIndex(dayIndex, totalDays);
  final dim = (dayIndex ~/ 7).isOdd ? 0.72 : 0.92;
  return switch (stage) {
    ActivityStage.soilPrep =>
      Color.lerp(Colors.brown.shade400, Colors.brown.shade200, 0.35)!.withValues(alpha: dim),
    ActivityStage.seeding => Colors.lightGreen.shade500.withValues(alpha: dim),
    ActivityStage.fertilizing => Colors.amber.shade600.withValues(alpha: dim),
    ActivityStage.harvesting => Colors.orange.shade500.withValues(alpha: dim),
  };
}

/// One month grid with prev/next; colours follow farm-plan blocks by week; tick = all tasks done.
class ActivityMonthCalendar extends StatefulWidget {
  const ActivityMonthCalendar({
    super.key,
    required this.session,
  });

  final GrowSession session;

  @override
  State<ActivityMonthCalendar> createState() => _ActivityMonthCalendarState();
}

class _ActivityMonthCalendarState extends State<ActivityMonthCalendar> {
  late DateTime _visibleMonth;

  void _initVisibleMonthForSession() {
    final now = DateTime.now();
    final start = _dOnly(widget.session.startedAt);
    final end = start.add(Duration(days: max(0, widget.session.harvestDurationDays - 1)));
    final cur = _dOnly(now);
    if (cur.isBefore(start)) {
      _visibleMonth = DateTime(start.year, start.month);
    } else if (cur.isAfter(end)) {
      _visibleMonth = DateTime(end.year, end.month);
    } else {
      _visibleMonth = DateTime(now.year, now.month);
    }
  }

  @override
  void initState() {
    super.initState();
    _initVisibleMonthForSession();
  }

  @override
  void didUpdateWidget(covariant ActivityMonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.startedAt != widget.session.startedAt ||
        oldWidget.session.harvestDurationDays != widget.session.harvestDurationDays) {
      _initVisibleMonthForSession();
    }
  }

  DateTime get _sessionStart => _dOnly(widget.session.startedAt);
  int get _n => widget.session.harvestDurationDays;
  DateTime get _sessionEnd => _sessionStart.add(Duration(days: max(0, _n - 1)));

  bool _monthOverlapsSession() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month);
    final last = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
    return !last.isBefore(_sessionStart) && !first.isAfter(_sessionEnd);
  }

  void _prevMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
      final first = DateTime(_visibleMonth.year, _visibleMonth.month);
      if (first.isAfter(_sessionEnd)) {
        _visibleMonth = DateTime(_sessionEnd.year, _sessionEnd.month);
      }
    });
  }

  void _nextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
      final first = DateTime(_visibleMonth.year, _visibleMonth.month);
      final lastOfVm = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0);
      if (lastOfVm.isBefore(_sessionStart)) {
        _visibleMonth = DateTime(_sessionStart.year, _sessionStart.month);
      } else if (first.isAfter(_sessionEnd)) {
        _visibleMonth = DateTime(_sessionEnd.year, _sessionEnd.month);
      }
    });
  }

  int? _dayOffsetInGrow(DateTime day) {
    final d = _dOnly(day);
    if (d.isBefore(_sessionStart) || d.isAfter(_sessionEnd)) return null;
    return d.difference(_sessionStart).inDays;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final firstDowIdx = loc.firstDayOfWeekIndex;
    // narrowWeekdays is Sunday-first; index 0 → Sunday (weekday 7).
    final firstWeekday = firstDowIdx == 0 ? DateTime.sunday : firstDowIdx;
    final firstOfMonth = DateTime(_visibleMonth.year, _visibleMonth.month);
    final daysInMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final lead = (firstOfMonth.weekday - firstWeekday + 7) % 7;

    final monthLabel = loc.formatMonthYear(_visibleMonth);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _prevMonth,
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous month',
            ),
            Expanded(
              child: Text(
                monthLabel,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ),
            IconButton(
              onPressed: _nextMonth,
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next month',
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (!_monthOverlapsSession())
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'No grow activity in this month.',
              style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
            ),
          ),
        Row(
          children: List.generate(7, (i) {
            final label = loc.narrowWeekdays[(i + firstDowIdx) % 7];
            return Expanded(
              child: Center(
                child: Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: GrowColors.gray600),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.05,
          ),
          itemCount: lead + daysInMonth,
          itemBuilder: (context, i) {
            if (i < lead) return const SizedBox.shrink();
            final dom = i - lead + 1;
            final day = DateTime(_visibleMonth.year, _visibleMonth.month, dom);
            final off = _dayOffsetInGrow(day);
            if (off == null) {
              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: GrowColors.gray50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '$dom',
                  style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray400),
                ),
              );
            }
            final fill = _fillForGrowDay(off, _n);
            final tick = GrowSession.allDueTasksCompleteForDay(widget.session, day);
            return Tooltip(
              message: '${day.month}/${day.day} · grow day ${off + 1} of $_n',
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.colorScheme.outlineVariant),
                    ),
                    child: Text(
                      '$dom',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.88),
                      ),
                    ),
                  ),
                  if (tick)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Icon(Icons.check_circle, size: 16, color: GrowColors.green700),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'Colours: week 1 = soil prep, then 2-week blocks (establish → feed → finish). '
          'A tick appears when every task due that day is completed.',
          style: GoogleFonts.inter(fontSize: 11, color: GrowColors.gray600, height: 1.35),
        ),
      ],
    );
  }
}
