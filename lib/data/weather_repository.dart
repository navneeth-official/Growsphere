import 'dart:convert';

import 'package:http/http.dart' as http;

enum WeatherDataSource { openMeteo, openWeatherMap, aiEstimate }

class WeatherSnapshot {
  WeatherSnapshot({
    required this.temperatureC,
    required this.windKmh,
    required this.code,
    required this.dailyMax,
    required this.dailyMin,
    required this.timeLabel,
    this.humidityPct,
    this.rainChancePct,
    this.source = WeatherDataSource.openMeteo,
    this.sourceNote,
  });

  final double temperatureC;
  final double windKmh;
  final int code;
  final double dailyMax;
  final double dailyMin;
  final String timeLabel;
  final double? humidityPct;
  final int? rainChancePct;
  final WeatherDataSource source;
  /// Shown under stats when [source] is AI (e.g. disclaimer).
  final String? sourceNote;

  static String labelForWmoCode(int code) {
    if (code == 0) return 'Clear';
    if (code <= 3) return 'Partly cloudy';
    if (code <= 48) return 'Foggy';
    if (code <= 57) return 'Drizzle';
    if (code <= 67) return 'Rain';
    if (code <= 77) return 'Snow';
    if (code <= 82) return 'Rain showers';
    if (code <= 86) return 'Snow showers';
    if (code <= 99) return 'Storm';
    return 'Cloudy';
  }
}

/// Primary: [Open-Meteo](https://open-meteo.com/) (no key). Optional: OpenWeatherMap current
/// if `OPENWEATHER_API_KEY` is set via `--dart-define=OPENWEATHER_API_KEY=...`.
class WeatherRepository {
  static const _owmKey = String.fromEnvironment('OPENWEATHER_API_KEY', defaultValue: '');

  /// Tries Open-Meteo, then OpenWeatherMap (when key present). Throws if both fail.
  Future<WeatherSnapshot> fetch(double lat, double lon) async {
    try {
      return await _fetchOpenMeteo(lat, lon);
    } catch (_) {
      if (_owmKey.isNotEmpty) {
        return await _fetchOpenWeatherMap(lat, lon);
      }
      rethrow;
    }
  }

  /// When [fetch] fails (e.g. offline), caller may use [tryParseAiEstimateJson] after Gemini returns JSON.
  static WeatherSnapshot? tryParseAiEstimateJson(String raw, double lat, double lon) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) return null;
      final j = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      if (j['error'] != null) return null;
      final t = j['temperatureC'];
      if (t is! num) return null;
      final code = (j['wmoWeatherCode'] is num) ? (j['wmoWeatherCode'] as num).toInt().clamp(0, 99) : 1;
      final hum = j['humidityPct'];
      final wind = j['windKmh'];
      return WeatherSnapshot(
        temperatureC: t.toDouble(),
        windKmh: wind is num ? wind.toDouble() : 8,
        code: code,
        dailyMax: t.toDouble() + 4,
        dailyMin: t.toDouble() - 4,
        timeLabel: 'AI estimate @ $lat,$lon',
        humidityPct: hum is num ? hum.toDouble() : null,
        rainChancePct: j['rainChancePct'] is num ? (j['rainChancePct'] as num).toInt().clamp(0, 100) : null,
        source: WeatherDataSource.aiEstimate,
        sourceNote: 'Estimated from coordinates and season only — verify with a live forecast when online.',
      );
    } catch (_) {
      return null;
    }
  }

  Future<WeatherSnapshot> _fetchOpenMeteo(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,relative_humidity_2m,weather_code,wind_speed_10m,precipitation'
      '&daily=temperature_2m_max,temperature_2m_min,precipitation_probability_max'
      '&forecast_days=1&timezone=auto&windspeed_unit=kmh',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('Open-Meteo HTTP ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final cur = j['current'] as Map<String, dynamic>;
    final daily = (j['daily'] as Map<String, dynamic>);
    final maxList = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
    final minList = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
    final probList = daily['precipitation_probability_max'] as List<dynamic>?;
    int? rainChance;
    if (probList != null && probList.isNotEmpty && probList.first is num) {
      rainChance = (probList.first as num).toInt().clamp(0, 100);
    }
    final hum = cur['relative_humidity_2m'];
    return WeatherSnapshot(
      temperatureC: (cur['temperature_2m'] as num).toDouble(),
      windKmh: (cur['wind_speed_10m'] as num).toDouble(),
      code: (cur['weather_code'] as num).toInt(),
      dailyMax: maxList.first.toDouble(),
      dailyMin: minList.first.toDouble(),
      timeLabel: cur['time'] as String? ?? '',
      humidityPct: hum is num ? hum.toDouble() : null,
      rainChancePct: rainChance,
      source: WeatherDataSource.openMeteo,
    );
  }

  /// OpenWeatherMap [Current weather](https://openweathermap.org/current) — free tier with API key.
  Future<WeatherSnapshot> _fetchOpenWeatherMap(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&units=metric&appid=$_owmKey',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    if (res.statusCode != 200) {
      throw Exception('OpenWeatherMap HTTP ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final main = j['main'] as Map<String, dynamic>;
    final wind = j['wind'] as Map<String, dynamic>?;
    final weather = (j['weather'] as List<dynamic>).cast<Map<String, dynamic>>();
    final owmId = weather.isNotEmpty ? (weather.first['id'] as num?)?.toInt() ?? 800 : 800;
    final code = _owmConditionIdToWmo(owmId);
    final t = (main['temp'] as num).toDouble();
    final hum = main['humidity'];
    final w = wind != null && wind['speed'] is num ? (wind['speed'] as num).toDouble() * 3.6 : 0.0;
    return WeatherSnapshot(
      temperatureC: t,
      windKmh: w,
      code: code,
      dailyMax: t + 3,
      dailyMin: t - 3,
      timeLabel: 'OpenWeatherMap',
      humidityPct: hum is num ? hum.toDouble() : null,
      rainChancePct: null,
      source: WeatherDataSource.openWeatherMap,
    );
  }

  /// Rough mapping from OpenWeather condition `id` to WMO-like code for visuals.
  static int _owmConditionIdToWmo(int id) {
    if (id >= 200 && id < 300) return 95;
    if (id >= 300 && id < 400) return 51;
    if (id >= 500 && id < 600) return id >= 502 ? 65 : 61;
    if (id >= 600 && id < 700) return 71;
    if (id >= 700 && id < 800) return 45;
    if (id == 800) return 0;
    if (id > 800) return 2;
    return 1;
  }
}
