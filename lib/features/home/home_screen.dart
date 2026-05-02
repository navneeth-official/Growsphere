import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/grow_session.dart';
import '../../providers/providers.dart';
import '../calendar/farm_plan_month_cards.dart';
import '../shell/grow_layout.dart';
import 'activity_farming_stages_section.dart';
import 'activity_month_calendar.dart';
import 'task_scope_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scroll = ScrollController();
  final GlobalKey _stagesSectionKey = GlobalKey();

  /// Negative: let [ActivityFarmingStagesSection] pick default from grow dates.
  int _selectedFarmPlanSlot = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final n = ref.read(notificationServiceProvider);
      await n.requestPermissionsIfNeeded();
      await n.scheduleWaterReminders();
      if (!mounted) return;
      final s = ref.read(sessionControllerProvider);
      if (s != null) await _syncFarmDigest(s);
    });
  }

  Future<void> _syncFarmDigest(GrowSession session) async {
    final n = ref.read(notificationServiceProvider);
    final storage = ref.read(growStorageProvider);
    final today = DateTime.now();
    final d = DateTime(today.year, today.month, today.day);
    final lines = session.tasks.where((t) {
      if (t.completed) return false;
      final dd = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return dd == d;
    }).take(5).map((t) => '• ${t.title}').join('\n');
    final body = lines.isEmpty
        ? 'No open tasks for ${session.plantName} today — check Growsphere anytime.'
        : 'Tasks for ${session.plantName}:\n$lines';
    await n.scheduleFarmTasksDigest(body);
    await n.rescheduleTaskDeadlineReminders(plantName: session.plantName, tasks: session.tasks);
    await n.scheduleSensorReadingReminders();
    await n.scheduleEodIncompleteReminder();
    await n.cancelPendingTaskNudges();
    if (storage.pushNotificationsEnabled) {
      await n.reschedulePendingTaskNudges(
        plantName: session.plantName,
        tasks: session.tasks,
        currentStreak: session.streak,
        bestStreak: session.bestStreak,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    ref.listen<GrowSession?>(sessionControllerProvider, (prev, next) {
      if (next != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncFarmDigest(next);
        });
      } else {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          final n = ref.read(notificationServiceProvider);
          await n.cancelFarmTasksDigest();
          await n.cancelTaskDeadlineReminders();
          await n.cancelSensorReadingReminders();
          await n.cancelEodIncompleteReminder();
          await n.cancelPendingTaskNudges();
        });
      }
    });
    final storage = ref.watch(growStorageProvider);
    ref.watch(localDataRevisionProvider);
    if (session == null) {
      return GrowLayout(
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.spa_outlined, size: 56, color: GrowColors.gray400),
              const SizedBox(height: 16),
              Text(
                'No active grow',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                l.openPlantCatalog,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: GrowColors.gray600),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/plants'),
                child: Text(l.tabPlants),
              ),
            ],
          ),
        ),
      );
    }
    final startM = storage.farmPlanStartMonthForPlant(session.plantId) ?? session.startedAt.month;
    return GrowLayout(
      body: ListView(
        controller: _scroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            session.plantName,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          FarmPlanMonthCards(
            startMonth1To12: startM,
            sectionTitle: l.farmPlanningSectionTitle,
            onTemplateRowTap: (flatIndex) {
              setState(() => _selectedFarmPlanSlot = flatIndex);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final ctx = _stagesSectionKey.currentContext;
                if (ctx != null && mounted) {
                  Scrollable.ensureVisible(
                    ctx,
                    alignment: 0.12,
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeInOutCubic,
                  );
                }
              });
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _StatCard(title: l.plantHealth, value: '${session.plantHealth}%'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(title: 'Grow cycle', value: '${session.harvestDurationDays} days'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l.wateringRecommendation, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(session.wateringRecommendationText, style: GoogleFonts.inter(color: GrowColors.gray600)),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => _onWatered(context),
            icon: const Icon(Icons.water_drop),
            label: Text(l.iWatered),
          ),
          const SizedBox(height: 24),
          ActivityFarmingStagesSection(
            session: session,
            startMonth1To12: startM,
            selectedSlotIndex: _selectedFarmPlanSlot < 0 ? null : _selectedFarmPlanSlot,
            onSlotChanged: (i) => setState(() => _selectedFarmPlanSlot = i),
            sectionAnchorKey: _stagesSectionKey,
          ),
          const SizedBox(height: 24),
          FarmStreakCard(session: session),
          const SizedBox(height: 16),
          Text(l.activityCalendar, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ActivityMonthCalendar(session: session),
        ],
      ),
    );
  }

  Future<void> _onWatered(BuildContext context) async {
    await ref.read(growStorageProvider).setPendingSprinklerFromCalendar(true);
    if (!context.mounted) return;
    context.push('/sprinkler?autoWater=1');
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500, fontSize: 13)),
            Text(value, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}
