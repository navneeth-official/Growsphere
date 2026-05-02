import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../shell/grow_tools_sheet.dart';
import '../soil/soil_recovery_challenge_section.dart';

class SoilGuidanceScreen extends ConsumerStatefulWidget {
  const SoilGuidanceScreen({super.key});

  @override
  ConsumerState<SoilGuidanceScreen> createState() => _SoilGuidanceScreenState();
}

class _SoilGuidanceScreenState extends ConsumerState<SoilGuidanceScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return GrowSubpageScaffold(
      title: l.soilGuidanceTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Card(
            color: cs.primaryContainer.withValues(alpha: 0.35),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🌱 What is Soil Recovery?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'After growing nutrient-demanding crops, planting leguminous plants restores nitrogen '
                    'and improves soil structure. These “green manures” fix atmospheric nitrogen and break pest cycles.',
                    style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const SoilRecoveryChallengeSection(),
        ],
      ),
    );
  }
}
