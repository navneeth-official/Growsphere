import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../data/grow_storage.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final storage = ref.watch(growStorageProvider);
    return GrowLayout(
      innerTitle: l.settings,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
        children: [
          _SectionCard(
            icon: Icons.light_mode_outlined,
            title: l.appearance,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.darkMode, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(l.appearanceDarkSubtitle, style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
              value: storage.themeModePref == ThemeModePref.dark,
              onChanged: (v) async {
                await storage.setThemeModePref(v ? ThemeModePref.dark : ThemeModePref.light);
                ref.read(uiTickProvider.notifier).state++;
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.notifications_outlined,
            title: l.notifications,
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.pushNotifications, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(l.pushNotificationsSubtitle, style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
                  value: storage.pushNotificationsEnabled,
                  onChanged: (v) async {
                    await storage.setPushNotificationsEnabled(v);
                    ref.read(uiTickProvider.notifier).state++;
                  },
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l.wateringReminders, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  subtitle: Text(l.wateringRemindersSubtitle, style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
                  value: storage.wateringRemindersEnabled,
                  onChanged: (v) async {
                    await storage.setWateringRemindersEnabled(v);
                    final n = ref.read(notificationServiceProvider);
                    if (v) {
                      await n.scheduleWaterReminders();
                    } else {
                      await n.cancelWaterReminders();
                    }
                    ref.read(uiTickProvider.notifier).state++;
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.water_drop_outlined,
            title: l.sprinklerSystem,
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.smartControl, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              subtitle: Text(l.smartControlSubtitle, style: GoogleFonts.inter(fontSize: 13, color: GrowColors.gray600)),
              value: storage.smartSprinklerControlEnabled,
              onChanged: (v) async {
                await storage.setSmartSprinklerControlEnabled(v);
                ref.read(uiTickProvider.notifier).state++;
              },
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.smartphone_outlined,
            title: l.appInformation,
            child: Column(
              children: [
                _kvRow(l.versionLabel, '1.0.0'),
                _kvRow(l.lastUpdatedLabel, 'Today'),
                _kvRow(l.storageUsedLabel, '2.4 MB'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.refresh,
            title: l.plantManagement,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l.restoreDefaultPlants)),
                    );
                  },
                  icon: const Icon(Icons.restore),
                  label: Text(l.restoreDefaultPlants),
                ),
                const SizedBox(height: 8),
                Text(l.restoreDefaultPlantsDetail, style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.warning_amber_rounded,
            title: l.dangerZone,
            tint: const Color(0xFFFFF5F5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l.clearAllData),
                        content: Text(l.clearAllConfirm),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.cancel)),
                          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l.clearAllData)),
                        ],
                      ),
                    );
                    if (ok != true || !context.mounted) return;
                    await storage.wipeAll();
                    ref.invalidate(sessionControllerProvider);
                    ref.read(routeRefreshProvider).refresh();
                    ref.read(uiTickProvider.notifier).state++;
                    if (context.mounted) context.go('/welcome');
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: Text(l.clearAllData),
                ),
                const SizedBox(height: 8),
                Text(l.clearAllDataFooter, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: GrowColors.gray600)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l.language),
            trailing: DropdownButton<String>(
              value: storage.localeCode == 'hi' ? 'hi' : 'en',
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
              ],
              onChanged: (c) async {
                if (c == null) return;
                await storage.setLocaleCode(c);
                ref.read(uiTickProvider.notifier).state++;
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _kvRow(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          Text(v, style: GoogleFonts.inter(color: GrowColors.gray700)),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.tint,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: tint,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 22),
                const SizedBox(width: 8),
                Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
