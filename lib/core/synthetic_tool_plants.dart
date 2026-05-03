import '../domain/plant.dart';

/// Builds a catalog [Plant] for soil-recovery / cover-crop entries from tools (stored as custom plants).
Plant syntheticLegumeCoverPlant(String displayName) {
  final slug = displayName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final id = 'tool_cover_${slug}_${DateTime.now().microsecondsSinceEpoch}';
  return Plant(
    id: id,
    name: '$displayName (cover crop)',
    aliases: [displayName, 'green manure', 'soil recovery'],
    difficulty: 'Easy',
    wateringLevel: 'medium',
    climate: 'Warm season legume cover; full sun to partial shade',
    soil: 'Well-drained loam; inoculate seed if nodulation is weak',
    fertilizers: 'Minimal N — relies on fixation; light P/K if soil tests very low',
    harvestDurationDays: 90,
    nutrientHeavy: false,
    pestNotes: 'Rotate families; terminate before heavy pest buildup if used only for soil.',
    typicalPricePerKg: 0,
  );
}

/// Microgreen row from the guide → persisted [Plant] for My Garden.
Plant syntheticMicrogreenPlant({
  required String name,
  required String retailLabel,
  required int harvestDurationDays,
}) {
  final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  final id = 'tool_micro_$slug_${DateTime.now().microsecondsSinceEpoch}';
  return Plant(
    id: id,
    name: name,
    aliases: ['microgreens', 'microgreen'],
    difficulty: 'Easy',
    wateringLevel: 'high',
    climate: 'Indoor windowsill / shelf; mild temps 18–26°C',
    soil: 'Sterile coco coir or grow mat on shallow tray',
    fertilizers: 'Optional quarter-strength feed after first true leaves',
    harvestDurationDays: harvestDurationDays,
    nutrientHeavy: false,
    pestNotes: 'Damping-off risk if too wet — gentle airflow and thin sowing.',
    typicalPricePerKg: 0,
  );
}

/// Parses "8–12 days" or "10-14 days" → midpoint days, default 12.
int parseMicrogreenHarvestDays(String durationLine) {
  final m = RegExp(r'(\d+)\s*[–-]\s*(\d+)').firstMatch(durationLine);
  if (m == null) {
    final single = RegExp(r'(\d+)\s*days?').firstMatch(durationLine.toLowerCase());
    if (single != null) return int.tryParse(single.group(1)!) ?? 12;
    return 12;
  }
  final a = int.tryParse(m.group(1)!) ?? 8;
  final b = int.tryParse(m.group(2)!) ?? 12;
  return ((a + b) / 2).round().clamp(5, 60);
}
