import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/farm_plan_bootstrap.dart';
import '../../core/network/image_request_headers.dart';
import '../../core/theme/grow_colors.dart';
import '../../domain/grow_enums.dart';
import '../../domain/grow_session.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

final _setupPlantProvider = FutureProvider.family<Plant?, String>((ref, id) async {
  ref.watch(localDataRevisionProvider);
  return ref.read(plantRepositoryProvider).byId(id);
});

int _growthMonthsFromHarvestDays(int days) => (days / 30).round().clamp(1, 36);

/// Crop encyclopedia + month / location / sunlight / watering → add to garden.
class PlantGardenSetupScreen extends ConsumerStatefulWidget {
  const PlantGardenSetupScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<PlantGardenSetupScreen> createState() => _PlantGardenSetupScreenState();
}

class _PlantGardenSetupScreenState extends ConsumerState<PlantGardenSetupScreen> {
  GrowLocationType _loc = GrowLocationType.balcony;
  SunlightLevel _sun = SunlightLevel.medium;
  late DateTime _farmStartDate;
  bool _busy = false;
  String? _aiWaterNote;
  bool _aiWaterLoading = false;
  Timer? _aiDebounce;
  String? _lastScheduledAiPlant;

  @override
  void dispose() {
    _aiDebounce?.cancel();
    super.dispose();
  }

  void _scheduleAiWaterSuggestion(Plant plant) {
    _aiDebounce?.cancel();
    _aiDebounce = Timer(const Duration(milliseconds: 450), () => _runAiWaterSuggestion(plant));
  }

