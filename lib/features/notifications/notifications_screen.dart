import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/providers.dart';
import '../../widgets/badge_medallion.dart';
import '../shell/grow_layout.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _clearAll(WidgetRef ref) async {
    await ref.read(growStorageProvider).clearInAppNotifications();
    ref.read(inAppNotificationsRevisionProvider.notifier).state++;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(inAppNotificationsRevisionProvider);
    final items = ref.watch(growStorageProvider).loadInAppNotifications();
    final cs = Theme.of(context).colorScheme;

    return GrowLayout(
      innerTitle: 'Notifications',
      innerActions: [
        TextButton(
          onPressed: items.isEmpty
              ? null
              : () async {
                  await _clearAll(ref);
                },
          child: const Text('Clear all'),
        ),
      ],
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No alerts yet. Task digests and sprinkler warnings will show up here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: cs.onSurfaceVariant, height: 1.4),
                ),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final m = items[i];
                final read = m['read'] == true;
                final title = m['title']?.toString() ?? '';
                final body = m['body']?.toString() ?? '';
                final badgeId = m['badgeId']?.toString();
                final hasBadge = badgeId != null && badgeId.isNotEmpty;
                final streakStyle = !hasBadge && title.startsWith('Perfect-day streak');
                return Card(
                  color: read ? cs.surfaceContainerHighest : cs.surface,
                  child: ListTile(
                    leading: hasBadge
                        ? BadgeMedallion(badgeId: badgeId, size: 44, unlocked: true)
                        : streakStyle
                            ? DecoratedBox(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.orange.shade400.withValues(alpha: 0.35),
                                      Colors.deepOrange.shade700.withValues(alpha: 0.9),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.orange.withValues(alpha: 0.35),
                                      blurRadius: 8,
                                      spreadRadius: 0.5,
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: Icon(Icons.local_fire_department, color: Colors.white, size: 24),
                                ),
                              )
                            : null,
                    title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: cs.onSurface)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        body,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          height: 1.35,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    trailing: read
                        ? Icon(Icons.done_all, color: cs.onSurfaceVariant, size: 20)
                        : Icon(Icons.circle, color: cs.primary, size: 12),
                    isThreeLine: true,
                    onTap: () {
                      if (!read) {
                        m['read'] = true;
                        ref.read(growStorageProvider).saveInAppNotifications(items);
                        ref.read(inAppNotificationsRevisionProvider.notifier).state++;
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
