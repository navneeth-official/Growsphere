import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/plant_catalog_image.dart';
import '../../core/theme/grow_colors.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

class PlantDetailScreen extends ConsumerStatefulWidget {
  const PlantDetailScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends ConsumerState<PlantDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    ref.watch(localDataRevisionProvider);
    final async = ref.watch(_plantProvider(widget.plantId));

    return async.when(
      data: (p) {
        if (p == null) {
          return GrowLayout(
            body: Center(child: Text(l.appTitle)),
          );
        }

        final cs = Theme.of(context).colorScheme;

        return GrowLayout(
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
            children: [
              if (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: plantCatalogImage(
                      p.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image)),
                    ),
                  ),
                ),
              if (p.imageUrl != null && p.imageUrl!.isNotEmpty) const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text('${l.difficulty}: ${p.difficulty}')),
                  Chip(label: Text('${l.watering}: ${p.wateringLevel}')),
                  Chip(label: Text('${p.harvestDurationDays} d harvest')),
                ],
              ),
              const SizedBox(height: 16),
              _infoCard(
                colorScheme: cs,
                icon: Icons.thermostat,
                iconColor: const Color(0xFFEA580C),
                title: l.climateRequirementsTitle,
                body: p.climate,
              ),
              const SizedBox(height: 12),
              _infoCard(
                colorScheme: cs,
                icon: Icons.water_drop_outlined,
                iconColor: const Color(0xFF2563EB),
                title: l.soilRequirementsTitle,
                body: p.soil,
              ),
              const SizedBox(height: 12),
              _infoCard(
                colorScheme: cs,
                icon: Icons.eco,
                iconColor: GrowColors.green600,
                title: l.fertilizerNeedsTitle,
                body: p.fertilizers,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.push('/plant-garden-setup/${p.id}'),
                child: Text(l.addToGarden),
              ),
            ],
          ),
        );
      },
      loading: () => const GrowLayout(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => GrowLayout(body: Center(child: Text('$e'))),
    );
  }

  Widget _infoCard({
    required ColorScheme colorScheme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String body,
  }) {
    final cs = colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      height: 1.45,
                      color: cs.onSurface,
                    ),
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

final _plantProvider = FutureProvider.family<Plant?, String>((ref, id) async {
  ref.watch(localDataRevisionProvider);
  return ref.read(plantRepositoryProvider).byId(id);
});
