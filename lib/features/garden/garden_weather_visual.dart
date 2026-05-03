import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/weather_repository.dart';

enum _WeatherMood {
  sunny,
  cloudy,
  rainy,
  stormy,
  foggy,
  snowy,
  neutral,
}

_WeatherMood _moodFromWmo(int code) {
  if (code == 0) return _WeatherMood.sunny;
  if (code <= 3) return _WeatherMood.cloudy;
  if (code <= 48) return _WeatherMood.foggy;
  if (code <= 67) return _WeatherMood.rainy;
  if (code <= 77) return _WeatherMood.snowy;
  if (code <= 86) return _WeatherMood.rainy;
  if (code <= 99) return _WeatherMood.stormy;
  return _WeatherMood.cloudy;
}

/// Live-style illustration behind garden weather stats (pure Flutter, no assets).
class GardenWeatherVisual extends StatefulWidget {
  const GardenWeatherVisual({
    super.key,
    required this.weather,
    required this.foreground,
  });

  final WeatherSnapshot weather;
  final Widget foreground;

  @override
  State<GardenWeatherVisual> createState() => _GardenWeatherVisualState();
}

class _GardenWeatherVisualState extends State<GardenWeatherVisual> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mood = _moodFromWmo(widget.weather.code);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _ctrl,
              builder: (_, __) {
                return CustomPaint(
                  painter: _WeatherSkyPainter(
                    t: _ctrl.value,
                    mood: mood,
                  ),
                );
              },
            ),
          ),
          widget.foreground,
        ],
      ),
    );
  }
}

class _WeatherSkyPainter extends CustomPainter {
  _WeatherSkyPainter({required this.t, required this.mood});

  final double t;
  final _WeatherMood mood;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = switch (mood) {
      _WeatherMood.sunny => const [Color(0xFF38BDF8), Color(0xFF0EA5E9)],
      _WeatherMood.cloudy => const [Color(0xFF64748B), Color(0xFF475569)],
      _WeatherMood.rainy => const [Color(0xFF334155), Color(0xFF1E293B)],
      _WeatherMood.stormy => const [Color(0xFF1E1B4B), Color(0xFF312E81)],
      _WeatherMood.foggy => const [Color(0xFF94A3B8), Color(0xFF64748B)],
      _WeatherMood.snowy => const [Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      _WeatherMood.neutral => const [Color(0xFF475569), Color(0xFF334155)],
    };
    canvas.drawRect(rect, Paint()..shader = LinearGradient(colors: base, begin: Alignment.topLeft, end: Alignment.bottomRight).createShader(rect)));

    if (mood == _WeatherMood.sunny) {
      final cx = size.width * 0.78;
      final cy = size.height * 0.22;
      final pulse = 0.92 + 0.08 * math.sin(t * math.pi * 2);
      final sunR = size.width * 0.11 * pulse;
      canvas.drawCircle(
        Offset(cx, cy),
        sunR,
        Paint()..color = const Color(0xFFFDE047).withValues(alpha: 0.95),
      );
      canvas.drawCircle(
        Offset(cx, cy),
        sunR * 1.35,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      for (var i = 0; i < 10; i++) {
        final a = (i / 10) * math.pi * 2 + t * math.pi * 2 * 0.15;
        final len = sunR * 1.5;
        final x1 = cx + math.cos(a) * sunR * 1.05;
        final y1 = cy + math.sin(a) * sunR * 1.05;
        final x2 = cx + math.cos(a) * (sunR + len);
        final y2 = cy + math.sin(a) * (sunR + len);
        canvas.drawLine(
          Offset(x1, y1),
          Offset(x2, y2),
          Paint()
            ..color = Colors.amber.shade100.withValues(alpha: 0.35)
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }

    if (mood == _WeatherMood.cloudy || mood == _WeatherMood.rainy || mood == _WeatherMood.stormy || mood == _WeatherMood.foggy || mood == _WeatherMood.snowy) {
      _drawClouds(canvas, size, t, mood);
    }

    if (mood == _WeatherMood.rainy || mood == _WeatherMood.stormy) {
      _drawRain(canvas, size, t, mood == _WeatherMood.stormy);
    }

    if (mood == _WeatherMood.stormy && (t * 10).floor() % 7 == 0) {
      final flash = Paint()..color = Colors.white.withValues(alpha: 0.08);
      canvas.drawRect(rect, flash);
    }

    if (mood == _WeatherMood.snowy) {
      _drawSnow(canvas, size, t);
    }

    if (mood == _WeatherMood.foggy) {
      final fog = Paint()..color = Colors.white.withValues(alpha: 0.12 + 0.06 * math.sin(t * math.pi * 2));
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), fog);
    }
  }

  void _drawClouds(Canvas canvas, Size size, double t, _WeatherMood mood) {
    final drift = t * 36;
    for (var c = 0; c < 3; c++) {
      final baseX = -40 + c * (size.width * 0.42) + drift % (size.width * 0.5);
      final y = size.height * (0.12 + c * 0.08);
      final alpha = switch (mood) {
        _WeatherMood.foggy => 0.55,
        _WeatherMood.snowy => 0.65,
        _ => 0.75,
      };
      _puff(canvas, Offset(baseX, y), size.width * 0.14, Colors.white.withValues(alpha: alpha * 0.9));
      _puff(canvas, Offset(baseX + size.width * 0.1, y + 4), size.width * 0.11, Colors.white.withValues(alpha: alpha * 0.75));
      _puff(canvas, Offset(baseX + size.width * 0.2, y), size.width * 0.12, Colors.white.withValues(alpha: alpha * 0.8));
    }
  }

  void _puff(Canvas canvas, Offset c, double r, Color color) {
    canvas.drawCircle(c, r, Paint()..color = color);
  }

  void _drawRain(Canvas canvas, Size size, double t, bool heavy) {
    final rnd = math.Random(4);
    final n = heavy ? 48 : 28;
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.45)
      ..strokeWidth = heavy ? 2.2 : 1.4
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < n; i++) {
      final x = (i * 37.0 + t * 120 + rnd.nextDouble() * 20) % (size.width + 20) - 10;
      final yBase = (i * 53.0 + t * 260) % (size.height + 40);
      final y = yBase - 20;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 14), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size, double t) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 36; i++) {
      final x = (i * 41.0 + t * 40) % (size.width + 8) - 4;
      final y = (i * 59.0 + t * 80) % (size.height + 8) - 4;
      canvas.drawCircle(Offset(x, y), 1.6, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WeatherSkyPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.mood != mood;
}
