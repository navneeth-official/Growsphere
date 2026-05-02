import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../providers/providers.dart';

class _RecoveryPlant {
  const _RecoveryPlant({
    required this.emoji,
    required this.name,
    required this.durationLine,
    required this.soilEnrichment,
    required this.rotationGuidance,
    required this.moreInfo,
  });

  final String emoji;
  final String name;
  final String durationLine;
  final String soilEnrichment;
  final String rotationGuidance;
  final String moreInfo;
}

/// Expandable soil-recovery crops + “Add challenge to calendar” (shared by soil lab + soil guidance).
class SoilRecoveryChallengeSection extends ConsumerStatefulWidget {
  const SoilRecoveryChallengeSection({super.key});

  @override
  ConsumerState<SoilRecoveryChallengeSection> createState() => _SoilRecoveryChallengeSectionState();
}

class _SoilRecoveryChallengeSectionState extends ConsumerState<SoilRecoveryChallengeSection> {
  static const _plants = <_RecoveryPlant>[
    _RecoveryPlant(
      emoji: '🫘',
      name: 'Cowpea',
      durationLine: '⏱️ About 3 months as a cover / green manure',
      soilEnrichment:
          'Fixes atmospheric nitrogen via root nodules, adds organic biomass when incorporated, '
          'improves soil aggregation and water infiltration.',
      rotationGuidance: 'Especially helpful after heavy feeders like tomato, corn, or cabbage that draw lots of N and K.',
      moreInfo:
          'Till or mow before full pod set if you mainly want soil benefit rather than a bean harvest. '
          'Allow about 2–3 weeks decomposition before planting the next cash crop.',
    ),
    _RecoveryPlant(
      emoji: '🍀',
      name: 'Clover',
      durationLine: '⏱️ Often 6–10 weeks for a quick cover; up to ~2 months for thicker stands',
      soilEnrichment:
          'Strong N-fixer (rhizobia), dense ground cover suppresses weeds, roots loosen topsoil and feed soil life.',
      rotationGuidance: 'Works after most vegetables; ideal after mixed beds or where you want low-input recovery.',
      moreInfo:
          'White and crimson clovers are common for undersowing or fall covers. Mow before seeds drop if you want to avoid volunteers.',
    ),
    _RecoveryPlant(
      emoji: '🫘',
      name: 'Soybeans',
      durationLine: '⏱️ Roughly 3 months for a full cover cycle',
      soilEnrichment:
          'Substantial N contribution through fixation, deep taproots bring up minerals, residue breaks down into stable organic matter.',
      rotationGuidance: 'Best after cereals (corn, wheat) or brassicas that have mined the soil hard.',
      moreInfo:
          'In home or market gardens, treat as green manure unless you need the harvest; inoculate seed if nodulation is weak on your site.',
    ),
    _RecoveryPlant(
      emoji: '🫛',
      name: 'Peas',
      durationLine: '⏱️ About 6–10 weeks for snap / snow types as cover',
      soilEnrichment:
          'Legume N fixation, softer stems decompose quickly, good for building tilth in upper soil layers.',
      rotationGuidance:
          'Great after root vegetables or brassicas; avoids repeating legume back-to-back on tiny plots if disease-prone.',
      moreInfo:
          'Field peas or Austrian winter pea are classic “soil recovery” choices; incorporate at flowering for maximum N retention in soil.',
    ),
    _RecoveryPlant(
      emoji: '🌾',
      name: 'Alfalfa',
      durationLine: '⏱️ Deep recovery: often 3–4+ months for meaningful taproot growth',
      soilEnrichment:
          'Very deep roots break compaction layers, mines subsoil nutrients to topsoil when cut, excellent long-term organic matter.',
      rotationGuidance: 'Best after the heaviest nutrient exporters (e.g. brassicas, solanums) when you can leave a bed fallow longer.',
      moreInfo:
          'Harder in small raised beds due to depth needs; consider shorter alfalfa cycles or lucerne substitutes like clover on shallow soils.',
    ),
  ];

  int? _expandedIndex;

  Future<void> _addChallenge(BuildContext context, String plantName) async {
    final ok = await ref.read(sessionControllerProvider.notifier).appendCustomCalendarTask(
          title: 'Soil recovery: $plantName green manure',
          daysFromToday: 3,
        );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Start a grow from My Garden first so tasks can be added to your calendar.'),
        ),
      );
      context.go('/garden');
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added soil recovery challenge for $plantName.')),
    );
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '🫘 Soil recovery challenge plants',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a plant to expand soil benefits, rotation tips, and add a reminder to your grow calendar.',
          style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600, height: 1.35),
        ),
        const SizedBox(height: 12),
        ...List.generate(_plants.length, (i) {
          final p = _plants[i];
          final open = _expandedIndex == i;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: open ? cs.primary : GrowColors.gray200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InkWell(
                    onTap: () => setState(() => _expandedIndex = open ? null : i),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.emoji, style: const TextStyle(fontSize: 28)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  p.durationLine,
                                  style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: GrowColors.gray700),
                                ),
                              ],
                            ),
                          ),
                          Icon(open ? Icons.expand_less : Icons.expand_more, color: cs.primary),
                        ],
                      ),
                    ),
                  ),
                  if (open)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _sectionTitle(cs, Icons.eco_outlined, 'Soil enrichment'),
                          const SizedBox(height: 6),
                          Text(p.soilEnrichment, style: GoogleFonts.inter(fontSize: 13, height: 1.45)),
                          const SizedBox(height: 12),
                          _sectionTitle(cs, Icons.shuffle_outlined, 'What to grow after / before'),
                          const SizedBox(height: 6),
                          Text(p.rotationGuidance, style: GoogleFonts.inter(fontSize: 13, height: 1.45)),
                          const SizedBox(height: 12),
                          _sectionTitle(cs, Icons.menu_book_outlined, 'More guidance'),
                          const SizedBox(height: 6),
                          Text(p.moreInfo, style: GoogleFonts.inter(fontSize: 13, height: 1.45)),
                          const SizedBox(height: 14),
                          FilledButton.icon(
                            onPressed: () => _addChallenge(context, p.name),
                            icon: const Icon(Icons.event_available_outlined),
                            label: const Text('Add challenge to calendar'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _sectionTitle(ColorScheme cs, IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: cs.primary),
        const SizedBox(width: 6),
        Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
      ],
    );
  }
}
