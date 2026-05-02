import 'dart:io';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/network/image_request_headers.dart';
import '../../core/theme/grow_colors.dart';
import '../../data/weather_repository.dart';
import '../../domain/grow_enums.dart';
import '../../domain/grow_session.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

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
  String? _gardenTip;
  bool _tipLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadWeatherAndTip());
  }

  Future<void> _loadWeatherAndTip() async {
    setState(() {
      _weatherLoading = true;
      _weatherErr = null;
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
      final pos = await Geolocator.getCurrentPosition();
      final w = await ref.read(weatherRepositoryProvider).fetch(pos.latitude, pos.longitude);
      if (!mounted) return;
      setState(() {
        _weather = w;
        _weatherLoading = false;
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
            'humidity ${w.humidityPct?.toStringAsFixed(0) ?? '?'}%, rain chance ${w.rainChancePct ?? '?'}%';
    String tip;
    if (g == null) {
      tip = _fallbackTip(plants, w);
    } else {
      try {
        tip = await g.generateText(
          systemInstruction:
              'You are a concise gardening coach. Reply with at most 3 short sentences. Plain text only.',
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
              Material(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => context.go('/plants'),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(Icons.add, color: cs.onPrimaryContainer, size: 22),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: cardGreen,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _weatherLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                    )
                  : _weatherErr != null
                      ? Text(
                          l.gardenWeatherLoadError,
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
                        )
                      : _weather == null
                          ? Text(
                              l.gardenWeatherUnavailable,
                              style: GoogleFonts.inter(color: Colors.white),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_weather!.temperatureC.round()}°C',
                                            style: GoogleFonts.inter(
                                              fontSize: 32,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            WeatherSnapshot.labelForWmoCode(_weather!.code),
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white.withValues(alpha: 0.95),
                                            ),
                                          ),
                                          Text(
                                            l.myGardenLocationHint,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: Colors.white.withValues(alpha: 0.88),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        _miniStat(
                                          Icons.water_drop_outlined,
                                          '${_weather!.humidityPct?.round() ?? '—'}%',
                                          l.gardenHumidityShort,
                                        ),
                                        const SizedBox(height: 6),
                                        _miniStat(
                                          Icons.air,
                                          '${_weather!.windKmh.round()} km/h',
                                          'Wind',
                                        ),
                                        const SizedBox(height: 6),
                                        _miniStat(
                                          Icons.grain,
                                          _weather!.rainChancePct != null
                                              ? '${_weather!.rainChancePct}%'
                                              : '—',
                                          l.gardenRainChanceShort,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                if (garden.isNotEmpty) ...[
                                  const SizedBox(height: 14),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.spa, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l.plantTipHeader,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (_tipLoading)
                                    Text(
                                      l.gardenAiTipLoading,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        color: Colors.white.withValues(alpha: 0.9),
                                      ),
                                    )
                                  else if (_gardenTip != null)
                                    Text(
                                      _gardenTip!,
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        height: 1.4,
                                        color: Colors.white.withValues(alpha: 0.95),
                                      ),
                                    ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.opacity, color: Colors.white, size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            l.wateringAdjustmentHeader,
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _aggregateWateringNote(garden),
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      color: Colors.white.withValues(alpha: 0.92),
                                    ),
                                  ),
                                ],
                              ],
                            ),
            ),
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
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GardenPlantCard(
                  session: s,
                  headerGreen: headerGreen,
                  locLabel: _locLabel(l, s.location),
                  sunLabel: _sunLabel(l, s.sunlight),
                  onCalendar: () async {
                    await ref.read(sessionControllerProvider.notifier).setActiveGardenPlant(s.gardenInstanceId);
                    if (context.mounted) context.go('/home');
                  },
                  onWatered: () async {
                    await ref.read(sessionControllerProvider.notifier).setActiveGardenPlant(s.gardenInstanceId);
                    if (context.mounted) {
                      context.push(
                        '/sprinkler?instanceId=${Uri.encodeComponent(s.gardenInstanceId)}'
                        '&crop=${Uri.encodeComponent(s.plantName)}',
                      );
                    }
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _aggregateWateringNote(List<GrowSession> garden) {
    if (garden.length == 1) return garden.first.wateringRecommendationText;
    return 'Review each card below — mixed crops may need different rhythms.';
  }

  Widget _miniStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GardenPlantCard extends ConsumerWidget {
  const _GardenPlantCard({
    required this.session,
    required this.headerGreen,
    required this.locLabel,
    required this.sunLabel,
    required this.onCalendar,
    required this.onWatered,
  });

  final GrowSession session;
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
          data: (plant) => _cardBody(context, l, cs, plant),
          loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => _cardBody(context, l, cs, null),
        ),
      ),
    );
  }

  Widget _cardBody(BuildContext context, AppLocalizations l, ColorScheme cs, Plant? plant) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                onPressed: onWatered,
                icon: const Icon(Icons.water_drop, size: 18),
                label: Text(l.iWatered),
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
    if (url.startsWith('http')) {
      return ClipOval(
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          headers: ImageRequestHeaders.standard,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: cs.surfaceContainerHighest,
            child: const Icon(Icons.broken_image),
          ),
        ),
      );
    }
    return ClipOval(
      child: Image.file(
        File(url),
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
