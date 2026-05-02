import 'dart:math';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../core/widgets/ai_progress_dialog.dart';
import '../../providers/providers.dart';
import '../shell/grow_tool_shell.dart';

class SoilRecoveryScreen extends ConsumerStatefulWidget {
  const SoilRecoveryScreen({super.key});

  @override
  ConsumerState<SoilRecoveryScreen> createState() => _SoilRecoveryScreenState();
}

class _SoilRecoveryScreenState extends ConsumerState<SoilRecoveryScreen> {
  double _ph = 6.8;
  String _n = 'High';
  String _p = 'Medium';
  String _k = 'Low';

  void _randomize() {
    final r = Random();
    setState(() {
      _ph = 5.5 + r.nextDouble() * 2;
      _n = ['Low', 'Medium', 'High'][r.nextInt(3)];
      _p = ['Low', 'Medium', 'High'][r.nextInt(3)];
      _k = ['Low', 'Medium', 'High'][r.nextInt(3)];
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    return GrowToolShell(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.science_outlined, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        l.soilAnalysisTitle,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 17),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.05,
                    children: [
                      _MetricTile(
                        bg: const Color(0xFFE0F2FE),
                        label: 'pH Level',
                        value: _ph.toStringAsFixed(1),
                        valueColor: const Color(0xFF2563EB),
                        status: 'Optimal',
                      ),
                      _MetricTile(
                        bg: const Color(0xFFDCFCE7),
                        label: 'Nitrogen',
                        value: _n,
                        valueColor: const Color(0xFF15803D),
                        status: 'Good',
                      ),
                      _MetricTile(
                        bg: const Color(0xFFFFF8E7),
                        label: 'Phosphorus',
                        value: _p,
                        valueColor: const Color(0xFFB45309),
                        status: 'Fair',
                      ),
                      _MetricTile(
                        bg: const Color(0xFFF3E8FF),
                        label: 'Potassium',
                        value: _k,
                        valueColor: const Color(0xFF7C3AED),
                        status: 'Needs Attention',
                        statusUrgent: _k == 'Low',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () async {
                        await runWithAiProgress(
                          context,
                          title: 'Soil lab simulation',
                          messages: kAiStatusSoilLab,
                          task: () async {
                            await Future<void>.delayed(const Duration(milliseconds: 1100));
                            _randomize();
                          }(),
                        );
                      },
                      icon: const Icon(Icons.science_outlined),
                      label: const Text('Run New Soil Test'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Soil recovery', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          session == null
              ? Text(
                  'Start a grow session to see soil recovery suggestions.',
                  style: GoogleFonts.inter(color: GrowColors.gray600),
                )
              : session.nutrientHeavy
                  ? Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Soil Recovery Challenge',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${session.plantName} is a heavier feeder. After harvest, '
                              'try a legume cover crop or grow beans, peas, or cluster beans next cycle '
                              'to replenish nitrogen naturally.',
                            ),
                          ],
                        ),
                      ),
                    )
                  : const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Your current crop is lighter on soil nutrients. Still rotate families yearly '
                          'and add compost between cycles.',
                        ),
                      ),
                    ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.bg,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.status,
    this.statusUrgent = false,
  });

  final Color bg;
  final String label;
  final String value;
  final Color valueColor;
  final String status;
  final bool statusUrgent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600)),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w700, color: valueColor),
          ),
          const SizedBox(height: 4),
          if (statusUrgent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(status, style: GoogleFonts.inter(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
            )
          else
            Text(status, style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray700)),
        ],
      ),
    );
  }
}
