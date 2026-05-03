import 'dart:convert';

import '../core/services/gemini_generative_service.dart';
import '../core/services/plant_rag_context_service.dart';
import 'market_price_repository.dart';

/// Uses Gemini with RAG + general knowledge to **estimate** indicative wholesale-style prices.
/// Not a live exchange feed — model may hallucinate; good for demos until you wire a real API.
class GeminiMarketPriceRepository implements MarketPriceRepository {
  GeminiMarketPriceRepository({
    required GeminiGenerativeService gemini,
    required PlantRagContextService rag,
  })  : _gemini = gemini,
        _rag = rag;

  final GeminiGenerativeService _gemini;
  final PlantRagContextService _rag;

  static const _system = '''
You output only JSON (no markdown fences): one JSON object with two keys:
1) "rows": array of {"crop": string, "pricePerKg": number, "unit": "INR/kg", "changePercent": number}
   — 5–10 major crops traded in the USER_REGION. Prices are rough indicative INR/kg at mandi/yard level.
   changePercent = plausible recent % swing (can be negative).
2) "series": array of up to 4 objects {"crop": string, "points": [{"label": string, "price": number}, ...]}
   — for each of the top few crops in "rows", include 7 chronological points (labels like "-6d","-5d",...,"0d")
   showing a believable smooth trend ending at the row's pricePerKg at "0d". Values must stay positive.
Optional key "insight" (string): one short sentence on regional demand or seasonality (plain text).

Use catalog typicalPricePerKg only as a weak prior. Mention in your head that figures are estimates.
''';

  static const _systemCropSearch = '''
You output only JSON (no markdown fences): one object with keys:
- "rows": array of 1–3 objects {"crop": string, "pricePerKg": number, "unit": "INR/kg", "changePercent": number}
  for TARGET_CROP in USER_REGION (mandi-style indicative INR/kg). If the crop has common grades, you may
  include a second row for a related grade or local synonym.
- "series": array with one object {"crop": string, "points": [{"label": string, "price": number}, ...]}
  with 7 points "-6d" … "0d" ending at the primary row's pricePerKg.
- "insight": string — 2–3 sentences: typical seasonality, quality cues, or what buyers watch in this region.
Figures are estimates, not exchange quotes.
''';

  static const _systemSuggest = '''
Return only JSON (no markdown): {"suggestions": ["name1", "name2", ...]} — 6 crop or commodity names
that a farmer might search for in India given the partial text PARTIAL. Include close spellings and
related crops; not limited to any fixed database.
''';

  @override
  Future<MarketBoardResult> fetchBoard({
    required String regionLabel,
    String? geoHint,
  }) async {
    final rag = await _rag.buildContextBlock();
    final now = DateTime.now();
    final geo = geoHint == null || geoHint.isEmpty ? '(not provided)' : geoHint;
    final prompt = '''
USER_REGION (primary): $regionLabel
DEVICE_GEO_HINT: $geo

RAG_CONTEXT (catalog typicalPricePerKg — weak priors only):
$rag

Timestamp: ${now.toIso8601String()}
Return the JSON object only.
''';
    final raw = await _gemini.generateText(systemInstruction: _system, userText: prompt);
    return _parseBoard(raw, now);
  }

  @override
  Future<MarketBoardResult> searchCropPrices({
    required String cropQuery,
    required String regionLabel,
    String? geoHint,
  }) async {
    final rag = await _rag.buildContextBlock();
    final now = DateTime.now();
    final geo = geoHint == null || geoHint.isEmpty ? '(not provided)' : geoHint;
    final crop = cropQuery.trim().isEmpty ? 'unspecified crop' : cropQuery.trim();
    final prompt = '''
TARGET_CROP: $crop
USER_REGION (primary): $regionLabel
DEVICE_GEO_HINT: $geo

RAG_CONTEXT (weak priors only):
$rag

Timestamp: ${now.toIso8601String()}
Return the JSON object only.
''';
    final raw = await _gemini.generateText(systemInstruction: _systemCropSearch, userText: prompt);
    return _parseBoard(raw, now);
  }

  @override
  Future<List<String>> suggestCropNames(String partial) async {
    final t = partial.trim();
    if (t.length < 2) return [];
    final raw = await _gemini.generateText(
      systemInstruction: _systemSuggest.replaceAll('PARTIAL', t),
      userText: 'Partial search: $t',
    );
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) return [];
      final root = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      final s = root['suggestions'];
      if (s is! List) return [];
      return s.map((e) => '$e').where((e) => e.trim().isNotEmpty).take(8).toList();
    } catch (_) {
      return [];
    }
  }

  MarketBoardResult _parseBoard(String raw, DateTime updated) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start < 0 || end <= start) {
        return _fallback(updated);
      }
      final root = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
      final insight = root['insight'] is String ? root['insight'] as String : null;
      final rowsJson = root['rows'];
      final seriesJson = root['series'];
      final rows = <MarketRow>[];
      if (rowsJson is List) {
        for (final e in rowsJson) {
          final m = e as Map<String, dynamic>;
          rows.add(
            MarketRow(
              crop: '${m['crop']}',
              pricePerKg: (m['pricePerKg'] as num).toDouble(),
              unit: '${m['unit'] ?? 'INR/kg'}',
              updated: updated,
              changePercent: (m['changePercent'] as num?)?.toDouble() ?? 0,
            ),
          );
        }
      }
      final series = <MarketPriceSeries>[];
      if (seriesJson is List) {
        for (final e in seriesJson) {
          final m = e as Map<String, dynamic>;
          final pts = m['points'];
          if (pts is! List) continue;
          final spots = <MarketPriceSpot>[];
          for (final p in pts) {
            if (p is! Map<String, dynamic>) continue;
            spots.add(
              MarketPriceSpot(
                label: '${p['label'] ?? ''}',
                pricePerKg: (p['price'] as num?)?.toDouble() ?? 0,
              ),
            );
          }
          if (spots.isNotEmpty) {
            series.add(MarketPriceSeries(crop: '${m['crop']}', spots: spots));
          }
        }
      }
      if (rows.isEmpty) return _fallback(updated);
      if (series.isEmpty) {
        return MarketBoardResult(rows: rows, series: _syntheticSeries(rows), insightNote: insight);
      }
      return MarketBoardResult(rows: rows, series: series.take(4).toList(), insightNote: insight);
    } catch (_) {
      return _fallback(updated);
    }
  }

  List<MarketPriceSeries> _syntheticSeries(List<MarketRow> rows) {
    return rows.take(3).map((r) {
      final spots = <MarketPriceSpot>[];
      for (var i = 6; i >= 0; i--) {
        final wobble = 1 + (i - 3) * 0.012 * (r.changePercent >= 0 ? 1 : -1);
        spots.add(MarketPriceSpot(label: '-${i}d', pricePerKg: (r.pricePerKg * wobble).clamp(0.5, 99999)));
      }
      return MarketPriceSeries(crop: r.crop, spots: spots);
    }).toList();
  }

  MarketBoardResult _fallback(DateTime updated) {
    final rows = [
      MarketRow(crop: 'Tomato', pricePerKg: 48, unit: 'INR/kg', updated: updated, changePercent: 0.5),
      MarketRow(crop: 'Onion', pricePerKg: 32, unit: 'INR/kg', updated: updated, changePercent: -0.2),
    ];
    return MarketBoardResult(rows: rows, series: _syntheticSeries(rows), insightNote: null);
  }
}
