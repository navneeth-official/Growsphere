import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/plant_catalog_image.dart';
import '../../core/theme/grow_colors.dart';
import '../../data/weather_repository.dart';
import '../../domain/grow_enums.dart';
import '../../domain/grow_session.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';
import 'garden_weather_banner.dart';

final _gardenCardPlantProvider = FutureProvider.family<Plant?, String>((ref, id) async {
  ref.watch(localDataRevisionProvider);
  return ref.read(plantRepositoryProvider).byId(id);
});

class MyGardenScreen extends ConsumerStatefulWidget {
  const MyGardenScreen({super.key});

  @override
  ConsumerState<MyGardenScreen> createState() => _MyGardenScreenState();
}

class _MyGardenScreenState extends ConsumerState<MyGardenScreen> {
  WeatherSnapshot? _weather;
  String? _weatherErr;
  bool _weatherLoading = true;
  String? _placeLabel;
  String? _gardenTip;
  bool _tipLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWeatherAndTip();
      ref.read(notificationServiceProvider).rescheduleScheduledGrowReminders(ref.read(gardenListProvider));
    });
  }

  Future<void> _loadWeatherAndTip() async {
    setState(() {
      _weatherLoading = true;
      _weatherErr = null;
      _placeLabel = null;
    });
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission p = perm;
      if (perm == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        setState(() {
          _weatherErr = 'denied';
          _weatherLoading = false;
        });
        await _loadTip(null);
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      ref.read(reverseGeocodeServiceProvider).placeLabel(pos.latitude, pos.longitude).then((label) {
        if (!mounted || label == null) return;
        setState(() => _placeLabel = label);
      });
      WeatherSnapshot? w;
      Object? fetchErr;
      try {
        w = await ref.read(weatherRepositoryProvider).fetch(pos.latitude, pos.longitude);
      } catch (e) {
        fetchErr = e;
        final g = ref.read(geminiGenerativeServiceProvider);
        if (g != null) {
          try {
            final month = DateTime.now().month;
            final raw = await g.generateText(
              systemInstruction:
                  'You are a weather fallback because live HTTP weather APIs failed. Output ONLY one JSON object. '
                  'Keys: temperatureC (number), humidityPct (number or null), windKmh (number or null), '
                  'rainChancePct (0-100 or null), wmoWeatherCode (integer 0-99, WMO style). '
                  'Use conservative seasonal normals for the latitude band and calendar month only. '
                  'Do not invent storms, heat waves, or snow unless typical for that band in that month. '
                  'If you cannot estimate, output exactly {"error":"cannot_estimate"}. No markdown, no extra text.',
              userText:
                  'Latitude ${pos.latitude} Longitude ${pos.longitude} Month $month. JSON only.',
            );
            w = WeatherRepository.tryParseAiEstimateJson(raw, pos.latitude, pos.longitude);
          } catch (_) {}
        }
      }
      if (!mounted) return;
      if (w == null) {
        setState(() {
          _weatherErr = fetchErr != null ? '$fetchErr' : 'unavailable';
          _weatherLoading = false;
          _weather = null;
        });
        await _loadTip(null);
        return;
      }
      setState(() {
        _weather = w;
        _weatherLoading = false;
        _weatherErr = null;
      });
      await _loadTip(w);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _weatherErr = '$e';
        _weatherLoading = false;
      });
      await _loadTip(null);
    }
  }

  Future<void> _loadTip(WeatherSnapshot? w) async {
    final plants = ref.read(gardenListProvider);
    if (plants.isEmpty) {
      setState(() => _gardenTip = null);
      return;
    }
    setState(() => _tipLoading = true);
    final g = ref.read(geminiGenerativeServiceProvider);
    final names = plants.map((e) => e.plantName).join(', ');
    final wx = w == null
        ? 'unknown'
        : '${w.temperatureC.toStringAsFixed(0)}°C, ${WeatherSnapshot.labelForWmoCode(w.code)}, '
            'humidity ${w.humidityPct?.toStringAsFixed(0) ?? '?'}%, rain chance ${w.rainChancePct ?? '?'}%'
            '${w.source == WeatherDataSource.aiEstimate ? ' (AI estimate — verify when online)' : ''}';
    String tip;
    if (g == null) {
      tip = _fallbackTip(plants, w);
    } else {
      try {
        tip = await g.generateText(
          systemInstruction:
              'You are a concise gardening coach. Use ONLY the numbers and condition words in the user message for weather — '
              'do not invent temperature, rainfall, or humidity. If weather is unknown, give generic season-appropriate advice without fake numbers. '
              'At most 3 short sentences. Plain text only.',
          userText:
              'Plants in the user garden: $names. Weather today: $wx. Give one practical combined tip (watering / rain / humidity).',
        );
        if (tip.isEmpty) tip = _fallbackTip(plants, w);
      } catch (_) {
        tip = _fallbackTip(plants, w);
      }
    }
    if (!mounted) return;
    setState(() {
      _gardenTip = tip;
      _tipLoading = false;
    });
  }

  String _fallbackTip(List<GrowSession> plants, WeatherSnapshot? w) {
    final rain = w?.rainChancePct;
    if (rain != null && rain >= 50) {
      return 'Moderate rain chance. Water less today for ${plants.map((e) => e.plantName).join(', ')}.';
    }
    if (rain != null && rain < 20) {
      return 'Dry conditions likely — check soil for ${plants.first.plantName} and nearby pots.';
    }
    return 'Keep soil lightly moist; adjust if the weather shifts this week.';
  }

  String _locLabel(AppLocalizations l, GrowLocationType t) {
    return switch (t) {
      GrowLocationType.indoor => l.indoor,
      GrowLocationType.balcony => l.balcony,
      GrowLocationType.terrace => l.terrace,
    };
  }

  String _sunLabel(AppLocalizations l, SunlightLevel s) {
    return switch (s) {
      SunlightLevel.low => l.sunLow,
      SunlightLevel.medium => l.sunMedium,
      SunlightLevel.high => l.sunHigh,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final garden = ref.watch(gardenListProvider);
    ref.listen<List<GrowSession>>(gardenListProvider, (prev, next) {
      final a = prev?.map((e) => e.gardenInstanceId).join(',') ?? '';
      final b = next.map((e) => e.gardenInstanceId).join(',');
      if (a != b) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _loadTip(_weather);
        });
      }
    });
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final headerGreen = dark ? const Color(0xFF1B4D2E) : GrowColors.green600;
    final cardGreen = dark ? const Color(0xFF234D32) : GrowColors.green600.withValues(alpha: 0.92);

    return GrowLayout(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: cs.primary, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.myGardenTitle,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _weatherLoading
              ? DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardGreen,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    ),
                  ),
                )
              : _weatherErr != null
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardGreen,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          l.gardenWeatherLoadError,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    )
                  : _weather == null
                      ? DecoratedBox(
                          decoration: BoxDecoration(
                            color: cardGreen,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              l.gardenWeatherUnavailable,
                              style: GoogleFonts.inter(color: Colors.white),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GardenWeatherHeroBanner(
                              weather: _weather!,
                              placeLine: _placeLabel ?? l.myGardenLocationHint,
                              sourceLine: switch (_weather!.source) {
                                WeatherDataSource.openMeteo => 'Open-Meteo',
                                WeatherDataSource.openWeatherMap => 'OpenWeatherMap',
                                WeatherDataSource.aiEstimate => 'AI seasonal estimate',
                              },
                            ),
                            if (garden.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Card(
                                color: cs.surfaceContainerHighest,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(color: cs.outline.withValues(alpha: 0.25)),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.spa, color: cs.primary, size: 22),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l.plantTipHeader,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w800,
                                                color: cs.onSurface,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      if (_tipLoading)
                                        Text(
                                          l.gardenAiTipLoading,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            color: cs.onSurfaceVariant,
                                          ),
                                        )
                                      else if (_gardenTip != null)
                                        Text(
                                          _gardenTip!,
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            height: 1.45,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      const SizedBox(height: 14),
                                      Row(
                                        children: [
                                          Icon(Icons.opacity, color: cs.primary, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              l.wateringAdjustmentHeader,
                                              style: GoogleFonts.inter(
                                                fontWeight: FontWeight.w700,
                                                color: cs.onSurface,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        _aggregateWateringNote(garden),
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          height: 1.4,
                                          color: cs.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Text(
                  l.gardenYourPlants,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ),
              Text(
                l.gardenPlantsCount(garden.length),
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (garden.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                l.myGardenEmpty,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            )
          else
            ...garden.map(
              (s) {
                final locked = s.farmingLockedOn(DateTime.now());
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GardenPlantCard(
                    session: s,
                    scheduledLocked: locked,
                    headerGreen: headerGreen,
                    locLabel: _locLabel(l, s.location),
                    sunLabel: _sunLabel(l, s.sunlight),
                    onCalendar: () async {
                      await ref.read(sessionControllerProvider.notifier).setActiveGardenPlant(s.gardenInstanceId);
                      if (context.mounted) context.go('/home');
                    },
                    onWatered: () async {
                      await ref.read(sessionControllerProvider.notifier).setActiveGardenPlant(s.gardenInstanceId);
                      if (!context.mounted) return;
                      context.push(
                        '/sprinkler?instanceId=${Uri.encodeComponent(s.gardenInstanceId)}'
                        '&crop=${Uri.encodeComponent(s.plantName)}',
                      );
                    },
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  String _aggregateWateringNote(List<GrowSession> garden) {
    if (garden.length == 1) return garden.first.wateringRecommendationText;
    return 'Review each card below — mixed crops may need different rhythms.';
  }
}

class _GardenPlantCard extends ConsumerWidget {
  const _GardenPlantCard({
    required this.session,
    required this.scheduledLocked,
    required this.headerGreen,
    required this.locLabel,
    required this.sunLabel,
    required this.onCalendar,
    required this.onWatered,
  });

  final GrowSession session;
  final bool scheduledLocked;
  final Color headerGreen;
  final String locLabel;
  final String sunLabel;
  final VoidCallback onCalendar;
  final VoidCallback onWatered;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final asyncPlant = ref.watch(_gardenCardPlantProvider(session.plantId));

    return Card(
      elevation: 2,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: asyncPlant.when(
          data: (plant) => _cardBody(context, ref, l, cs, plant),
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => _cardBody(context, ref, l, cs, null),
        ),
      ),
    );
  }

  Widget _cardBody(BuildContext context, WidgetRef ref, AppLocalizations l, ColorScheme cs, Plant? plant) {
    ref.watch(localDataRevisionProvider);
    final valveOn = ref.read(growStorageProvider).sprinklerOnFor(session.gardenInstanceId);
    final loc = MaterialLocalizations.of(context);
    final startLabel = loc.formatFullDate(session.effectiveFarmingStart);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (scheduledLocked)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Icon(Icons.schedule, size: 18, color: cs.tertiary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Scheduled — unlocks $startLabel',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _plantThumb(plant, cs),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.plantName,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 17),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l.locationSunLine(locLabel, sunLabel),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange.shade700, size: 22),
                Text(
                  '${session.streak}',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                ),
                Text(
                  l.streak,
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(Icons.favorite_outline, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.plantHealth,
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            Text(
              '${session.plantHealth}%',
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (session.plantHealth / 100).clamp(0.0, 1.0),
            backgroundColor: cs.surfaceContainerHighest,
            color: cs.primary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.water_drop_outlined, size: 18, color: cs.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '${l.recoPrefix} ${session.wateringRecommendationText}',
                style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: cs.onSurface),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: headerGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: scheduledLocked ? null : onWatered,
                icon: Icon(valveOn ? Icons.hourglass_top : Icons.water_drop, size: 18),
                label: Text(valveOn ? '${l.watering}…' : l.iWatered),
              ),
            ),
            const SizedBox(width: 10),
            OutlinedButton(
              onPressed: onCalendar,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(12),
                side: BorderSide(color: cs.outline),
              ),
              child: Icon(Icons.calendar_today_outlined, color: cs.onSurface, size: 20),
            ),
          ],
        ),
      ],
    );
  }

  Widget _plantThumb(Plant? plant, ColorScheme cs) {
    final url = plant?.imageUrl;
    const size = 56.0;
    if (url == null || url.isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: cs.surfaceContainerHighest,
        child: const Icon(Icons.spa),
      );
    }
    return ClipOval(
      child: plantCatalogImage(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          color: cs.surfaceContainerHighest,
          child: const Icon(Icons.broken_image),
        ),
      ),
    );
  }
}
