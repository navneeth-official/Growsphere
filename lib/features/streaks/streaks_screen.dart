import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/badge_catalog.dart';
import '../../domain/grow_session.dart';
import '../../providers/providers.dart';
import '../../widgets/badge_medallion.dart';
import '../shell/grow_tools_sheet.dart';

/// Main streaks chart + badge strip. Deeper history lives in [StreakHubScreen] (`/streak-hub`).
List<MapEntry<String, (String title, String desc)>> _badgeEntriesForSession(GrowSession s) {
  final out = <MapEntry<String, (String, String)>>[];
  for (final m in s.streakMilestoneDays) {
    final id = 'badge_streak_day_$m';
    out.add(
      MapEntry(
        id,
        (
          BadgeCatalog.streakMilestoneTitle(m),
          BadgeCatalog.descriptionFor(id),
        ),
      ),
    );
  }
  for (final id in BadgeCatalog.allStaticBadgeIds) {
    out.add(MapEntry(id, (BadgeCatalog.titleFor(id), BadgeCatalog.descriptionFor(id))));
  }
  return out;
}

class StreaksScreen extends ConsumerWidget {
  const StreaksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    return GrowSubpageScaffold(
      title: l.streaksBadges,
      appBarActions: [
        IconButton(
          tooltip: 'History & milestones',
          icon: const Icon(Icons.insights_outlined),
          onPressed: () => context.push('/streak-hub'),
        ),
      ],
      body: session == null
          ? const Center(child: Text('Start a grow to see streaks'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'The chart shows your streak count after each day you cleared every due task.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 220,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                      child: _StreakChart(streakByDay: session.streakByDay),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('Badges', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _badgeEntriesForSession(session).map<Widget>((e) {
                    final earned = session.earnedBadgeIds.contains(e.key);
                    final m = e.value;
                    final cs = Theme.of(context).colorScheme;
                    return Tooltip(
                      message: m.$2,
                      child: Chip(
                        avatar: Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: earned
                              ? BadgeMedallion(badgeId: e.key, size: 24, unlocked: true)
                              : BadgeMedallion(badgeId: e.key, size: 24, unlocked: false),
                        ),
                        label: Text(m.$1),
                        side: BorderSide(
                          color: earned ? Colors.amber : cs.outline.withValues(alpha: 0.5),
                        ),
                        backgroundColor: earned
                            ? Color.alphaBlend(Colors.amber.withValues(alpha: 0.15), cs.surfaceContainerHighest)
                            : cs.surfaceContainerHighest,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}

class _StreakChart extends StatelessWidget {
  const _StreakChart({required this.streakByDay});

  final Map<String, int> streakByDay;

  @override
  Widget build(BuildContext context) {
    final keys = streakByDay.keys.toList()..sort();
    if (keys.isEmpty) {
      return const Center(child: Text('Water on schedule to build your streak graph'));
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < keys.length; i++) {
      spots.add(FlSpot(i.toDouble(), streakByDay[keys[i]]!.toDouble()));
    }
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.isEmpty ? 1 : spots.length - 1.0,
        minY: 0,
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              getTitlesWidget: (v, m) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10)),
            ),
          ),
          bottomTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }
}
