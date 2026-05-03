import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../data/weather_repository.dart';

/// Dark, wide weather strip inspired by compact forecast UIs: animated pictogram + stats + header column.
class GardenWeatherHeroBanner extends StatefulWidget {
  const GardenWeatherHeroBanner({
    super.key,
    required this.weather,
    required this.placeLine,
    this.sourceLine,
  });

  final WeatherSnapshot weather;
  final String placeLine;
  final String? sourceLine;

  @override
  State<GardenWeatherHeroBanner> createState() => _GardenWeatherHeroBannerState();
}

class _GardenWeatherHeroBannerState extends State<GardenWeatherHeroBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  bool _celsius = true;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(seconds: 18))..repeat();
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  double get _tempDisplay => _celsius ? widget.weather.temperatureC : (widget.weather.temperatureC * 9 / 5 + 32);

  @override
  Widget build(BuildContext context) {
    final w = widget.weather;
    final timeStr = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(DateTime.now()),
      alwaysUse24HourFormat: MediaQuery.of(context).alwaysUse24HourFormat,
    );
    final dayStr = MaterialLocalizations.of(context).formatFullDate(DateTime.now());
    final condition = WeatherSnapshot.labelForWmoCode(w.code);

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 340;
        final artW = narrow ? 86.0 : 108.0;
        final artH = narrow ? 86.0 : 100.0;
        final hPad = narrow ? 10.0 : 14.0;

        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1F24),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: artW,
                height: artH,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  clipBehavior: Clip.antiAlias,
                  child: AnimatedBuilder(
                    animation: _anim,
                    builder: (_, __) {
                      return CustomPaint(
                        painter: _ClimateHeroPainter(
                          t: _anim.value,
                          code: w.code,
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(width: narrow ? 8 : 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Precipitation chance',
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, height: 1.2),
                    ),
                    Text(
                      '${w.rainChancePct ?? '—'}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Humidity',
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, height: 1.2),
                    ),
                    Text(
                      '${w.humidityPct?.round() ?? '—'}%',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wind',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.white54, height: 1.2),
                    ),
                    Text(
                      '${w.windKmh.round()} km/h',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.92)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Weather',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.inter(
                        fontSize: narrow ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.96),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$dayStr · $timeStr',
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: narrow ? 10 : 12, color: Colors.white60, height: 1.25),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.placeLine,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white38),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      condition,
                      textAlign: TextAlign.right,
                      maxLines: 2,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white60, height: 1.25),
                    ),
                    const SizedBox(height: 10),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _tempDisplay.round().toString(),
                            style: GoogleFonts.inter(
                              fontSize: narrow ? 28 : 34,
                              fontWeight: FontWeight.w800,
                              height: 1,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          GestureDetector(
                            onTap: () => setState(() => _celsius = !_celsius),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                                children: [
                                  TextSpan(
                                    text: '°C',
                                    style: TextStyle(
                                      color: _celsius ? Colors.white : Colors.white38,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' | ',
                                    style: TextStyle(color: Colors.white38),
                                  ),
                                  TextSpan(
                                    text: '°F',
                                    style: TextStyle(
                                      color: !_celsius ? Colors.white : Colors.white38,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.sourceLine != null && widget.sourceLine!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.sourceLine!,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: 9, color: Colors.white38, height: 1.2),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ClimateHeroPainter extends CustomPainter {
  _ClimateHeroPainter({required this.t, required this.code});

  final double t;
  final int code;

  _Mood get _mood {
    if (code == 0) return _Mood.clear;
    if (code <= 3) return _Mood.partlyCloudy;
    if (code <= 48) return _Mood.fog;
    if (code <= 67) return _Mood.rain;
    if (code <= 77) return _Mood.snow;
    if (code <= 86) return _Mood.rain;
    if (code <= 99) return _Mood.storm;
    return _Mood.partlyCloudy;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final mood = _mood;
    final cx = size.width * 0.52;
    final cy = size.height * 0.48;

    const panel = Color(0xFF1E1F24);
    canvas.drawRect(Offset.zero & size, Paint()..color = panel);

    final sunAngle = t * math.pi * 2 * 0.12;

    if (mood == _Mood.clear || mood == _Mood.partlyCloudy || mood == _Mood.fog) {
      canvas.save();
      canvas.translate(cx - 2, cy - 18);
      canvas.rotate(sunAngle);
      _drawSun(canvas, 22);
      canvas.restore();
    }

    if (mood == _Mood.partlyCloudy || mood == _Mood.rain || mood == _Mood.storm || mood == _Mood.snow || mood == _Mood.fog) {
      _drawSoftCloud(canvas, size, cx + 4, cy + 8, mood);
    }

    if (mood == _Mood.rain || mood == _Mood.storm) {
      _drawRain(canvas, size, t, mood == _Mood.storm);
    }
    if (mood == _Mood.storm && (t * 20).floor() % 11 == 0) {
      canvas.drawRect(Offset.zero & size, Paint()..color = Colors.white.withValues(alpha: 0.07));
    }
    if (mood == _Mood.snow) {
      _drawSnow(canvas, size, t);
    }
    if (mood == _Mood.fog) {
      final mist = Paint()..color = Colors.white.withValues(alpha: 0.08 + 0.06 * math.sin(t * math.pi * 2));
      canvas.drawRect(Rect.fromLTWH(0, size.height * 0.55, size.width, size.height * 0.45), mist);
    }
  }

  void _drawSun(Canvas canvas, double r) {
    final core = Paint()..color = const Color(0xFFFFA726);
    canvas.drawCircle(Offset.zero, r, core);
    canvas.drawCircle(Offset.zero, r * 1.28, Paint()..color = Colors.amber.shade100.withValues(alpha: 0.22)..style = PaintingStyle.stroke..strokeWidth = 2);
    for (var i = 0; i < 12; i++) {
      final a = (i / 12) * math.pi * 2;
      final len = r * 0.55 + 4 * math.sin(t * math.pi * 4 + i);
      canvas.drawLine(
        Offset(math.cos(a) * r * 1.05, math.sin(a) * r * 1.05),
        Offset(math.cos(a) * (r + len), math.sin(a) * (r + len)),
        Paint()
          ..color = Colors.orange.shade100.withValues(alpha: 0.45)
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawSoftCloud(Canvas canvas, Size size, double cx, double cy, _Mood mood) {
    final base = mood == _Mood.fog ? 0.75 : 0.92;
    final wobble = 2 * math.sin(t * math.pi * 2);
    void puff(double ox, double oy, double rad, double a) {
      canvas.drawCircle(
        Offset(cx + ox + wobble, cy + oy),
        rad,
        Paint()..color = Colors.white.withValues(alpha: a * base),
      );
    }

    puff(-18, 4, 16, 0.95);
    puff(4, 0, 22, 1.0);
    puff(28, 6, 15, 0.88);
    puff(14, -10, 14, 0.85);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 6, cy + 10), width: 62, height: 18),
      Paint()..color = const Color(0xFFB0BEC5).withValues(alpha: 0.35),
    );
  }

  void _drawRain(Canvas canvas, Size size, double t, bool heavy) {
    final n = heavy ? 22 : 14;
    final paint = Paint()
      ..color = Colors.lightBlueAccent.withValues(alpha: 0.5)
      ..strokeWidth = heavy ? 2.0 : 1.3
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var i = 0; i < n; i++) {
      final x = (i * 17.0 + t * 90 + rnd.nextDouble() * 8) % (size.width + 6);
      final y = (i * 23.0 + t * 140) % (size.height + 10);
      canvas.drawLine(Offset(x, y), Offset(x - 3, y + 9), paint);
    }
  }

  void _drawSnow(Canvas canvas, Size size, double t) {
    final p = Paint()..color = Colors.white.withValues(alpha: 0.85);
    for (var i = 0; i < 18; i++) {
      final x = (i * 19.0 + t * 26) % size.width;
      final y = (i * 31.0 + t * 44) % size.height;
      canvas.drawCircle(Offset(x, y), 1.4, p);
    }
  }

  @override
  bool shouldRepaint(covariant _ClimateHeroPainter oldDelegate) =>
      oldDelegate.t != t || oldDelegate.code != code;
}

enum _Mood { clear, partlyCloudy, rain, storm, snow, fog }
