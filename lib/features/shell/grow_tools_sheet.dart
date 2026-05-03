import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/grow_colors.dart';
import '../../providers/providers.dart';

/// Grid of feature shortcuts (replaces drawer); matches reference header grid action.
void showGrowToolsSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      final l = AppLocalizations.of(ctx)!;
      return Consumer(
        builder: (ctx, ref, _) {
          final session = ref.watch(sessionControllerProvider);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: [
                _tile(ctx, Icons.eco, l.tabMyGarden, () => ctx.go('/garden')),
                _tile(ctx, Icons.local_fire_department, l.streaksBadges, () => ctx.go('/streaks')),
                _tile(ctx, Icons.bug_report, l.pestControl, () => ctx.go('/pest')),
                _tile(ctx, Icons.payments, l.marketPrices, () => ctx.go('/market')),
                _tile(ctx, Icons.chat, l.aiChat, () => ctx.go('/chat')),
                _tile(ctx, Icons.photo_camera, l.diseasePhoto, () => ctx.go('/disease')),
                _tile(ctx, Icons.grass, l.soilRecovery, () => ctx.go('/soil')),
                _tile(ctx, Icons.water_drop, l.sprinkler, () {
                  final s = session;
                  if (s != null) {
                    ctx.go(
                      '/sprinkler?instanceId=${Uri.encodeComponent(s.gardenInstanceId)}'
                      '&crop=${Uri.encodeComponent(s.plantName)}',
                    );
                  } else {
                    ctx.go('/sprinkler');
                  }
                }),
                _tile(ctx, Icons.wb_sunny, l.weather, () => ctx.go('/weather')),
                _tile(ctx, Icons.settings, l.settings, () => ctx.go('/settings')),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
  return OutlinedButton.icon(
    onPressed: () {
      Navigator.pop(context);
      onTap();
    },
    icon: Icon(icon, size: 20),
    label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
  );
}

PreferredSizeWidget growToolsAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: GrowColors.green600,
    foregroundColor: Colors.white,
    elevation: 2,
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
    leading: context.canPop()
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          )
        : null,
    actions: [
      IconButton(
        icon: const Icon(Icons.grid_3x3),
        tooltip: 'More',
        onPressed: () => showGrowToolsSheet(context),
      ),
    ],
  );
}

/// Sub-pages: green app bar + tools grid + centered white column (reference max-w-md).
class GrowSubpageScaffold extends StatelessWidget {
  const GrowSubpageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.appBarActions,
  });

  final String title;
  final Widget body;
  final List<Widget>? appBarActions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: GrowColors.green600,
        foregroundColor: Colors.white,
        elevation: 2,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
        actions: [
          ...?appBarActions,
          IconButton(
            icon: const Icon(Icons.grid_3x3),
            tooltip: 'More',
            onPressed: () => showGrowToolsSheet(context),
          ),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 448),
          color: cs.surface,
          child: body,
        ),
      ),
    );
  }
}
