import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../providers/providers.dart';
import 'grow_tools_sheet.dart';

const _kTabRoots = {'/plants', '/home', '/tools', '/add-crop', '/research'};

/// V1 shell: green GROWSPHERE bar, optional white inner title row, max-width body, black-pill bottom nav.
class GrowLayout extends StatelessWidget {
  const GrowLayout({
    super.key,
    required this.body,
    this.innerTitle,
    this.innerActions,
  });

  final Widget body;
  /// Second row (white): back + title — matches V1 Settings / Sprinkler / Add Crop headers.
  final String? innerTitle;
  final List<Widget>? innerActions;

  int? _tabIndex(String path) {
    if (path == '/plants' || path.startsWith('/plants?')) return 0;
    if (path == '/home') return 1;
    if (path == '/tools' ||
        path == '/chat' ||
        path == '/disease' ||
        path == '/soil' ||
        path == '/pest' ||
        path == '/market') {
      return 2;
    }
    if (path == '/add-crop') return 3;
    if (path == '/research' || path.startsWith('/research/')) return 4;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final path = GoRouterState.of(context).uri.path;
    final tab = _tabIndex(path);

    return Scaffold(
      backgroundColor: GrowColors.gray50,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GreenHeader(),
          if (innerTitle != null) _InnerTitleBar(title: innerTitle!, actions: innerActions),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 448),
                color: Colors.white,
                child: body,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Material(
        color: Colors.white,
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: GrowColors.gray200)),
            ),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _BottomNavItem(
                  icon: Icons.spa,
                  label: l.tabPlants,
                  selected: tab == 0,
                  onTap: () => context.go('/plants'),
                ),
                _BottomNavItem(
                  icon: Icons.calendar_today_outlined,
                  label: l.tabCalendar,
                  selected: tab == 1,
                  onTap: () => context.go('/home'),
                ),
                _BottomNavItem(
                  icon: Icons.chat_bubble_outline,
                  label: l.tabTools,
                  selected: tab == 2,
                  onTap: () => context.go('/tools'),
                ),
                _BottomNavItem(
                  icon: Icons.add,
                  label: l.tabAddPlant,
                  selected: tab == 3,
                  onTap: () => context.go('/add-crop'),
                ),
                _BottomNavItem(
                  icon: Icons.search,
                  label: l.tabResearch,
                  selected: tab == 4,
                  onTap: () => context.go('/research'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InnerTitleBar extends StatelessWidget {
  const _InnerTitleBar({required this.title, this.actions});

  final String title;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
        child: Row(
          children: [
            if (context.canPop())
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black87),
                onPressed: () => context.pop(),
              )
            else
              const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            ...?actions,
          ],
        ),
      ),
    );
  }
}

class _GreenHeader extends ConsumerWidget {
  const _GreenHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    ref.watch(inAppNotificationsRevisionProvider);
    final unread = ref.watch(growStorageProvider).unreadNotificationCount();
    return Material(
      color: GrowColors.green600,
      elevation: 4,
      shadowColor: Colors.black26,
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12),
        bottomRight: Radius.circular(12),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 14),
          child: Row(
            children: [
              const Icon(Icons.eco, color: Colors.white, size: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.growsphereTitle,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none, color: Colors.white, size: 24),
                    if (unread > 0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.shade700,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unread > 9 ? '9+' : '$unread',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                tooltip: 'Notifications',
                onPressed: () => context.push('/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.mode_edit_outlined, color: Colors.white, size: 22),
                tooltip: l.settings,
                onPressed: () => context.push('/settings'),
              ),
              IconButton(
                icon: const Icon(Icons.grid_3x3, color: Colors.white, size: 22),
                tooltip: 'More',
                onPressed: () => showGrowToolsSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.water_drop, color: Colors.white, size: 22),
                tooltip: l.sprinkler,
                onPressed: () => context.push('/sprinkler'),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white, size: 22),
                tooltip: l.settings,
                onPressed: () => context.push('/settings'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// V1 active tab: black rounded pill, white icon + label.
class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: selected ? Colors.black87 : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: selected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
