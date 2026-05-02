import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/care_timing_service.dart';
import '../../core/services/sprinkler_ai_advice_service.dart';
import '../../core/theme/grow_colors.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

/// Sprinkler dashboard with simulated live sensors, AI-guided timing, and calendar handoff.
class SprinklerScreen extends ConsumerStatefulWidget {
  const SprinklerScreen({super.key, this.autoWater = false});

  /// When true (e.g. from calendar), valve opens on entry for the "watering lab" flow.
  final bool autoWater;

  @override
  ConsumerState<SprinklerScreen> createState() => _SprinklerScreenState();
}

class _SprinklerScreenState extends ConsumerState<SprinklerScreen> {
  bool _autoMode = true;
  late double _durationMinutes;

  String _formatWaterMinutes(double m) {
    final x = (m * 2).round() / 2;
    if ((x - x.round()).abs() < 0.001) return '${x.round()} min';
    return '${x.toStringAsFixed(1)} min';
  }

  @override
  void initState() {
    super.initState();
    _durationMinutes = ref.read(growStorageProvider).wateringDurationMinutes;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (widget.autoWater) {
        await ref.read(sprinklerRepositoryProvider).setOn(
              true,
              targetWateringSeconds: (_durationMinutes * 60).round(),
            );
      }
    });
  }

  Color _qualityColor(SprinklerTimingQuality q) {
    return switch (q) {
      SprinklerTimingQuality.idle => GrowColors.gray600,
      SprinklerTimingQuality.watering => const Color(0xFF2563EB),
      SprinklerTimingQuality.idealWindow => GrowColors.green600,
      SprinklerTimingQuality.warnStop => const Color(0xFFD97706),
      SprinklerTimingQuality.over => Colors.red.shade700,
    };
  }

  String _qualityLabel(SprinklerTimingQuality q) {
    return switch (q) {
      SprinklerTimingQuality.idle => 'Idle',
      SprinklerTimingQuality.watering => 'Watering…',
      SprinklerTimingQuality.idealWindow => 'Perfect window',
      SprinklerTimingQuality.warnStop => 'Check timing',
      SprinklerTimingQuality.over => 'Overwatering',
    };
  }

  Future<void> _stopWatering(SprinklerLiveState live, SprinklerAiPlan plan) async {
    final over = live.quality == SprinklerTimingQuality.over;
    final sec = live.secondsWatering;
    final fromCal = ref.read(growStorageProvider).pendingSprinklerFromCalendar;
    await ref.read(sprinklerRepositoryProvider).setOn(false);
    final fb = await ref.read(sessionControllerProvider.notifier).finishSprinklerSession(
          overwatered: over,
          secondsWatered: sec,
          idealSecondsMid: plan.idealSecondsMid,
          logCareFromCalendar: fromCal,
        );
    await ref.read(growStorageProvider).setPendingSprinklerFromCalendar(false);
    if (!mounted) return;
    if (fromCal && fb != null) {
      final l = AppLocalizations.of(context)!;
      final msg = switch (fb!) {
        WaterFeedback.perfect => l.perfectTiming,
        WaterFeedback.overwatering => l.overwateringRisk,
        WaterFeedback.missed => l.missedCare,
        WaterFeedback.suboptimal => l.suboptimalTiming,
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else if (!fromCal) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            over
                ? 'Stopped. Soil was very wet — plant health may dip slightly.'
                : 'Watering stopped. Moisture-related tasks for today were updated when enough time elapsed.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final live = ref.watch(sprinklerLiveProvider);
    final planAsync = ref.watch(sprinklerAiPlanProvider);

    ref.listen(sprinklerAiPlanProvider, (_, next) {
      next.whenData((plan) => ref.read(sprinklerLiveProvider.notifier).setAiPlan(plan));
    });

    final plan = planAsync.valueOrNull ?? SprinklerAiPlan.fallback;
    final qc = _qualityColor(live.quality);

    return GrowLayout(
      innerTitle: l.sprinklerControlTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.wifi, color: GrowColors.green600, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.connectedSprinkler,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GrowColors.green100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      l.online,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: GrowColors.green700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          planAsync.when(
            loading: () => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Fetching AI watering window for your crop…',
                        style: GoogleFonts.inter(fontSize: 14, color: GrowColors.gray700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (p) => Card(
              color: const Color(0xFFEFF6FF),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: const Color(0xFF1D4ED8), size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI watering window',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${p.idealSecondsMin}–${p.idealSecondsMax}s typical valve time · aim ~${p.targetMoisturePct}% moisture',
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF1E40AF)),
                    ),
                    const SizedBox(height: 6),
                    Text(p.rationale, style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: const Color(0xFF1E3A8A))),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: qc.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: qc.withValues(alpha: 0.35)),
            ),
            child: Row(
              children: [
                Icon(
                  live.valveOpen ? Icons.water_drop : Icons.opacity_outlined,
                  color: qc,
                  size: 26,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _qualityLabel(live.quality),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: qc),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        live.hintLine,
                        style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: GrowColors.gray700),
                      ),
                      if (live.valveOpen)
                        Text(
                          '${live.secondsWatering}s on valve · target moisture ${plan.targetMoisturePct}%',
                          style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.05,
            children: [
              _SensorTile(
                background: const Color(0xFFFFF8E7),
                icon: Icons.water_drop,
                iconColor: const Color(0xFFE6A000),
                label: l.soilMoisture,
                valueText: live.moisture.toStringAsFixed(2),
                valueColor: const Color(0xFFE6A000),
                chip: live.moisture < 35 ? 'Low' : live.moisture > 85 ? 'High' : l.statusMedium,
              ),
              _SensorTile(
                icon: Icons.thermostat,
                iconColor: const Color(0xFF2563EB),
                label: l.temperature,
                valueText: live.temperature.toStringAsFixed(2),
                valueColor: const Color(0xFF2563EB),
                chip: l.normal,
              ),
              _SensorTile(
                icon: Icons.speed,
                iconColor: const Color(0xFF7C3AED),
                label: l.humidity,
                valueText: live.humidity.toStringAsFixed(2),
                valueColor: const Color(0xFF7C3AED),
                chip: l.good,
              ),
              _SensorTile(
                icon: Icons.battery_charging_full,
                iconColor: const Color(0xFFEA580C),
                label: l.battery,
                valueText: '${live.batteryPct}%',
                valueColor: const Color(0xFFEA580C),
                chip: l.good,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.power_settings_new, size: 22),
                      const SizedBox(width: 8),
                      Text(l.manualControl, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l.sprinklerStatus, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                            Text(
                              live.valveOpen ? 'Watering in progress…' : l.readyToWater,
                              style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        onPressed: live.valveOpen
                            ? () => _stopWatering(live, plan)
                            : () async {
                                await ref.read(sprinklerRepositoryProvider).setOn(
                                      true,
                                      targetWateringSeconds: (_durationMinutes * 60).round(),
                                    );
                              },
                        icon: Icon(live.valveOpen ? Icons.stop_circle_outlined : Icons.water_drop, size: 18),
                        label: Text(live.valveOpen ? 'Stop watering' : l.startWatering),
                      ),
                    ],
                  ),
                    if (live.valveOpen) ...[
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(99),
                      backgroundColor: GrowColors.gray200,
                      color: qc,
                      value: () {
                        final cap = (_durationMinutes * 60).round().clamp(1, 3600);
                        return (live.secondsWatering / cap).clamp(0.0, 1.0);
                      }(),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(l.duration, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      Text(
                        _formatWaterMinutes(_durationMinutes),
                        style: GoogleFonts.inter(color: GrowColors.gray600),
                      ),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.black,
                      inactiveTrackColor: GrowColors.gray200,
                      thumbColor: Colors.white,
                      overlayColor: Colors.black26,
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10, elevation: 0),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                    ),
                    child: Slider(
                      value: _durationMinutes.clamp(0.5, 30.0),
                      min: 0.5,
                      max: 30,
                      divisions: 59,
                      onChanged: live.valveOpen
                          ? null
                          : (v) async {
                              final snapped = ((v * 2).round() / 2).clamp(0.5, 30.0);
                              setState(() => _durationMinutes = snapped);
                              await ref.read(growStorageProvider).setWateringDurationMinutes(snapped);
                            },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, size: 22),
                      const SizedBox(width: 8),
                      Text(l.smartWatering, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.autoMode, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      l.autoModeSubtitle,
                      style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600),
                    ),
                    value: _autoMode,
                    onChanged: (v) => setState(() => _autoMode = v),
                  ),
                  if (_autoMode) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '• Water when soil moisture drops below 30%\n'
                        '• Daily watering at 7:00 AM and 5:00 PM\n'
                        '• Skip watering if rain is detected\n'
                        '• Adjust duration based on weather conditions',
                        style: GoogleFonts.inter(fontSize: 13, height: 1.45, color: const Color(0xFF1D4ED8)),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: Material(
                      color: const Color(0xFFE8F4FC),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${l.autoSettings} (demo)')),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Center(
                            child: Text(
                              l.autoSettings,
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1D4ED8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Schedule",
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  _ScheduleTile(
                    title: 'Morning Watering',
                    subtitle: '7:00 AM - Completed',
                    done: true,
                    bg: const Color(0xFFF0FDF4),
                  ),
                  const SizedBox(height: 10),
                  _ScheduleTile(
                    title: 'Evening Watering',
                    subtitle: '5:00 PM - Scheduled',
                    done: false,
                    bg: const Color(0xFFEFF6FF),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  const _ScheduleTile({
    required this.title,
    required this.subtitle,
    required this.done,
    required this.bg,
  });

  final String title;
  final String subtitle;
  final bool done;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
              ],
            ),
          ),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GrowColors.green600,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Done',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

class _SensorTile extends StatelessWidget {
  const _SensorTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.valueText,
    required this.valueColor,
    required this.chip,
    this.background,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String valueText;
  final Color valueColor;
  final String chip;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: background ?? Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600)),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                valueText,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: valueColor,
                ),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: GrowColors.gray100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                chip,
                style: GoogleFonts.inter(fontSize: 11, color: GrowColors.gray700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
