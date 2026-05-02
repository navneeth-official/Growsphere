import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/grow_session.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

const _staticBadgeMeta = <String, (String title, String desc)>{
  'badge_first_water': ('First drink', 'Logged your first watering'),
  'badge_thriving': ('Thriving', 'Plant health 90% or more'),
  'badge_task_master': ('Task master', 'Completed 20 care tasks'),
};

List<MapEntry<String, (String title, String desc)>> _badgeEntriesForSession(GrowSession s) {
  final out = <MapEntry<String, (String, String)>>[];
  for (final m in s.streakMilestoneDays) {
    out.add(
      MapEntry(
        'badge_streak_day_$m',
        (
          '$m-day streak',
          'Reach $m consecutive perfect task days for this crop.',
        ),
      ),
    );
  }
  out.addAll(_staticBadgeMeta.entries);
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
                    return Tooltip(
                      message: m.$2,
                      child: Chip(
                        avatar: Icon(earned ? Icons.emoji_events : Icons.lock_outline, size: 18),
                        label: Text(m.$1),
                        side: BorderSide(color: earned ? Colors.amber : Colors.grey),
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
