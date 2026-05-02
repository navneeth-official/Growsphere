import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(inAppNotificationsRevisionProvider);
    final items = ref.watch(growStorageProvider).loadInAppNotifications();

    return GrowLayout(
      innerTitle: 'Notifications',
      innerActions: [
        TextButton(
          onPressed: items.isEmpty
              ? null
              : () async {
                  await ref.read(growStorageProvider).markAllNotificationsRead();
                  ref.read(inAppNotificationsRevisionProvider.notifier).state++;
                },
          child: const Text('Mark all read'),
        ),
      ],
      body: items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No alerts yet. Task digests and sprinkler warnings will show up here.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: GrowColors.gray600, height: 1.4),
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
                final at = m['at']?.toString() ?? '';
                return Card(
                  color: read ? GrowColors.gray50 : Colors.white,
                  child: ListTile(
                    title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        body,
                        style: GoogleFonts.inter(fontSize: 14, height: 1.35, color: GrowColors.gray700),
                      ),
                    ),
                    trailing: read
                        ? Icon(Icons.done_all, color: GrowColors.gray400, size: 20)
                        : Icon(Icons.circle, color: GrowColors.green600, size: 12),
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
