import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/providers.dart';
import '../calendar/farm_plan_month_cards.dart';
import '../shell/grow_layout.dart';

/// Full-width monthly farm plan template — opened from the home “plan” shortcut.
class FarmPlanChartScreen extends ConsumerWidget {
  const FarmPlanChartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final session = ref.watch(sessionControllerProvider);
    final storage = ref.watch(growStorageProvider);
    final cs = Theme.of(context).colorScheme;

    if (session == null) {
      return GrowLayout(
        innerTitle: l.farmPlanningSectionTitle,
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month_outlined, size: 56, color: cs.outline),
              const SizedBox(height: 16),
              Text(
                'Choose an active grow from My Garden to see its full seasonal plan chart.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 15, height: 1.45, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/garden'),
                child: Text(l.tabMyGarden),
              ),
            ],
          ),
        ),
      );
    }

    final startM = storage.farmPlanStartMonthForPlant(session.plantId) ?? session.farmPlanStartMonth;

    return GrowLayout(
      innerTitle: l.farmPlanningSectionTitle,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Text(
            session.plantName,
            style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Template months and tasks for this grow — scroll the full overview.',
            style: GoogleFonts.inter(fontSize: 13, height: 1.4, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FarmPlanMonthCards(
            startMonth1To12: startM,
            sectionTitle: l.farmPlanningSectionTitle,
          ),
        ],
      ),
    );
  }
}
