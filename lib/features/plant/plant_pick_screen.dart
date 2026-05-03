import 'dart:async';

import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/plant_catalog_image.dart';
import '../../core/plant_catalog_category.dart';
import '../../data/location_crop_suggestions_repository.dart';
import '../../domain/plant.dart';
import '../../providers/providers.dart';
import '../shell/grow_layout.dart';

enum _PlantSort { nameAZ, harvestShort, harvestLong, difficultyEasyFirst }

final _locationSuggestedPlantsProvider = FutureProvider<List<Plant>>((ref) async {
  ref.watch(localDataRevisionProvider);
  final catalog = await ref.read(plantRepositoryProvider).loadAll();
  final gemini = ref.read(geminiGenerativeServiceProvider);
  final repo = LocationCropSuggestionsRepository(gemini: gemini);
  final ids = await repo.suggestPlantIds(catalog);
  final byId = {for (final p in catalog) p.id: p};
  return ids.map((id) => byId[id]).whereType<Plant>().toList();
});

class PlantPickScreen extends ConsumerStatefulWidget {
  const PlantPickScreen({super.key});

  @override
  ConsumerState<PlantPickScreen> createState() => _PlantPickScreenState();
}

class _PlantPickScreenState extends ConsumerState<PlantPickScreen> {
  final _controller = TextEditingController();
  final _catPageCtrl = PageController(viewportFraction: 0.88);
  Timer? _carouselTimer;
  String _q = '';
  int _catPageIndex = 0;
  _PlantSort _sort = _PlantSort.nameAZ;
  String? _difficultyFilter; // null = all
  bool _pauseCarousel = false;

