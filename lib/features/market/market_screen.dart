import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../core/theme/grow_colors.dart';
import '../../data/market_price_repository.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

const _kRegions = <String>[
  'Auto (device location)',
  'Mumbai, Maharashtra',
  'Pune, Maharashtra',
  'Delhi NCR',
  'Bengaluru, Karnataka',
  'Hyderabad, Telangana',
  'Chennai, Tamil Nadu',
  'Kolkata, West Bengal',
  'Ahmedabad, Gujarat',
  'Lucknow, Uttar Pradesh',
  'Kochi, Kerala',
  'Indore, Madhya Pradesh',
  'Nagpur, Maharashtra',
];

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  String _regionChoice = _kRegions.first;
  String _resolvedRegion = 'India';
  String? _geoHint;
  Future<MarketBoardResult>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  Future<void> _bootstrap() async {
    await _resolveDeviceRegion();
    _reload();
  }

  Future<void> _resolveDeviceRegion() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _resolvedRegion = 'India (enable location for local default)';
            _geoHint = null;
          });
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final lat = pos.latitude;
      final lon = pos.longitude;
      final label = await _reverseGeocodeLabel(lat, lon);
      if (!mounted) return;
      setState(() {
        _geoHint = '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
        _resolvedRegion = label ?? 'Near ${lat.toStringAsFixed(2)}, ${lon.toStringAsFixed(2)}';
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _resolvedRegion = 'India';
          _geoHint = null;
        });
      }
    }
  }

  Future<String?> _reverseGeocodeLabel(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json',
      );
      final res = await http.get(
        uri,
        headers: const {'User-Agent': 'GrowSphere/1.0 (educational demo app)'},
      ).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = j['address'] as Map<String, dynamic>?;
      if (addr == null) return null;
      final city = addr['city'] ?? addr['town'] ?? addr['village'] ?? addr['county'];
      final state = addr['state'];
      final country = addr['country'];
      final parts = <String>[];
      if (city != null) parts.add('$city');
      if (state != null) parts.add('$state');
      if (country != null) parts.add('$country');
      if (parts.isEmpty) return j['display_name']?.toString();
      return parts.join(', ');
    } catch (_) {
      return null;
    }
  }

  String get _effectiveRegion {
    if (_regionChoice == _kRegions.first) return _resolvedRegion;
    return _regionChoice;
  }

  void _reload() {
    setState(() {
      _future = ref.read(marketRepositoryProvider).fetchBoard(
            regionLabel: _effectiveRegion,
            geoHint: _geoHint,
          );
    });
  }

  Widget _buildBoard(ColorScheme cs) {
    final f = _future;
    if (f == null) {
      return const _MarketAiLoadingCard();
    }
    return FutureBuilder<MarketBoardResult>(
      future: f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const _MarketAiLoadingCard();
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}', textAlign: TextAlign.center));
        }
        final board = snap.data!;
        final rows = board.rows;
        final last = rows.isNotEmpty ? rows.first.updated : DateTime.now();
        final timeStr = '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}';
        return ListView(
          children: [
            Text(
              'Region: ${_effectiveRegion}',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: cs.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'AI-generated indicative wholesale-style prices (INR/kg) — not a live exchange feed.',
              style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, height: 1.35),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Updated (device clock): $timeStr',
                style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 12),
            if (board.series.isNotEmpty) ...[
              Text(
                'Price movement (model trend)',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: cs.onSurface),
              ),
              const SizedBox(height: 8),
              ...board.series.map((s) => _MiniTrendCard(series: s, cs: cs)),
              const SizedBox(height: 12),
            ],
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.attach_money, color: cs.primary, size: 22),
                        const SizedBox(width: 8),
                        Text(
                          'Spot prices',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    for (final r in rows) ...[
                      if (r != rows.first) Divider(height: 18, color: cs.outline.withValues(alpha: 0.25)),
                      _PriceRow(row: r, timeStr: timeStr),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GrowToolShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.pin_drop_outlined, color: cs.primary, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Market region',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _regionChoice == _kRegions.first
                          ? 'Default uses your device location when permission is granted.'
                          : 'Showing indicative prices for the selected market area.',
                      style: GoogleFonts.inter(fontSize: 12, height: 1.35, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _regionChoice,
                      decoration: InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: _kRegions
                          .map(
                            (r) => DropdownMenuItem(
                              value: r,
                              child: Text(r, overflow: TextOverflow.ellipsis),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => _regionChoice = v);
                        _reload();
                      },
                    ),
                    if (_geoHint != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'GPS: $_geoHint',
                        style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.tonalIcon(
                        onPressed: _reload,
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Refresh prices'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildBoard(cs)),
          ],
        ),
      ),
    );
  }
}

class _MiniTrendCard extends StatelessWidget {
  const _MiniTrendCard({required this.series, required this.cs});

  final MarketPriceSeries series;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final spots = series.spots;
    if (spots.isEmpty) return const SizedBox.shrink();
    final rawMin = spots.map((e) => e.pricePerKg).reduce((a, b) => a < b ? a : b);
    final rawMax = spots.map((e) => e.pricePerKg).reduce((a, b) => a > b ? a : b);
    var minY = rawMin * 0.96;
    var maxY = rawMax * 1.04;
    if (maxY - minY < 0.01) {
      minY = rawMin - 1;
      maxY = rawMax + 1;
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              series.crop,
              style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: cs.onSurface),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 120,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(show: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(show: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        show: true,
                        reservedSize: 36,
                        getTitlesWidget: (v, m) => Text(
                          v.round().toString(),
                          style: GoogleFonts.inter(fontSize: 9, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        show: true,
                        interval: 1,
                        getTitlesWidget: (v, m) {
                          final i = v.round();
                          if (i < 0 || i >= spots.length) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              spots[i].label,
                              style: GoogleFonts.inter(fontSize: 9, color: cs.onSurfaceVariant),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < spots.length; i++) FlSpot(i.toDouble(), spots[i].pricePerKg),
                      ],
                      isCurved: true,
                      color: cs.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketAiLoadingCard extends StatefulWidget {
  const _MarketAiLoadingCard();

  @override
  State<_MarketAiLoadingCard> createState() => _MarketAiLoadingCardState();
}

class _MarketAiLoadingCardState extends State<_MarketAiLoadingCard> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      color: cs.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fetching regional prices',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: cs.onSurface),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Gemini is estimating mandi-style rates and short trends for your selected region…',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.row, required this.timeStr});

  final MarketRow row;
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    final up = row.changePercent >= 0;
    final trendColor = up ? GrowColors.green600 : Colors.red.shade700;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(row.crop, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 4),
              Text(
                '₹${row.pricePerKg.toStringAsFixed(2)}/kg',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: GrowColors.green600,
                ),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(up ? Icons.trending_up : Icons.trending_down, color: trendColor, size: 22),
                const SizedBox(width: 4),
                Text(
                  '${row.changePercent.toStringAsFixed(2)}%',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: trendColor),
                ),
              ],
            ),
            Text(timeStr, style: GoogleFonts.inter(fontSize: 11, color: GrowColors.gray600)),
          ],
        ),
      ],
    );
  }
}
