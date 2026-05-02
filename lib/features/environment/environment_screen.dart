import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/farm_plan_bootstrap.dart';
import '../../domain/grow_enums.dart';
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
  int _farmStartMonth = DateTime.now().month;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final m = ref.read(growStorageProvider).farmPlanStartMonthForPlant(widget.plantId);
      if (m != null && mounted) setState(() => _farmStartMonth = m);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
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
              l.farmStartMonthHint,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _farmStartMonth,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              items: List.generate(12, (i) {
                final m = i + 1;
                final d = DateTime(2000, m);
                return DropdownMenuItem(
                  value: m,
                  child: Text(loc.formatMonthYear(d)),
                );
              }),
              onChanged: _busy ? null : (v) => setState(() => _farmStartMonth = v ?? 1),
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
                        await storage.setFarmPlanStartMonth(plant.id, _farmStartMonth);
                        ref.read(localDataRevisionProvider.notifier).state++;
                        final repo = ref.read(geminiFarmPlanRepositoryProvider);
                        final rawPlan = await FarmPlanBootstrap.loadOrBuild(
                          repo: repo,
                          plant: plant,
                          farmStartMonth1To12: _farmStartMonth,
                          location: _loc,
                          sunlight: _sun,
                        );
                        final now = DateTime.now();
                        final start = DateTime(now.year, now.month, now.day);
                        final plan = FarmPlanBootstrap.anchorToGrowStart(rawPlan, start);
                        final usedAi = repo != null && !plan.summary.contains('Template plan');
                        await ref.read(sessionControllerProvider.notifier).startGrow(
                              plant: plant,
                              location: _loc,
                              sunlight: _sun,
                              farmPlanStartMonth1To12: _farmStartMonth,
                              farmPlan: plan,
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
