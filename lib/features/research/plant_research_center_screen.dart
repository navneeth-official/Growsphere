import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/launch_google_search.dart';
import '../../core/theme/grow_colors.dart';
import '../shell/grow_layout.dart';

/// V1 Plant Research Center — Google search card + quick topics.
class PlantResearchCenterScreen extends StatefulWidget {
  const PlantResearchCenterScreen({super.key});

  @override
  State<PlantResearchCenterScreen> createState() => _PlantResearchCenterScreenState();
}

class _PlantResearchCenterScreenState extends State<PlantResearchCenterScreen> {
  final _q = TextEditingController();

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowLayout(
      innerTitle: l.plantResearchCenter,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.search, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        l.googlePlantResearch,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _q,
                          decoration: InputDecoration(
                            hintText: l.searchPlantInfoHint,
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(14),
                        ),
                        onPressed: () async {
                          final q = _q.text.trim();
                          if (q.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Type what you want to search, then tap search.')),
                            );
                            return;
                          }
                          final ok = await launchGoogleSearch(q);
                          if (!mounted) return;
                          if (!ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open Google search.')),
                            );
                          }
                        },
                        child: const Icon(Icons.search),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.searchPlantInfoFooter,
                    style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l.quickResearchTopics, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          _TopicTile(
            icon: Icons.thermostat,
            query: 'plant climate requirements',
            subtitle: 'Temperature & weather needs',
          ),
          _TopicTile(
            icon: Icons.spa,
            query: 'soil pH for vegetables',
            subtitle: 'Soil conditions & pH levels',
          ),
          _TopicTile(
            icon: Icons.science,
            query: 'NPK fertilizer guide',
            subtitle: 'Fertilizer types & ratios',
          ),
          _TopicTile(
            icon: Icons.show_chart,
            query: 'plant growth stages',
            subtitle: 'Growth timeline & stages',
          ),
          _TopicTile(
            icon: Icons.eco,
            query: 'organic farming methods',
            subtitle: 'Natural growing techniques',
          ),
        ],
      ),
    );
  }
}

class _TopicTile extends StatelessWidget {
  const _TopicTile({
    required this.icon,
    required this.query,
    required this.subtitle,
  });

  final IconData icon;
  final String query;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: GrowColors.green600),
        title: Text(query),
        subtitle: Text(subtitle, style: const TextStyle(color: GrowColors.gray600, fontSize: 13)),
        trailing: const Icon(Icons.open_in_new, size: 20),
        onTap: () async {
          final ok = await launchGoogleSearch(query);
          if (!context.mounted) return;
          if (!ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not open Google search.')),
            );
          }
        },
      ),
    );
  }
}
