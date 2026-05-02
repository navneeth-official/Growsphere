import 'dart:io';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/grow_colors.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

class PlantPickScreen extends ConsumerStatefulWidget {
  const PlantPickScreen({super.key});

  @override
  ConsumerState<PlantPickScreen> createState() => _PlantPickScreenState();
}

class _PlantPickScreenState extends ConsumerState<PlantPickScreen> {
  final _controller = TextEditingController();
  String _q = '';

  int _monthsFromDays(int days) => (days / 30).round().clamp(1, 36);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAddNewPlant() => context.go('/add-crop');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final async = ref.watch(_plantsFutureProvider);
    return GrowLayout(
      body: async.when(
        data: (plants) {
          final filtered = plants.where((p) => p.matchesQuery(_q)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Text(
                  l.whichPlant,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: GrowColors.gray700,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: l.searchPlantsHint,
                    prefixIcon: const Icon(Icons.search, color: GrowColors.gray400, size: 20),
                    isDense: true,
                  ),
                  onChanged: (v) => setState(() => _q = v),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: FilledButton.icon(
                  onPressed: _onAddNewPlant,
                  style: FilledButton.styleFrom(
                    backgroundColor: GrowColors.green600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.add, size: 20),
                  label: Text(l.addNewPlant),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (_, i) {
                    final p = filtered[i];
                    return _PlantCard(
                      plant: p,
                      monthsLabel: l.growthPeriodMonths(_monthsFromDays(p.harvestDurationDays)),
                      onOpen: () => context.push('/plant/${p.id}'),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Padding(
          padding: EdgeInsets.all(48),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text('$e')),
        ),
      ),
    );
  }
}

class _PlantCard extends ConsumerWidget {
  const _PlantCard({
    required this.plant,
    required this.monthsLabel,
    required this.onOpen,
  });

  final Plant plant;
  final String monthsLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final l = AppLocalizations.of(context)!;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GrowColors.gray200),
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _PlantThumb(imageUrl: plant.imageUrl),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            plant.name,
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: GrowColors.gray200.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plant.id.startsWith('custom_') ? l.customBadge : l.defaultBadge,
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthsLabel,
                      style: GoogleFonts.inter(fontSize: 14, color: GrowColors.gray600),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(l.learnMore),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantThumb extends StatelessWidget {
  const _PlantThumb({required this.imageUrl});

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    final u = imageUrl;
    if (u == null || u.isEmpty) {
      return ColoredBox(
        color: GrowColors.green100,
        child: const Center(child: Icon(Icons.eco, color: GrowColors.green600, size: 36)),
      );
    }
    if (u.startsWith('http')) {
      return Image.network(
        u,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: GrowColors.green100,
          child: const Center(child: Icon(Icons.eco, color: GrowColors.green600, size: 36)),
        ),
      );
    }
    final f = File(u);
    if (f.existsSync()) {
      return Image.file(
        f,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => ColoredBox(
          color: GrowColors.green100,
          child: const Center(child: Icon(Icons.eco, color: GrowColors.green600, size: 36)),
        ),
      );
    }
    return ColoredBox(
      color: GrowColors.green100,
      child: const Center(child: Icon(Icons.eco, color: GrowColors.green600, size: 36)),
    );
  }
}

final _plantsFutureProvider = FutureProvider<List<Plant>>((ref) async {
  ref.watch(localDataRevisionProvider);
  return ref.read(plantRepositoryProvider).loadAll();
});
