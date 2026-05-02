import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/weather_repository.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

class WeatherScreen extends ConsumerStatefulWidget {
  const WeatherScreen({super.key});

  @override
  ConsumerState<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends ConsumerState<WeatherScreen> {
  Future<WeatherSnapshot>? _future;
  String? _err;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _err = null;
      _future = null;
    });
    try {
      final perm = await Geolocator.checkPermission();
      LocationPermission p = perm;
      if (perm == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
      }
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever) {
        setState(() => _err = 'Location permission denied');
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final w = ref.read(weatherRepositoryProvider);
      setState(() {
        _future = w.fetch(pos.latitude, pos.longitude);
      });
    } catch (e) {
      setState(() => _err = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowSubpageScaffold(
      title: l.weather,
      appBarActions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _err != null
            ? Text(_err!)
            : _future == null
                ? const Center(child: CircularProgressIndicator())
                : FutureBuilder<WeatherSnapshot>(
                    future: _future,
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final w = snap.data!;
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Now: ${w.temperatureC.toStringAsFixed(1)}°C',
                                  style: Theme.of(context).textTheme.headlineSmall),
                              Text('Wind: ${w.windKmh.toStringAsFixed(1)} km/h'),
                              Text('Code: ${w.code} (WMO)'),
                              const Divider(),
                              Text('Today high: ${w.dailyMax.toStringAsFixed(1)}°C'),
                              Text('Today low: ${w.dailyMin.toStringAsFixed(1)}°C'),
                              if (w.timeLabel.isNotEmpty) Text('Observation: ${w.timeLabel}'),
                              const SizedBox(height: 12),
                              const Text('Powered by Open-Meteo (no API key).'),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}