  @override
  void initState() {
    super.initState();
    _carouselTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_catPageCtrl.hasClients || _pauseCarousel) return;
      final n = PlantCatalogCategory.carouselShelfOrder.length;
      final cur = _catPageCtrl.page!.round().clamp(0, n - 1);
      final next = (cur + 1) % n;
      _catPageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 520),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _catPageCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _touchCarousel() {
    setState(() => _pauseCarousel = true);
    Future.delayed(const Duration(seconds: 9), () {
      if (mounted) setState(() => _pauseCarousel = false);
    });
  }

  int _monthsFromDays(int days) => (days / 30).round().clamp(1, 36);

  int _difficultyRank(String d) {
    return switch (d.toLowerCase()) {
      'easy' => 0,
      'medium' => 1,
      _ => 2,
    };
  }

  String _categoryOf(Plant p) => PlantCatalogCategory.inferForPlantId(p.id);

  List<Plant> _applyBrowse(List<Plant> plants) {
    var list = plants.where((p) => p.matchesQuery(_q)).toList();
    if (_difficultyFilter != null) {
      list = list.where((p) => p.difficulty.toLowerCase() == _difficultyFilter).toList();
    }
    switch (_sort) {
      case _PlantSort.nameAZ:
        list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
        break;
      case _PlantSort.harvestShort:
        list.sort((a, b) => a.harvestDurationDays.compareTo(b.harvestDurationDays));
        break;
      case _PlantSort.harvestLong:
        list.sort((a, b) => b.harvestDurationDays.compareTo(a.harvestDurationDays));
        break;
      case _PlantSort.difficultyEasyFirst:
        list.sort((a, b) => _difficultyRank(a.difficulty).compareTo(_difficultyRank(b.difficulty)));
        break;
    }
    return list;
  }

  void _onAddNewPlant() => context.go('/add-crop');

  void _openCategorySheet(BuildContext context, String categoryId, List<Plant> allPlants, AppLocalizations l) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = categoryId == PlantCatalogCategory.all
        ? List<Plant>.from(allPlants)
        : allPlants.where((p) => PlantCatalogCategory.inferForPlantId(p.id) == categoryId).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      builder: (sheetCtx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.58,
          minChildSize: 0.32,
          maxChildSize: 0.94,
          builder: (_, scrollController) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: 60,
                          height: 60,
                          child: plantCatalogImage(
                            PlantCatalogCategory.coverImageUrl(categoryId),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                ColoredBox(color: cs.primary.withValues(alpha: 0.35)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              PlantCatalogCategory.labelOf(categoryId),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: cs.onSurface,
                              ),
                            ),
                            Text(
                              '${list.length} crops · tap for full info & farm setup',
                              style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant, height: 1.3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => Divider(height: 1, color: cs.outline.withValues(alpha: 0.25)),
                    itemBuilder: (_, i) {
                      final p = list[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: SizedBox(
                            width: 52,
                            height: 52,
                            child: _PlantThumb(imageUrl: p.imageUrl),
                          ),
                        ),
                        title: Text(
                          p.name,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: cs.onSurface),
                        ),
                        subtitle: Text(
                          '${p.difficulty} · ${p.harvestDurationDays} d harvest',
                          style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
                        ),
                        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
                        onTap: () {
                          Navigator.of(sheetCtx).pop();
                          context.push('/plant-garden-setup/${p.id}');
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final async = ref.watch(_plantsFutureProvider);
    final locSuggest = ref.watch(_locationSuggestedPlantsProvider);

    return GrowLayout(
      body: async.when(
        data: (plants) {
          final customs = plants.where((p) => p.id.startsWith('custom_')).toList();
          final filtered = _applyBrowse(plants);
          return CustomScrollView(
            slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Text(
                      l.whichPlant,
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: l.searchPlantsHint,
                        prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 22),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() => _q = v),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ChoiceChip(
                              label: const Text('All levels', style: TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              selected: _difficultyFilter == null,
                              onSelected: (_) => setState(() => _difficultyFilter = null),
                            ),
                            ChoiceChip(
                              label: const Text('Easy', style: TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              selected: _difficultyFilter == 'easy',
                              onSelected: (_) => setState(() => _difficultyFilter = 'easy'),
                            ),
                            ChoiceChip(
                              label: const Text('Medium', style: TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              selected: _difficultyFilter == 'medium',
                              onSelected: (_) => setState(() => _difficultyFilter = 'medium'),
                            ),
                            ChoiceChip(
                              label: const Text('Hard', style: TextStyle(fontSize: 12)),
                              visualDensity: VisualDensity.compact,
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                              selected: _difficultyFilter == 'hard',
                              onSelected: (_) => setState(() => _difficultyFilter = 'hard'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Text(
                              'Sort',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: cs.onSurface,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<_PlantSort>(
                                    isDense: true,
                                    value: _sort,
                                    borderRadius: BorderRadius.circular(12),
                                    style: GoogleFonts.inter(fontSize: 13, color: cs.onSurface),
                                    items: const [
                                      DropdownMenuItem(value: _PlantSort.nameAZ, child: Text('Name A–Z')),
                                      DropdownMenuItem(value: _PlantSort.harvestShort, child: Text('Harvest: shortest')),
                                      DropdownMenuItem(value: _PlantSort.harvestLong, child: Text('Harvest: longest')),
                                      DropdownMenuItem(
                                        value: _PlantSort.difficultyEasyFirst,
                                        child: Text('Difficulty: easy first'),
                                      ),
                                    ],
                                    onChanged: (v) => setState(() => _sort = v ?? _PlantSort.nameAZ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: FilledButton.icon(
                      onPressed: _onAddNewPlant,
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(l.addNewPlant),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Browse by category',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap a shelf to explore — the full catalog stays below.',
                                style: GoogleFonts.inter(
                                    fontSize: 12, color: cs.onSurfaceVariant, height: 1.3),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 132,
                          child: NotificationListener<UserScrollNotification>(
                            onNotification: (_) {
                              _touchCarousel();
                              return false;
                            },
                            child: PageView.builder(
                              controller: _catPageCtrl,
                              itemCount: PlantCatalogCategory.carouselShelfOrder.length,
                              onPageChanged: (i) => setState(() => _catPageIndex = i),
                              itemBuilder: (context, i) {
                                final id = PlantCatalogCategory.carouselShelfOrder[i];
                                final count = id == PlantCatalogCategory.all
                                    ? plants.length
                                    : plants.where((p) => _categoryOf(p) == id).length;
                                return Padding(
                                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
                                  child: _CategoryHeroCard(
                                    categoryId: id,
                                    plantCount: count,
                                    selected: i == _catPageIndex,
                                    coverImageUrl: PlantCatalogCategory.coverImageUrl(id),
                                    onTap: () => _openCategorySheet(context, id, plants, l),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            PlantCatalogCategory.carouselShelfOrder.length,
                            (i) => Container(
                              width: i == _catPageIndex ? 18 : 6,
                              height: 6,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == _catPageIndex ? cs.primary : cs.outline.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Row(
                      children: [
                        Icon(Icons.near_me_outlined, color: cs.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Grows well near you',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: locSuggest.when(
                    data: (near) {
                      if (near.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Enable location or Gemini for tailored picks — showing popular starters.',
                            style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant, height: 1.35),
                          ),
                        );
                      }
                      return SizedBox(
                        height: 168,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          itemCount: near.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 148,
                            child: _CompactPlantCard(
                              plant: near[i],
                              monthsLabel: l.growthPeriodMonths(_monthsFromDays(near[i].harvestDurationDays)),
                              onOpen: () => context.push('/plant-garden-setup/${near[i].id}'),
                            ),
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),
                if (customs.isNotEmpty) ...[
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Text(
                        'Your added crops',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: 168,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        itemCount: customs.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (_, i) => SizedBox(
                          width: 148,
                          child: _CompactPlantCard(
                            plant: customs[i],
                            monthsLabel: l.growthPeriodMonths(_monthsFromDays(customs[i].harvestDurationDays)),
                            onOpen: () => context.push('/plant-garden-setup/${customs[i].id}'),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final p = filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _PlantCard(
                            plant: p,
                            monthsLabel: l.growthPeriodMonths(_monthsFromDays(p.harvestDurationDays)),
                            categoryLabel: PlantCatalogCategory.labelOf(_categoryOf(p)),
                            onOpen: () => context.push('/plant-garden-setup/${p.id}'),
                          ),
                        );
                      },
                      childCount: filtered.length,
                    ),
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

class _CategoryHeroCard extends StatelessWidget {
  const _CategoryHeroCard({
    required this.categoryId,
    required this.plantCount,
    required this.selected,
    required this.coverImageUrl,
    required this.onTap,
  });

  final String categoryId;
  final int plantCount;
  final bool selected;
  final String coverImageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? cs.primary : cs.outline.withValues(alpha: 0.4),
              width: selected ? 2.5 : 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                plantCatalogImage(
                  coverImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => ColoredBox(
                    color: cs.primary.withValues(alpha: 0.45),
                    child: Icon(Icons.eco, size: 48, color: cs.onPrimary.withValues(alpha: 0.9)),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.72),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        PlantCatalogCategory.labelOf(categoryId),
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: const [
                            Shadow(offset: Offset(0, 1), blurRadius: 8, color: Color(0x88000000)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$plantCount crops · tap to browse',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.95),
                          shadows: const [
                            Shadow(offset: Offset(0, 1), blurRadius: 6, color: Color(0x77000000)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Icon(Icons.touch_app_rounded, color: Colors.white.withValues(alpha: 0.95), size: 22),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactPlantCard extends StatelessWidget {
  const _CompactPlantCard({
    required this.plant,
    required this.monthsLabel,
    required this.onOpen,
  });

  final Plant plant;
  final String monthsLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: double.infinity,
                    child: _PlantThumb(imageUrl: plant.imageUrl),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                plant.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: cs.onSurface),
              ),
              Text(
                monthsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 11, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlantCard extends ConsumerWidget {
  const _PlantCard({
    required this.plant,
    required this.monthsLabel,
    required this.categoryLabel,
    required this.onOpen,
  });

  final Plant plant;
  final String monthsLabel;
  final String categoryLabel;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context, WidgetRef _) {
    final l = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: _PlantThumb(imageUrl: plant.imageUrl),
                ),
              ),
              const SizedBox(width: 14),
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
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plant.id.startsWith('custom_') ? l.customBadge : l.defaultBadge,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: cs.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      categoryLabel,
                      style: GoogleFonts.inter(fontSize: 12, color: cs.primary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      monthsLabel,
                      style: GoogleFonts.inter(fontSize: 13, color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: onOpen,
                      style: FilledButton.styleFrom(
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
    final cs = Theme.of(context).colorScheme;
    final u = imageUrl;
    if (u == null || u.isEmpty) {
      return ColoredBox(
        color: cs.primary.withValues(alpha: 0.15),
        child: Icon(Icons.eco, color: cs.primary, size: 36),
      );
    }
    return plantCatalogImage(
      u,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => ColoredBox(
        color: cs.primary.withValues(alpha: 0.15),
        child: Icon(Icons.eco, color: cs.primary, size: 36),
      ),
    );
  }
}

final _plantsFutureProvider = FutureProvider<List<Plant>>((ref) async {
  ref.watch(localDataRevisionProvider);
  return ref.read(plantRepositoryProvider).loadAll();
});
