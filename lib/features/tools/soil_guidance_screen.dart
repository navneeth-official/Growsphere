import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../shell/grow_tools_sheet.dart';

class SoilGuidanceScreen extends StatelessWidget {
  const SoilGuidanceScreen({super.key});

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
          Text(
            '🫘 Soil recovery challenge plants',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
          ),
          const SizedBox(height: 12),
          _PlantRow(
            cs: cs,
            emoji: '🫘',
            name: 'Cowpea',
            detail: '⏱️ 3 months • Best after: Tomato, Corn, Cabbage',
          ),
          const SizedBox(height: 10),
          _PlantRow(
            cs: cs,
            emoji: '🍀',
            name: 'Clover',
            detail: '⏱️ 2 months • Best after: Most vegetables',
          ),
          const SizedBox(height: 10),
          _PlantRow(
            cs: cs,
            emoji: '🫘',
            name: 'Soybeans',
            detail: '⏱️ 3 months • Best after: Corn, Wheat, Cabbage',
          ),
          const SizedBox(height: 10),
          _PlantRow(
            cs: cs,
            emoji: '🫛',
            name: 'Peas',
            detail: '⏱️ 2 months • Best after: Root vegetables, Brassicas',
          ),
          const SizedBox(height: 10),
          _PlantRow(
            cs: cs,
            emoji: '🌾',
            name: 'Alfalfa',
            detail: '⏱️ 4 months • Best after: Heavy nutrient crops',
          ),
        ],
      ),
    );
  }
}

class _PlantRow extends StatelessWidget {
  const _PlantRow({
    required this.cs,
    required this.emoji,
    required this.name,
    required this.detail,
  });

  final ColorScheme cs;
  final String emoji;
  final String name;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    detail,
                    style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: GrowColors.gray700),
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
