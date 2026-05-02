import 'dart:convert';

import 'gemini_generative_service.dart';

/// Ideal manual watering window from Gemini (or safe defaults).
class SprinklerAiPlan {
  const SprinklerAiPlan({
    required this.idealSecondsMin,
    required this.idealSecondsMax,
    required this.targetMoisturePct,
    required this.rationale,
  });

  final int idealSecondsMin;
  final int idealSecondsMax;
  final int targetMoisturePct;
  final String rationale;

  int get idealSecondsMid => ((idealSecondsMin + idealSecondsMax) / 2).round().clamp(30, 600);

  static const SprinklerAiPlan fallback = SprinklerAiPlan(
    idealSecondsMin: 90,
    idealSecondsMax: 180,
    targetMoisturePct: 68,
    rationale: 'Default plan: water until soil moisture approaches the mid‑60s % range, then pause and let it infiltrate.',
  );

  static SprinklerAiPlan parseModelText(String raw) {
    var t = raw.trim();
    if (t.startsWith('```')) {
      final nl = t.indexOf('\n');
      if (nl != -1) t = t.substring(nl + 1);
      if (t.endsWith('```')) t = t.substring(0, t.length - 3);
    }
    t = t.trim();
    final decoded = jsonDecode(t);
    if (decoded is! Map) return fallback;
    final m = decoded.cast<String, dynamic>();
    int i(String k, int d) => (m[k] is num) ? (m[k] as num).round() : d;
    final minS = i('idealSecondsMin', fallback.idealSecondsMin).clamp(20, 900);
    var maxS = i('idealSecondsMax', fallback.idealSecondsMax).clamp(minS, 900);
    if (maxS < minS) maxS = minS + 30;
    final moist = i('targetMoisturePct', fallback.targetMoisturePct).clamp(40, 92);
    final rat = (m['rationale'] ?? fallback.rationale).toString().trim();
    return SprinklerAiPlan(
      idealSecondsMin: minS,
      idealSecondsMax: maxS,
      targetMoisturePct: moist,
      rationale: rat.isEmpty ? fallback.rationale : rat,
    );
  }

  static Future<SprinklerAiPlan> fetchFromGemini({
    required GeminiGenerativeService gemini,
    required String plantName,
    required String wateringLevel,
    required String climateHint,
  }) async {
    const sys = '''
You advise smallholder / balcony growers on manual sprinkler sessions.
Reply with ONLY valid JSON (no markdown fences) with keys:
"idealSecondsMin", "idealSecondsMax" (total seconds the valve should stay on for one gentle session),
"targetMoisturePct" (integer percent soil moisture to aim for before stopping),
"rationale" (one short sentence for the grower).
Use conservative ranges; avoid overwatering.
''';
    final user =
        'Crop: $plantName. Declared watering need: $wateringLevel. Climate/soil notes: ${climateHint.length > 400 ? climateHint.substring(0, 400) : climateHint}';
    final text = await gemini.generateText(systemInstruction: sys, userText: user);
    try {
      return parseModelText(text);
    } catch (_) {
      return fallback;
    }
  }
}
