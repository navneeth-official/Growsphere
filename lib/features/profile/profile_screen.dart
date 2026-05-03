import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../../domain/badge_catalog.dart';
import '../../domain/grow_session.dart';
import '../../providers/providers.dart';
import '../../widgets/badge_medallion.dart';
import '../shell/grow_layout.dart';

/// Growsphere-style profile: display name, cross-crop streaks, merged badges.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _dirty = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localDataRevisionProvider);
    final storage = ref.watch(growStorageProvider);
    final garden = ref.watch(gardenListProvider);
    final archives = storage.loadGrowArchives();
    final journey = storage.loadUserJourneyBadgeIds();
    final display = storage.profileDisplayName;
    final photoPath = storage.profilePhotoPath;
    final email = storage.profileEmail;
    final phone = storage.profilePhone;

    if (!_dirty && _nameCtrl.text.isEmpty && display != null) {
      _nameCtrl.text = display;
    }
    if (!_dirty && _emailCtrl.text.isEmpty && email != null) {
      _emailCtrl.text = email;
    }
    if (!_dirty && _phoneCtrl.text.isEmpty && phone != null) {
      _phoneCtrl.text = phone;
    }

    final cs = Theme.of(context).colorScheme;
    final allSessions = <GrowSession>[
      ...garden,
      ...archives.map((raw) {
        try {
          return GrowSession.fromJson(Map<String, dynamic>.from(raw));
        } catch (_) {
          return null;
        }
      }).whereType<GrowSession>(),
    ];

    var totalBest = 0;
    final cropLines = <String>[];
    final seen = <String>{};
    for (final s in allSessions) {
      if (!seen.add(s.gardenInstanceId)) continue;
      totalBest = totalBest + s.bestStreak;
      cropLines.add('${s.plantName} · best streak ${s.bestStreak} · current ${s.streak}');
    }

    final archiveSessions = <GrowSession>[];
    for (final raw in archives) {
      try {
        archiveSessions.add(GrowSession.fromJson(Map<String, dynamic>.from(raw)));
      } catch (_) {}
    }
    final activeIds = garden.map((e) => e.gardenInstanceId).toSet();
    final pastSeasons = archiveSessions.where((s) => !activeIds.contains(s.gardenInstanceId)).toList();

    return GrowLayout(
      innerTitle: 'My profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          Card(
            color: cs.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: cs.primary,
                        backgroundImage: () {
                          final p = photoPath;
                          if (p == null || !File(p).existsSync()) return null;
                          return FileImage(File(p));
                        }(),
                        child: () {
                          final p = photoPath;
                          if (p != null && File(p).existsSync()) return null;
                          return Icon(Icons.person, size: 48, color: cs.onPrimary);
                        }(),
                      ),
                      Positioned(
                        child: Material(
                          color: cs.secondaryContainer,
                          shape: const CircleBorder(),
                          child: IconButton(
                            tooltip: 'Change photo',
                            icon: Icon(Icons.camera_alt, size: 18, color: cs.onSecondaryContainer),
                            onPressed: () async {
                              final x = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1200,
                                imageQuality: 88,
                              );
                              if (x == null || !context.mounted) return;
                              try {
                                final dir = await getApplicationDocumentsDirectory();
                                final dest = File('${dir.path}/profile_avatar.jpg');
                                await File(x.path).copy(dest.path);
                                await storage.setProfilePhotoPath(dest.path);
                                ref.read(localDataRevisionProvider.notifier).state++;
                                setState(() => _dirty = true);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Could not save photo: $e')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () async {
                      await storage.setProfilePhotoPath(null);
                      ref.read(localDataRevisionProvider.notifier).state++;
                      setState(() => _dirty = true);
                    },
                    child: const Text('Remove photo'),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    display ?? 'Growsphere grower',
                    style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photo, name, email, and phone are stored on this device for reminders and updates.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant, height: 1.35),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() => _dirty = true),
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Display name',
                      hintText: 'e.g. Priya',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailCtrl,
                    onChanged: (_) => setState(() => _dirty = true),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'you@example.com',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneCtrl,
                    onChanged: (_) => setState(() => _dirty = true),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      hintText: '+91 …',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () async {
                        await storage.setProfileDisplayName(_nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text);
                        await storage.setProfileEmail(_emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text);
                        await storage.setProfilePhone(_phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text);
                        ref.read(localDataRevisionProvider.notifier).state++;
                        setState(() => _dirty = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Streaks across crops',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _statRow(cs, 'Active grows', '${garden.length}'),
                  _statRow(cs, 'Seasons in history', '${archives.length}'),
                  _statRow(cs, 'Sum of best streaks', '$totalBest days'),
                  if (cropLines.isNotEmpty) ...[
                    const Divider(height: 24),
                    Text('Per crop', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 8),
                    ...cropLines.take(8).map(
                          (line) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(line, style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant)),
                          ),
                        ),
                    if (cropLines.length > 8)
                      Text('+ ${cropLines.length - 8} more', style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Badges earned',
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.push('/streak-hub'),
                child: const Text('Details'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (journey.isEmpty && garden.every((s) => s.earnedBadgeIds.isEmpty) && pastSeasons.every((s) => s.earnedBadgeIds.isEmpty))
            Text(
              'Grow plants to unlock badges — they also appear under the bell.',
              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant, height: 1.4),
            )
          else ...[
            if (journey.isNotEmpty) ...[
              Text(
                'Journey',
                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
              ),
              const SizedBox(height: 4),
              Text(
                'Milestones across your profile',
                style: GoogleFonts.inter(fontSize: 12, color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: journey.map((id) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => context.push('/streak-hub'),
                    child: SizedBox(
                      width: 88,
                      child: Column(
                        children: [
                          BadgeMedallion(badgeId: id, size: 56, unlocked: true),
                          const SizedBox(height: 6),
                          Text(
                            BadgeCatalog.titleFor(id),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
            for (final s in garden) ...[
              if (s.earnedBadgeIds.isNotEmpty) ...[
                Text(
                  s.plantName,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Active grow · tap a badge for streak history',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: (s.earnedBadgeIds.toList()..sort()).map((id) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/streak-hub?focus=${Uri.encodeComponent(s.gardenInstanceId)}'),
                      child: SizedBox(
                        width: 88,
                        child: Column(
                          children: [
                            BadgeMedallion(badgeId: id, size: 56, unlocked: true),
                            const SizedBox(height: 6),
                            Text(
                              BadgeCatalog.titleFor(id),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ],
            for (final s in pastSeasons) ...[
              if (s.earnedBadgeIds.isNotEmpty) ...[
                Text(
                  s.plantName,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: cs.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  'Past season · tap a badge for streak history',
                  style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 12,
                  children: (s.earnedBadgeIds.toList()..sort()).map((id) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => context.push('/streak-hub?focus=${Uri.encodeComponent(s.gardenInstanceId)}'),
                      child: SizedBox(
                        width: 88,
                        child: Column(
                          children: [
                            BadgeMedallion(badgeId: id, size: 56, unlocked: true),
                            const SizedBox(height: 6),
                            Text(
                              BadgeCatalog.titleFor(id),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: cs.onSurface),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ],
        ],
      ),
    );
  }

  static Widget _statRow(ColorScheme cs, String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: cs.onSurface)),
          Text(v, style: GoogleFonts.inter(color: cs.onSurfaceVariant)),
        ],
      ),
    );
  }
}
