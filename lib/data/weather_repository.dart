import 'dart:convert';

import 'package:http/http.dart' as http;

class WeatherSnapshot {
  WeatherSnapshot({
    required this.temperatureC,
    required this.windKmh,
    required this.code,
    required this.dailyMax,
    required this.dailyMin,
    required this.timeLabel,
  });

  final double temperatureC;
  final double windKmh;
  final int code;
  final double dailyMax;
  final double dailyMin;
  final String timeLabel;
}

/// Open-Meteo (no API key). **Firebase:** optional cache in Firestore.
class WeatherRepository {
  Future<WeatherSnapshot> fetch(double lat, double lon) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weather_code,wind_speed_10m'
      '&daily=temperature_2m_max,temperature_2m_min&forecast_days=1&timezone=auto',
    );
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Weather HTTP ${res.statusCode}');
    }
    final j = jsonDecode(res.body) as Map<String, dynamic>;
    final cur = j['current'] as Map<String, dynamic>;
    final daily = (j['daily'] as Map<String, dynamic>);
    final maxList = (daily['temperature_2m_max'] as List<dynamic>).cast<num>();
    final minList = (daily['temperature_2m_min'] as List<dynamic>).cast<num>();
    return WeatherSnapshot(
      temperatureC: (cur['temperature_2m'] as num).toDouble(),
      windKmh: (cur['wind_speed_10m'] as num).toDouble(),
      code: (cur['weather_code'] as num).toInt(),
      dailyMax: maxList.first.toDouble(),
      dailyMin: minList.first.toDouble(),
      timeLabel: cur['time'] as String? ?? '',
    );
  }
}
