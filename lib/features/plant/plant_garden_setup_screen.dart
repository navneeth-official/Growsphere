import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/farm_plan_bootstrap.dart';
import '../../domain/grow_enums.dart';
import '../../domain/grow_session.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

final _setupPlantProvider = FutureProvider.family<Plant?, String>((ref, id) async {
  ref.watch(localDataRevisionProvider);
  return ref.read(plantRepositoryProvider).byId(id);
});

/// Month → location → sunlight → watering line → add to garden (single screen).
class PlantGardenSetupScreen extends ConsumerStatefulWidget {
  const PlantGardenSetupScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<PlantGardenSetupScreen> createState() => _PlantGardenSetupScreenState();
}

class _PlantGardenSetupScreenState extends ConsumerState<PlantGardenSetupScreen> {
  GrowLocationType _loc = GrowLocationType.balcony;
  SunlightLevel _sun = SunlightLevel.medium;
  int _farmStartMonth = DateTime.now().month;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final async = ref.watch(_setupPlantProvider(widget.plantId));
    return async.when(
      data: (plant) {
        if (plant == null) {
          return GrowSubpageScaffold(
            title: l.gardenSetupTitle,
            body: const Center(child: Text('Plant not found')),
          );
        }
        final rec = GrowSession.recommendationFor(
          wateringLevel: plant.wateringLevel,
          location: _loc,
          sun: _sun,
        );
        return GrowSubpageScaffold(
          title: l.gardenSetupTitle,
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(plant.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 20),
              Text(l.farmMonthLabel, style: Theme.of(context).textTheme.titleMedium),
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
              const SizedBox(height: 24),
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
              Text(l.wateringRecommendation, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(rec, style: Theme.of(context).textTheme.bodyMedium),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _busy
                    ? null
                    : () async {
                        setState(() => _busy = true);
                        try {
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
                          await ref.read(sessionControllerProvider.notifier).addGardenPlant(
                                plant: plant,
                                location: _loc,
                                sunlight: _sun,
                                farmPlanStartMonth1To12: _farmStartMonth,
                                farmPlan: plan,
                              );
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
                    : Text(l.addToGarden),
              ),
            ],
          ),
        );
      },
      loading: () => GrowSubpageScaffold(
        title: l.gardenSetupTitle,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => GrowSubpageScaffold(
        title: l.gardenSetupTitle,
        body: Center(child: Text('$e')),
      ),
    );
  }
}
