import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/grow_enums.dart';
import '../../providers/providers.dart';
import '../shell/grow_tools_sheet.dart';

class EnvironmentScreen extends ConsumerStatefulWidget {
  const EnvironmentScreen({super.key, required this.plantId});

  final String plantId;

  @override
  ConsumerState<EnvironmentScreen> createState() => _EnvironmentScreenState();
}

class _EnvironmentScreenState extends ConsumerState<EnvironmentScreen> {
  GrowLocationType _loc = GrowLocationType.balcony;
  SunlightLevel _sun = SunlightLevel.medium;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return GrowSubpageScaffold(
      title: l.environmentTitle,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l.locationLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<GrowLocationType>(
              segments: [
                ButtonSegment(value: GrowLocationType.indoor, label: Text(l.indoor)),
                ButtonSegment(value: GrowLocationType.balcony, label: Text(l.balcony)),
                ButtonSegment(value: GrowLocationType.terrace, label: Text(l.terrace)),
              ],
              selected: {_loc},
              onSelectionChanged: (s) => setState(() => _loc = s.first),
            ),
            const SizedBox(height: 24),
            Text(l.sunlightLabel, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<SunlightLevel>(
              segments: [
                ButtonSegment(value: SunlightLevel.low, label: Text(l.sunLow)),
                ButtonSegment(value: SunlightLevel.medium, label: Text(l.sunMedium)),
                ButtonSegment(value: SunlightLevel.high, label: Text(l.sunHigh)),
              ],
              selected: {_sun},
              onSelectionChanged: (s) => setState(() => _sun = s.first),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () async {
                final plant = await ref.read(plantRepositoryProvider).byId(widget.plantId);
                if (plant == null || !context.mounted) return;
                await ref.read(sessionControllerProvider.notifier).startGrow(
                      plant: plant,
                      location: _loc,
                      sunlight: _sun,
                    );
                if (context.mounted) context.go('/home');
              },
              child: Text(l.continueLabel),
            ),
          ],
        ),
      ),
    );
  }
}
