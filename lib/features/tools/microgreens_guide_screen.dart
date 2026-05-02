import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../shell/grow_tools_sheet.dart';

class _Variety {
  const _Variety({
    required this.emoji,
    required this.name,
    required this.duration,
    required this.price,
    required this.nutrients,
    required this.tips,
  });

  final String emoji;
  final String name;
  final String duration;
  final String price;
  final String nutrients;
  final List<String> tips;
}

class MicrogreensGuideScreen extends StatefulWidget {
  const MicrogreensGuideScreen({super.key});

  @override
  State<MicrogreensGuideScreen> createState() => _MicrogreensGuideScreenState();
}

class _MicrogreensGuideScreenState extends State<MicrogreensGuideScreen> {
  static const _varieties = <_Variety>[
    _Variety(
      emoji: '🥦',
      name: 'Broccoli microgreens',
      duration: '8–12 days',
      price: '₹150/100g',
      nutrients: 'Sulforaphane, vitamins A, C, K, folate',
      tips: [
        'Keep medium moist but not soggy',
        'Good light improves leaf color',
        'Harvest when first true leaves appear',
        'Mild broccoli flavor — salads & wraps',
      ],
    ),
    _Variety(
      emoji: '🌶️',
      name: 'Radish microgreens',
      duration: '7–10 days',
      price: '₹120/100g',
      nutrients: 'Vitamin C, potassium, antioxidants',
      tips: [
        'Soak seeds about 4 hours only',
        'Dense growth is normal',
        'Peppery taste intensifies slightly over time',
        'Great for salads and garnish',
        'Germination rate is usually very high',
      ],
    ),
    _Variety(
      emoji: '🌿',
      name: 'Mustard microgreens',
      duration: '10–14 days',
      price: '₹100/100g',
      nutrients: 'Vitamins A, C, E, calcium, iron',
      tips: [
        'Spicy bite — use sparingly at first',
        'Prefer bright indirect light',
        'Cut above the medium when harvesting',
      ],
    ),
    _Variety(
      emoji: '🌱',
      name: 'Alfalfa microgreens',
      duration: '8–14 days',
      price: '₹80/100g',
      nutrients: 'Protein, vitamin K, trace minerals',
      tips: [
        'Rinse gently to reduce hulls',
        'Mild flavor — bulk for sandwiches',
        'Rotate trays for even growth',
      ],
    ),
    _Variety(
      emoji: '🌻',
      name: 'Sunflower microgreens',
      duration: '10–14 days',
      price: '₹140/100g',
      nutrients: 'Protein, zinc, magnesium, vitamin E',
      tips: [
        'Black oil sunflower seed works best',
        'Press seeds lightly into medium',
        'Crunchy stems — popular microgreen',
      ],
    ),
  ];

  final Set<int> _open = {1};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return GrowSubpageScaffold(
      title: l.microgreensGuideTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          Card(
            color: cs.primaryContainer.withValues(alpha: 0.3),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '✨ What are microgreens?',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Microgreens are young vegetable plants harvested 7–14 days after germination. '
                    "They're nutrient-dense, grow in minimal space, and suit urban gardening. "
                    'They can pack up to 40× more nutrients than mature leaves by weight.',
                    style: GoogleFonts.inter(fontSize: 14, height: 1.45, color: cs.onSurface),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Benefits',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
                  ),
                  const SizedBox(height: 12),
                  _bullet('⚡', 'Ready in 7–14 days (fastest harvest)'),
                  _bullet('🏠', 'Grows on a windowsill or shelf'),
                  _bullet('💰', '₹100–150 per 100g typical retail band'),
                  _bullet('🥗', 'Very nutrient-dense vs mature greens'),
                  _bullet('♻️', 'Reusable trays and grow mats'),
                  _bullet('🚫', 'Short cycle — minimal pesticide need'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '🌿 Popular varieties',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
          ),
          const SizedBox(height: 10),
          ...List.generate(_varieties.length, (i) {
            final v = _varieties[i];
            final open = _open.contains(i);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: open ? BorderSide(color: cs.primary, width: 1.5) : BorderSide.none,
                ),
                child: ExpansionTile(
                  initiallyExpanded: open,
                  onExpansionChanged: (x) => setState(() {
                    if (x) {
                      _open.add(i);
                    } else {
                      _open.remove(i);
                    }
                  }),
                  leading: Text(v.emoji, style: const TextStyle(fontSize: 28)),
                  title: Text(
                    v.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  subtitle: Text(
                    '⏱️ ${v.duration} • ${v.price}',
                    style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray700),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.restaurant_outlined, size: 18, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Key nutrients',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            v.nutrients,
                            style: GoogleFonts.inter(fontSize: 13, height: 1.4),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(Icons.checklist_outlined, size: 18, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(
                                'Growing tips',
                                style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...v.tips.map(
                            (t) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_outline, size: 18, color: cs.primary),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(t, style: GoogleFonts.inter(fontSize: 13, height: 1.35))),
                                ],
                              ),
                            ),
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
      ),
    );
  }

  Widget _bullet(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 14, height: 1.35))),
        ],
      ),
    );
  }
}
