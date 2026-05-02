import '../../data/grow_storage.dart';
import '../../data/plant_repository.dart';
import '../../domain/grow_session.dart';
import '../../domain/plant.dart';

/// Builds a single text block injected into Gemini as **retrieved app knowledge** (RAG-style).
/// No vector DB: full catalog is summarized; trim if you add thousands of rows.
class PlantRagContextService {
  PlantRagContextService({
    required PlantRepository plantRepository,
    required GrowStorage growStorage,
  })  : _plants = plantRepository,
        _storage = growStorage;

  final PlantRepository _plants;
  final GrowStorage _storage;

  static const _maxPlants = 80;
  static const _maxFieldLen = 220;

  Future<String> buildContextBlock() async {
    final buf = StringBuffer();
    buf.writeln('## GrowSphere embedded plant catalog (authoritative for crops listed here)');
    final List<Plant> list;
    try {
      list = await _plants.loadAll();
    } catch (e) {
      return '## Catalog\n(unavailable: $e)';
    }
    var n = 0;
    for (final p in list) {
      if (n >= _maxPlants) break;
      n++;
      buf.writeln(_plantLine(p));
    }
    buf.writeln('\n## Active grow session (if any)');
    final session = _storage.loadSessionSync();
    if (session == null) {
      buf.writeln('No active session.');
    } else {
      buf.writeln(_sessionSummary(session));
    }
    return buf.toString();
  }

  String _plantLine(Plant p) {
    String clip(String s) {
      if (s.length <= _maxFieldLen) return s;
      return '${s.substring(0, _maxFieldLen)}…';
    }

    return '- **${p.name}** (id: `${p.id}`) | diff: ${p.difficulty} | water: ${p.wateringLevel} | '
        'harvest ~${p.harvestDurationDays}d | nutrientHeavy: ${p.nutrientHeavy}\n'
        '  climate: ${clip(p.climate)}\n'
        '  soil: ${clip(p.soil)}\n'
        '  fertilizer: ${clip(p.fertilizers)}\n'
        '  pests: ${clip(p.pestNotes)}';
  }

  String _sessionSummary(GrowSession s) {
    return '- plant: **${s.plantName}** (${s.plantId})\n'
        '- health: ${s.plantHealth}% | streak: ${s.streak}\n'
        '- location: ${s.location.name} | sun: ${s.sunlight.name}\n'
        '- watering note: ${s.wateringRecommendationText}';
  }

  static const _visionPestClip = 140;

  /// Short pest-focused catalog for vision tools. **No active session** — avoids biasing analysis toward the current grow.
  Future<String> buildVisionAssistBlock() async {
    final buf = StringBuffer();
    buf.writeln(
      'OPTIONAL_CATALOG (reference only). The photograph may show any plant, crop, weed, or non-plant object. '
      'Identify strictly from visible evidence; do not assume the subject matches any row below.\n',
    );
    final List<Plant> list;
    try {
      list = await _plants.loadAll();
    } catch (e) {
      return '(catalog unavailable: $e)';
    }
    var n = 0;
    for (final p in list) {
      if (n >= 55) break;
      n++;
      final pest = p.pestNotes.length <= _visionPestClip ? p.pestNotes : '${p.pestNotes.substring(0, _visionPestClip)}…';
      buf.writeln('- ${p.name}: common issues — $pest');
    }
    return buf.toString();
  }
}
