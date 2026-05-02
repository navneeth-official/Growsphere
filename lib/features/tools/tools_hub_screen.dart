import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../shell/grow_layout.dart';

/// V1 Tools hub — four cards with colored circles and black "Open Tool" buttons.
class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return GrowLayout(
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        children: [
          Text(
            l.toolsScreenTitle,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 20),
          _ToolCard(
            circleColor: const Color(0xFF2563EB),
            icon: Icons.chat_bubble_outline,
            title: l.aiChatAssistantTitle,
            subtitle: l.aiChatAssistantDesc,
            onOpen: () => context.push('/chat'),
            subtitleColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          _ToolCard(
            circleColor: GrowColors.green600,
            icon: Icons.photo_camera_outlined,
            title: l.plantPhotoDetectionTitle,
            subtitle: l.plantPhotoDetectionDesc,
            onOpen: () => context.push('/disease'),
            subtitleColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          _ToolCard(
            circleColor: const Color(0xFF9333EA),
            icon: Icons.science_outlined,
            title: l.soilAnalysisTitle,
            subtitle: l.soilAnalysisDesc,
            onOpen: () => context.push('/soil'),
            subtitleColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          _ToolCard(
            circleColor: const Color(0xFFDC2626),
            icon: Icons.bug_report_outlined,
            title: l.pestControlGuideTitle,
            subtitle: l.pestControlGuideDesc,
            onOpen: () => context.push('/pest'),
            subtitleColor: cs.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          _ToolCard(
            circleColor: const Color(0xFFCA8A04),
            icon: Icons.trending_up,
            title: l.marketPrices,
            subtitle: 'Regional INR/kg estimates, short price trends, and manual region override.',
            onOpen: () => context.push('/market'),
            subtitleColor: cs.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({
    required this.circleColor,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onOpen,
    required this.subtitleColor,
  });

  final Color circleColor;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onOpen;
  final Color subtitleColor;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: circleColor,
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(fontSize: 14, color: subtitleColor, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: onOpen,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(120, 40),
                    ),
                    child: Text(l.openTool),
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
