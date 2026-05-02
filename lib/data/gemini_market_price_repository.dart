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
You output **only JSON** (no markdown fences): a JSON array of objects.
Each object: {"crop": string, "pricePerKg": number, "unit": "INR/kg", "changePercent": number}
Use 3–8 major Indian retail/wholesale style crops (e.g. Tomato, Onion, Potato, Rice, Wheat).
changePercent is a plausible daily-ish % move (can be negative). Prices are rough **indicative** INR/kg.
''';

  @override
  Future<List<MarketRow>> latestRows() async {
    final rag = await _rag.buildContextBlock();
    final now = DateTime.now();
    final prompt = '''
RAG_CONTEXT (catalog typicalPricePerKg hints — use as weak priors only, may be stale):
$rag

Return JSON array only for crops relevant to this catalog and Indian context. Timestamp context: ${now.toIso8601String()}.
''';
    final raw = await _gemini.generateText(systemInstruction: _system, userText: prompt);
    return _parseRows(raw, now);
  }

  List<MarketRow> _parseRows(String raw, DateTime updated) {
    try {
      final start = raw.indexOf('[');
      final end = raw.lastIndexOf(']');
      if (start < 0 || end <= start) {
        return _fallback(updated);
      }
      final list = jsonDecode(raw.substring(start, end + 1)) as List<dynamic>;
      return list.map((e) {
        final m = e as Map<String, dynamic>;
        return MarketRow(
          crop: '${m['crop']}',
          pricePerKg: (m['pricePerKg'] as num).toDouble(),
          unit: '${m['unit'] ?? 'INR/kg'}',
          updated: updated,
          changePercent: (m['changePercent'] as num?)?.toDouble() ?? 0,
        );
      }).toList();
    } catch (_) {
      return _fallback(updated);
    }
  }

  List<MarketRow> _fallback(DateTime updated) => [
        MarketRow(crop: 'Tomato', pricePerKg: 48, unit: 'INR/kg', updated: updated, changePercent: 0.5),
        MarketRow(crop: 'Onion', pricePerKg: 32, unit: 'INR/kg', updated: updated, changePercent: -0.2),
      ];
}
