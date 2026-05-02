import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../shell/grow_layout.dart';

/// V1 Research tab — quick topic rows + green tips card.
class ResearchScreen extends StatelessWidget {
  const ResearchScreen({super.key});

  static const _queries = <String>[
    'tomato growing guide',
    'rice cultivation methods',
    'wheat farming techniques',
    'corn planting season',
    'potato growing conditions',
    'carrot soil requirements',
    'lettuce growing tips',
    'onion farming guide',
    'spinach growing season',
    'broccoli cultivation',
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowLayout(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Card(
            child: Column(
              children: [
                for (final q in _queries)
                  ListTile(
                    title: Text(q, style: GoogleFonts.inter(fontSize: 15)),
                    trailing: const Icon(Icons.open_in_new, size: 20, color: GrowColors.gray600),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open: $q (demo)')),
                      );
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: GrowColors.green100.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GrowColors.green600.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.menu_book_outlined, color: GrowColors.green700, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      l.researchTipsTitle,
                      style: GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: GrowColors.green700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l.researchTipsBody,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    height: 1.45,
                    color: GrowColors.green700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/research/center'),
            icon: const Icon(Icons.travel_explore),
            label: Text(l.plantResearchCenter),
          ),
        ],
      ),
    );
  }
}
