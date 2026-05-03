import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/synthetic_tool_plants.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

class _Variety {
  const _Variety({
    required this.emoji,
    required this.name,
    required this.duration,
    required this.price,
    required this.nutrients,
    required this.tips,
    required this.basicSetupInr,
    required this.totalInvestmentInr,
  });

  final String emoji;
  final String name;
  final String duration;
  final String price;
  final String nutrients;
  final List<String> tips;
  final int basicSetupInr;
  final int totalInvestmentInr;
}

class MicrogreensGuideScreen extends ConsumerStatefulWidget {
  const MicrogreensGuideScreen({super.key});

  @override
  ConsumerState<MicrogreensGuideScreen> createState() => _MicrogreensGuideScreenState();
}

class _MicrogreensGuideScreenState extends ConsumerState<MicrogreensGuideScreen> {
  static const _varieties = <_Variety>[
    _Variety(
      emoji: '🥦',
      name: 'Broccoli microgreens',
      duration: '8–12 days',
      price: '₹150/100g',
      nutrients: 'Sulforaphane, vitamins A, C, K, folate',
      basicSetupInr: 1850,
      totalInvestmentInr: 2480,
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
      basicSetupInr: 1850,
      totalInvestmentInr: 2320,
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
      basicSetupInr: 1850,
      totalInvestmentInr: 2280,
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
      basicSetupInr: 1750,
      totalInvestmentInr: 2180,
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
      basicSetupInr: 1950,
      totalInvestmentInr: 2680,
      tips: [
        'Black oil sunflower seed works best',
        'Press seeds lightly into medium',
        'Crunchy stems — popular microgreen',
      ],
    ),
  ];

  int? _expandedIndex;
  int? _selectedIndex;

  void _toggleExpand(int i) {
    setState(() {
      _expandedIndex = _expandedIndex == i ? null : i;
    });
  }

  void _goGardenAfterFrame(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      GoRouter.of(context).go('/garden');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
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
                  _bullet(context, '⚡', 'Ready in 7–14 days (fastest harvest)'),
                  _bullet(context, '🏠', 'Grows on a windowsill or shelf'),
                  _bullet(context, '💰', '₹100–150 per 100g typical retail band'),
                  _bullet(context, '🥗', 'Very nutrient-dense vs mature greens'),
                  _bullet(context, '♻️', 'Reusable trays and grow mats'),
                  _bullet(context, '🚫', 'Short cycle — minimal pesticide need'),
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
          Text(
            'Tap a variety to expand key nutrients and growing tips, then use Select to choose your crop.',
            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant, height: 1.35),
          ),
          const SizedBox(height: 10),
          ...List.generate(_varieties.length, (i) {
            final v = _varieties[i];
            final open = _expandedIndex == i;
            final selected = _selectedIndex == i;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: selected ? cs.primary : (open ? cs.primary.withValues(alpha: 0.5) : cs.outline.withValues(alpha: 0.45)),
                    width: selected ? 2 : 1,
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    InkWell(
                      onTap: () => _toggleExpand(i),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.emoji, style: const TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    v.name,
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: cs.onSurface),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '⏱️ ${v.duration} • ${v.price}',
                                    style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
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
                            Row(
                              children: [
                                Icon(Icons.restaurant_outlined, size: 18, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Key nutrients',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: cs.onSurface),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              v.nutrients,
                              style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: cs.onSurface),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.checklist_outlined, size: 18, color: cs.primary),
                                const SizedBox(width: 6),
                                Text(
                                  'Growing tips',
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14, color: cs.onSurface),
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
                                    Expanded(
                                      child: Text(
                                        t,
                                        style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: cs.onSurface),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            FilledButton.tonalIcon(
                              onPressed: () {
                                setState(() => _selectedIndex = i);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Selected: ${v.name}')),
                                );
                              },
                              icon: const Icon(Icons.check_circle_outline, size: 20),
                              label: Text(selected ? 'Selected' : 'Select this microgreen'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          Text(
            'Costs & setup',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Card(
            color: dark ? const Color(0xFF2A2318) : const Color(0xFFFFF9E6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: dark ? Colors.amber.shade700.withValues(alpha: 0.4) : Colors.amber.shade200,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('🛠️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedIndex == null
                              ? 'Basic setup cost'
                              : 'Basic setup cost — ${_varieties[_selectedIndex!].name}',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: cs.onSurface),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _costRow(context, 'Growing tray (5 pcs)', '₹200–300'),
                  const SizedBox(height: 6),
                  _costRow(context, 'Coconut coir or jute mat', '₹100–150'),
                  const SizedBox(height: 6),
                  if (_selectedIndex != null)
                    _costRow(context, 'Seeds (${_varieties[_selectedIndex!].name})', _varieties[_selectedIndex!].price)
                  else
                    _costRow(context, 'Seeds (per variety)', '₹50–100'),
                  const SizedBox(height: 6),
                  _costRow(context, 'Spray bottle', '₹50–100'),
                  const SizedBox(height: 6),
                  _costRow(context, 'Grow light (optional)', '₹500–1500'),
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('💰', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedIndex == null
                              ? 'Total investment: ₹900–2250 (one-time, generic kit)'
                              : 'Total investment (typical for ${_varieties[_selectedIndex!].name}): '
                                  'about ₹${_varieties[_selectedIndex!].basicSetupInr} setup + '
                                  '≈ ₹${_varieties[_selectedIndex!].totalInvestmentInr} with starter seed runs.',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            height: 1.35,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_selectedIndex != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Figures are indicative — compare with your local shop before you add this crop to My Garden.',
                      style: GoogleFonts.inter(fontSize: 12, height: 1.4, color: cs.onSurfaceVariant),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              if (_selectedIndex == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Expand a variety and tap Select this microgreen first.')),
                );
                return;
              }
              final v = _varieties[_selectedIndex!];
              final plant = syntheticMicrogreenPlant(
                name: v.name,
                retailLabel: v.price,
                harvestDurationDays: parseMicrogreenHarvestDays(v.duration),
              );
              try {
                await ref.read(sessionControllerProvider.notifier).addToolPlantToGarden(plant);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${v.name} to My Garden.')),
                );
                _goGardenAfterFrame(context);
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Could not add to garden: $e')),
                );
              }
            },
            icon: const Icon(Icons.spa_outlined),
            label: const Text('Add Microgreens to My Garden'),
          ),
        ],
      ),
    );
  }

  Widget _costRow(BuildContext context, String label, String value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(fontSize: 13, height: 1.35, color: cs.onSurfaceVariant),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 13, color: cs.onSurface),
        ),
      ],
    );
  }

  Widget _bullet(BuildContext context, String icon, String text) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 14, height: 1.35, color: cs.onSurface),
            ),
          ),
        ],
      ),
    );
  }
}
