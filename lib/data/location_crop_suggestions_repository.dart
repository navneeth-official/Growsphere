import 'dart:convert';

import 'package:geolocator/geolocator.dart';

import '../core/services/gemini_generative_service.dart';
import '../domain/plant.dart';
import 'ai_tool_ids.dart';
import 'grow_storage.dart';

/// Uses coarse GPS + Gemini (when configured) to pick catalog crops suited to the area.
class LocationCropSuggestionsRepository {
  LocationCropSuggestionsRepository({
    GeminiGenerativeService? gemini,
    GrowStorage? storage,
  })  : _gemini = gemini,
        _storage = storage;

  final GeminiGenerativeService? _gemini;
  final GrowStorage? _storage;

  Future<Position?> _tryPosition() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
      return null;
    }
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
    } catch (_) {
      return null;
    }
  }

  /// Returns ordered plant ids present in [catalog].
  Future<List<String>> suggestPlantIds(List<Plant> catalog) async {
    final allowed = catalog.map((e) => e.id).toSet();
    if (allowed.isEmpty) return [];
    final pos = await _tryPosition();
    final lat = pos?.latitude;
    final lng = pos?.longitude;
    if (_gemini != null) {
      try {
        final idsCsv = allowed.join(',');
        final mem = _storage?.buildAiToolContextBlock(AiToolIds.locationCropSuggest) ?? '';
        final user = '''
${mem.isNotEmpty ? 'PRIOR_TOOL_MEMORY:\n$mem\n\n' : ''}Approximate latitude: ${lat ?? 'unknown'}, longitude: ${lng ?? 'unknown'}.
Choose 6–12 crop ids well suited to this climate and typical Indian small-farm / home-garden conditions.
Use ONLY ids from this comma-separated list (no invented ids): $idsCsv
Output ONLY valid JSON: {"ids":["id1","id2",...]}
''';
        final raw = await _gemini!.generateText(
          systemInstruction: 'You output only compact JSON. No markdown fences.',
          userText: user,
        );
        final parsed = _parseIds(raw, allowed);
        if (parsed.isNotEmpty) {
          await _storage?.recordAiToolExchange(
            AiToolIds.locationCropSuggest,
            'Suggest ids lat=$lat lng=$lng',
            raw.length > 1200 ? '${raw.substring(0, 1200)}…' : raw,
          );
        }
        if (parsed.isNotEmpty) return parsed;
      } catch (_) {}
    }
    return _heuristicFallback(allowed, lat, lng);
  }

  List<String> _parseIds(String raw, Set<String> allowed) {
    var t = raw.trim();
    if (t.startsWith('```')) {
      t = t.replaceFirst(RegExp(r'^```json?\s*'), '').replaceFirst(RegExp(r'\s*```\s*$'), '');
    }
    try {
      final map = jsonDecode(t) as Map<String, dynamic>?;
      if (map == null) return [];
      final list = map['ids'] as List<dynamic>? ?? [];
      final out = <String>[];
      for (final e in list) {
        final id = e.toString();
        if (allowed.contains(id) && !out.contains(id)) out.add(id);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Latitude-based heuristic when Gemini or GPS is unavailable.
  List<String> _heuristicFallback(Set<String> allowed, double? lat, double? lng) {
    final pick = <String>[];
    void add(String id) {
      if (allowed.contains(id) && !pick.contains(id)) pick.add(id);
    }

    // Tropical / peninsular India (very rough band)
    final tropicalish = lat != null &&
        lat >= 6 &&
        lat <= 25 &&
        (lng == null || (lng >= 68 && lng <= 95));
    if (tropicalish) {
      for (final id in ['rice', 'okra', 'banana', 'tomato', 'chilli', 'brinjal', 'cucumber', 'coriander']) {
        add(id);
      }
    } else {
      for (final id in ['wheat', 'peas', 'spinach', 'carrot', 'onion', 'garlic', 'lettuce', 'potato']) {
        add(id);
      }
    }
    for (final id in ['tomato', 'chilli', 'okra', 'coriander', 'spinach', 'beans', 'rice', 'wheat']) {
      add(id);
    }
    for (final id in allowed) {
      if (pick.length >= 10) break;
      add(id);
    }
    return pick;
  }
}
