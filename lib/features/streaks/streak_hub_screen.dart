import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/grow_session.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

const _staticBadgeCopy = <String, (String title, String desc)>{
  'badge_first_water': ('First drink', 'Logged your first watering'),
  'badge_thriving': ('Thriving', 'Plant health reached 90% or more'),
  'badge_task_master': ('Task master', 'Completed 20 care tasks'),
};

class StreakHubScreen extends ConsumerWidget {
  const StreakHubScreen({super.key});

  static List<(String id, String title, String desc)> _milestoneBadges(GrowSession s) {
    return [
      for (final m in s.streakMilestoneDays)
        (
          'badge_streak_day_$m',
          '$m-day streak',
          'Reach $m consecutive perfect task days for this crop.',
        ),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final archives = ref.watch(growStorageProvider).loadGrowArchives();

    return GrowSubpageScaffold(
      title: 'Streaks & history',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            'Streak badges are tied to this crop’s AI plan. Milestone day counts change with harvest length and stages.',
            style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: GrowColors.gray600),
          ),
          const SizedBox(height: 20),
          if (session != null) ...[
            Text('This grow', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            _sessionSummaryCard(session),
            const SizedBox(height: 12),
            Text('Milestone targets', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            ...session.streakMilestoneDays.map((m) => _milestoneTile(session, m)),
            const SizedBox(height: 16),
            Text('Badges (this season)', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 8),
            _badgeWrap(session, includeMilestones: true),
            if (session.farmPlanOrNull?.summary.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Text('Plan summary', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 6),
              Text(
                session.farmPlanOrNull!.summary,
                style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: GrowColors.gray700),
              ),
            ],
          ] else
            Text(
              'Start a grow to see live milestones. Past seasons appear below.',
              style: GoogleFonts.inter(color: GrowColors.gray600),
            ),
          const SizedBox(height: 24),
          Text('Past seasons', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 8),
          if (archives.isEmpty)
            Text(
              'Finished grows will show here with their best streak and badges.',
              style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600, height: 1.35),
            )
          else
            ...archives.map((raw) => _ArchiveCard(raw: raw)),
        ],
      ),
    );
  }

  Widget _sessionSummaryCard(GrowSession s) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: GrowColors.gray200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.plantName, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17)),
            const SizedBox(height: 6),
            Text(
              'Current streak: ${s.streak} · Best: ${s.bestStreak} · Vitality: ${s.plantHealth}%',
              style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray700, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }

  Widget _milestoneTile(GrowSession s, int m) {
    final earned = s.streak >= m;
    final id = 'badge_streak_day_$m';
    final hasBadge = s.earnedBadgeIds.contains(id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Card(
        elevation: 0,
        color: earned ? GrowColors.green100.withValues(alpha: 0.35) : GrowColors.gray50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: earned ? GrowColors.green600 : GrowColors.gray200),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            hasBadge ? Icons.emoji_events : Icons.flag_outlined,
            color: hasBadge ? Colors.amber.shade800 : GrowColors.gray500,
          ),
          title: Text('$m perfect days', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          subtitle: Text(
            earned ? 'Unlocked — keep the chain going.' : '${m - s.streak} more perfect day(s) to go.',
            style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
          ),
        ),
      ),
    );
  }

  Widget _badgeWrap(GrowSession s, {required bool includeMilestones}) {
    final entries = <MapEntry<String, (String, String)>>[];
    if (includeMilestones) {
      for (final t in _milestoneBadges(s)) {
        entries.add(MapEntry(t.$1, (t.$2, t.$3)));
      }
    }
    entries.addAll(_staticBadgeCopy.entries);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: entries.map((e) {
        final earned = s.earnedBadgeIds.contains(e.key);
        final m = e.value;
        return Tooltip(
          message: m.$2,
          child: Chip(
            avatar: Icon(earned ? Icons.emoji_events : Icons.lock_outline, size: 18),
            label: Text(m.$1, style: GoogleFonts.inter(fontSize: 12)),
            side: BorderSide(color: earned ? Colors.amber.shade700 : GrowColors.gray300),
          ),
        );
      }).toList(),
    );
  }
}

class _ArchiveCard extends StatelessWidget {
  const _ArchiveCard({required this.raw});

  final Map<String, dynamic> raw;

  @override
  Widget build(BuildContext context) {
    GrowSession? s;
    try {
      s = GrowSession.fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return const SizedBox.shrink();
    }
    final at = raw['archivedAt']?.toString() ?? '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: GrowColors.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      s.plantName,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                    ),
                  ),
                  Text(
                    at.length > 10 ? at.substring(0, 10) : at,
                    style: GoogleFonts.inter(fontSize: 11, color: GrowColors.gray500),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Best streak: ${s.bestStreak}',
                style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: s.earnedBadgeIds
                    .map(
                      (id) => Chip(
                        label: Text(
                          id.replaceFirst('badge_', '').replaceAll('_', ' '),
                          style: GoogleFonts.inter(fontSize: 11),
                        ),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: GrowColors.gray100,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
