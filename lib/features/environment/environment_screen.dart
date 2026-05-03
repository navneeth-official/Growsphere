import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/farm_plan_bootstrap.dart';
import '../../domain/grow_enums.dart';
import '../../domain/grow_session.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

class EnvironmentScreen extends ConsumerStatefulWidget {
  const EnvironmentScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends ConsumerState<EnvironmentScreen> {
  GrowLocationType _loc = GrowLocationType.balcony;
  SunlightLevel _sun = SunlightLevel.medium;
  late DateTime _farmStartDate;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final today = GrowSession.calendarDay(DateTime.now());
    _farmStartDate = today;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = ref.read(growStorageProvider).farmPlanStartMonthForPlant(widget.plantId);
      if (!mounted) return;
      if (m != null) {
        final now = DateTime.now();
        var pick = DateTime(now.year, m, 1);
        if (pick.isBefore(today)) pick = today;
        setState(() => _farmStartDate = pick);
      }
    });
  }

  Future<void> _pickFarmStartDate(BuildContext context) async {
    if (_busy) return;
    final today = GrowSession.calendarDay(DateTime.now());
    final initial = _farmStartDate.isBefore(today) ? today : _farmStartDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 730)),
    );
    if (picked != null && mounted) {
      setState(() => _farmStartDate = GrowSession.calendarDay(picked));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowSubpageScaffold(
      title: l.environmentTitle,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.locationLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<GrowLocationType>(
              segments: [
                ButtonSegment(value: GrowLocationType.indoor, label: Text(l.indoor)),
                ButtonSegment(value: GrowLocationType.balcony, label: Text(l.balcony)),
                ButtonSegment(value: GrowLocationType.terrace, label: Text(l.terrace)),
              ],
              selected: {_loc},
              onSelectionChanged: (s) => setState(() => _loc = s.first),
            ),
            const SizedBox(height: 24),
            Text(l.sunlightLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<SunlightLevel>(
              segments: [
                ButtonSegment(value: SunlightLevel.low, label: Text(l.sunLow)),
                ButtonSegment(value: SunlightLevel.medium, label: Text(l.sunMedium)),
                ButtonSegment(value: SunlightLevel.high, label: Text(l.sunHigh)),
              ],
              selected: {_sun},
              onSelectionChanged: (s) => setState(() => _sun = s.first),
            ),
            const SizedBox(height: 24),
            Text(l.whenPlanFarmTitle, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Pick the first day of farming (today or a future date). Past dates are not available.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.45)),
              ),
              leading: Icon(Icons.calendar_month, color: Theme.of(context).colorScheme.primary),
              title: Text(
                MaterialLocalizations.of(context).formatFullDate(_farmStartDate),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              subtitle: const Text('Tap to change'),
              trailing: const Icon(Icons.edit_calendar_outlined),
              onTap: _busy ? null : () => _pickFarmStartDate(context),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _busy
                  ? null
                  : () async {
                      setState(() => _busy = true);
                      try {
                        final plant = await ref.read(plantRepositoryProvider).byId(widget.plantId);
                        if (plant == null || !context.mounted) return;
                        final storage = ref.read(growStorageProvider);
                        final farmMonth = _farmStartDate.month;
                        await storage.setFarmPlanStartMonth(plant.id, farmMonth);
                        ref.read(localDataRevisionProvider.notifier).state++;
                        final repo = ref.read(geminiFarmPlanRepositoryProvider);
                        final rawPlan = await FarmPlanBootstrap.loadOrBuild(
                          repo: repo,
                          plant: plant,
                          farmStartMonth1To12: farmMonth,
                          location: _loc,
                          sunlight: _sun,
                        );
                        final farmDay = GrowSession.calendarDay(_farmStartDate);
                        final plan = FarmPlanBootstrap.anchorToGrowStart(rawPlan, farmDay);
                        final usedAi = repo != null && !plan.summary.contains('Template plan');
                        await ref.read(sessionControllerProvider.notifier).startGrow(
                              plant: plant,
                              location: _loc,
                              sunlight: _sun,
                              farmPlanStartMonth1To12: farmMonth,
                              farmPlan: plan,
                              farmingCalendarStart: farmDay,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                usedAi
                                    ? 'AI calendar created for ${plant.name}.'
                                    : 'Using built-in template calendar (add Gemini API key for crop-specific AI plans).',
                              ),
                            ),
                          );
                        }
                        if (context.mounted) context.go('/garden');
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l.createActivityCalendar),
            ),
          ],
        ),
      ),
    );
  }
}