  Future<void> _runAiWaterSuggestion(Plant plant) async {
    final g = ref.read(geminiGenerativeServiceProvider);
    if (g == null) {
      if (mounted) setState(() => _aiWaterNote = null);
      return;
    }
    if (!mounted) return;
    setState(() {
      _aiWaterLoading = true;
      _aiWaterNote = null;
    });
    final locName = switch (_loc) {
      GrowLocationType.indoor => 'indoor',
      GrowLocationType.balcony => 'balcony',
      GrowLocationType.terrace => 'terrace',
    };
    final sunName = switch (_sun) {
      SunlightLevel.low => 'low',
      SunlightLevel.medium => 'medium',
      SunlightLevel.high => 'high',
    };
    try {
      final text = await g.generateText(
        systemInstruction:
            'You advise on watering frequency for one potted/balcony crop. Output 2–3 short sentences only. Plain text. '
            'Do not invent weather numbers. Base advice only on plant water need, location type, and sunlight level given.',
        userText:
            'Plant: ${plant.name}. Catalog watering tag: ${plant.wateringLevel}. Location: $locName. Sunlight: $sunName. '
            'Give practical water rhythm (how often to check soil, signs of dry vs soggy).',
      );
      if (!mounted) return;
      setState(() {
        _aiWaterNote = text.trim().isEmpty ? null : text.trim();
        _aiWaterLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _aiWaterLoading = false);
    }
  }

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
    final async = ref.watch(_setupPlantProvider(widget.plantId));
    return async.when(
      data: (plant) {
        if (plant == null) {
          return GrowSubpageScaffold(
            title: l.gardenSetupTitle,
            body: const Center(child: Text('Plant not found')),
          );
        }
        final cs = Theme.of(context).colorScheme;
        final growthMonths = _growthMonthsFromHarvestDays(plant.harvestDurationDays);
        final pid = plant.id;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_lastScheduledAiPlant != pid) {
            _lastScheduledAiPlant = pid;
            _scheduleAiWaterSuggestion(plant);
          }
        });
        return GrowSubpageScaffold(
          title: l.gardenSetupTitle,
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (plant.imageUrl != null && plant.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: plant.imageUrl!.startsWith('http')
                        ? Image.network(
                            plant.imageUrl!,
                            fit: BoxFit.cover,
                            headers: ImageRequestHeaders.standard,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                          )
                        : Image.file(
                            File(plant.imageUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                          ),
                  ),
                ),
              if (plant.imageUrl != null && plant.imageUrl!.isNotEmpty) const SizedBox(height: 16),
              Text(
                plant.name,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${l.difficulty}: ${plant.difficulty}')),
                  Chip(label: Text('${l.watering}: ${plant.wateringLevel}')),
                  Chip(label: Text(l.growthPeriodMonths(growthMonths))),
                  Chip(label: Text('${plant.harvestDurationDays} d harvest')),
                ],
              ),
              const SizedBox(height: 16),
              _infoCard(
                colorScheme: cs,
                icon: Icons.thermostat,
                iconColor: const Color(0xFFEA580C),
                title: l.climateRequirementsTitle,
                body: plant.climate,
              ),
              const SizedBox(height: 12),
              _infoCard(
                colorScheme: cs,
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF2563EB),
                title: l.soilRequirementsTitle,
                body: plant.soil,
              ),
              const SizedBox(height: 12),
              _infoCard(
                colorScheme: cs,
                icon: Icons.eco,
                iconColor: GrowColors.green600,
                title: l.fertilizerNeedsTitle,
                body: plant.fertilizers,
              ),
              const SizedBox(height: 28),
              Text(
                l.farmPlanningSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Text('When does farming start?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                'Pick today or a future date. Future starts stay in your garden as scheduled until that day.',
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
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                subtitle: Text(
                  'Tap to change',
                  style: GoogleFonts.inter(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: _busy ? null : () => _pickFarmStartDate(context),
              ),
              const SizedBox(height: 24),
              Text(l.locationLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<GrowLocationType>(
                segments: [
                  ButtonSegment(value: GrowLocationType.indoor, label: Text(l.indoor)),
                  ButtonSegment(value: GrowLocationType.balcony, label: Text(l.balcony)),
                  ButtonSegment(value: GrowLocationType.terrace, label: Text(l.terrace)),
                ],
                selected: {_loc},
                onSelectionChanged: (s) {
                  setState(() => _loc = s.first);
                  _scheduleAiWaterSuggestion(plant);
                },
              ),
              const SizedBox(height: 24),
              Text(l.sunlightLabel, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              SegmentedButton<SunlightLevel>(
                segments: [
                  ButtonSegment(value: SunlightLevel.low, label: Text(l.sunLow)),
                  ButtonSegment(value: SunlightLevel.medium, label: Text(l.sunMedium)),
                  ButtonSegment(value: SunlightLevel.high, label: Text(l.sunHigh)),
                ],
                selected: {_sun},
                onSelectionChanged: (s) {
                  setState(() => _sun = s.first);
                  _scheduleAiWaterSuggestion(plant);
                },
              ),
              const SizedBox(height: 24),
              Text('AI watering note', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Text(
                'Based on your location and sunlight. This text is saved as your crop’s watering tip when you add to the garden.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cs.primaryContainer.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _aiWaterLoading
                      ? const Row(
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            SizedBox(width: 12),
                            Expanded(child: Text('Getting a tailored suggestion…')),
                          ],
                        )
                      : Text(
                          _aiWaterNote ??
                              'Adjust location or sunlight above for an AI suggestion (needs Gemini API key).',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
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
                          final fallbackRec = GrowSession.recommendationFor(
                            wateringLevel: plant.wateringLevel,
                            location: _loc,
                            sun: _sun,
                          );
                          final waterTxt =
                              (_aiWaterNote?.trim().isNotEmpty ?? false) ? _aiWaterNote!.trim() : fallbackRec;
                          await ref.read(sessionControllerProvider.notifier).addGardenPlant(
                                plant: plant,
                                location: _loc,
                                sunlight: _sun,
                                farmPlanStartMonth1To12: farmMonth,
                                farmPlan: plan,
                                farmingCalendarStart: farmDay,
                                wateringRecommendationText: waterTxt,
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

Widget _infoCard({
  required ColorScheme colorScheme,
  required IconData icon,
  required Color iconColor,
  required String title,
  required String body,
}) {
  final cs = colorScheme;
  return Card(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  body,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
