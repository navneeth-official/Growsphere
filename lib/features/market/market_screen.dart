import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../core/widgets/ai_progress_dialog.dart';
import '../../data/market_price_repository.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

class MarketScreen extends ConsumerStatefulWidget {
  const MarketScreen({super.key});

  @override
  ConsumerState<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends ConsumerState<MarketScreen> {
  Future<List<MarketRow>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= ref.read(marketRepositoryProvider).latestRows();
  }

  void _reload() {
    setState(() {
      _future = ref.read(marketRepositoryProvider).latestRows();
    });
  }

  @override
  Widget build(BuildContext context) {
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
                side: const BorderSide(color: GrowColors.gray200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text('🇮🇳', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('India', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                          Text('Currency: INR', style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Change Country'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: FutureBuilder<List<MarketRow>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const _MarketAiLoadingCard();
                  }
                  if (snap.hasError) {
                    return Center(child: Text('${snap.error}'));
                  }
                  final rows = snap.data ?? [];
                  final last = rows.isNotEmpty ? rows.first.updated : DateTime.now();
                  final timeStr =
                      '${last.hour.toString().padLeft(2, '0')}:${last.minute.toString().padLeft(2, '0')}:${last.second.toString().padLeft(2, '0')}';
                  return ListView(
                    children: [
                      Center(
                        child: Text(
                          'Last updated: $timeStr',
                          style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: GrowColors.gray200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.attach_money, size: 22),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Market Prices (INR)',
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              for (final r in rows) ...[
                                if (r != rows.first) const Divider(height: 20),
                                _PriceRow(row: r, timeStr: timeStr),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
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
  Timer? _timer;
  int _i = 0;

  @override
  void initState() {
    super.initState();
    if (kAiStatusMarketPrices.length > 1) {
      _timer = Timer.periodic(const Duration(milliseconds: 2000), (_) {
        if (!mounted) return;
        setState(() => _i = (_i + 1) % kAiStatusMarketPrices.length);
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msg = kAiStatusMarketPrices[_i % kAiStatusMarketPrices.length];
    return Card(
      color: const Color(0xFFEFF6FF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFBFDBFE)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF2563EB)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Checking market prices',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    child: Text(
                      msg,
                      key: ValueKey<String>(msg),
                      style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: const Color(0xFF1E40AF)),
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
