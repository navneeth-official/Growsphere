import 'dart:convert';
import 'dart:typed_data';

import '../core/services/gemini_generative_service.dart';
import '../core/services/plant_rag_context_service.dart';
import '../domain/pest_guide_catalog.dart';
import 'ai_tool_ids.dart';
import 'disease_analysis_repository.dart';
import 'grow_storage.dart';

/// Multimodal Gemini analysis for plant health, pests, or species ID.
class GeminiDiseaseAnalysisRepository implements DiseaseAnalysisRepository {
  GeminiDiseaseAnalysisRepository({
    required GeminiGenerativeService gemini,
    required PlantRagContextService rag,
    required GrowStorage storage,
  })  : _gemini = gemini,
        _rag = rag,
        _storage = storage;

  final GeminiGenerativeService _gemini;
  final PlantRagContextService _rag;
  final GrowStorage _storage;

  static const _jsonKeys = '''
Output only valid JSON (no markdown fences) with keys:
- label: short title for the finding
- severity: short phrase (confidence or urgency, not medical)
- summary: 1–2 sentences overview
- findings: what is visible in the image (plant parts, symptoms, pests, damage patterns, possible nutrient clues)
- recommendations: practical steps (IPM, cultural controls, when to sample soil or call an expert); if pesticides mentioned, remind user to follow local label and agronomist advice
- safetyNote: one sentence (e.g. do not eat unidentified plants, lab confirmation for regulated pests)
All string values must be plain text: no markdown asterisks, no # headings, no backticks.
''';

  @override
  Future<DiseaseReport> analyzeImageBytes(
    List<int> bytes, {
    String? plantName,
    ImageAnalysisIntent intent = ImageAnalysisIntent.plantHealthAndDisease,
  }) async {
    final rag = await _rag.buildVisionAssistBlock();
    final mem = _storage.buildAiToolContextBlock(AiToolIds.diseaseVision);
    final memBlock = mem.isNotEmpty ? 'PRIOR_TOOL_MEMORY:\n$mem\n\n' : '';
    final u = Uint8List.fromList(bytes);
    final mime = _mimeFromBytes(u);

    final (String system, String prompt) = switch (intent) {
      ImageAnalysisIntent.plantHealthAndDisease => (
          '''You are an agricultural vision assistant for GrowSphere.
Analyze the photograph on its own merits. The user may be growing something completely different in the app — ignore app session.
$_jsonKeys''',
          '''$memBlockREFERENCE_CATALOG (optional, do not assume the photo matches any crop listed):
$rag

Task: From the image only — identify the plant or crop if reasonably possible, assess health, likely diseases or abiotic stress, signs of nutrient deficiency, and pest-related damage. Be conservative where the image is unclear.
JSON only:''',
        ),
      ImageAnalysisIntent.pestIdentification => (
          '''You are an expert integrated pest management (IPM) assistant for GrowSphere.
Identify likely pests, life stages, and damage from the image alone. Never invent insects or symptoms not supported by visible evidence.
If uncertain, say so in summary and keep recommendations general (monitoring, sanitation, expert ID).
${PestGuideEntry.referenceBlockForAi()}
$_jsonKeys''',
          '''$memBlockREFERENCE_CATALOG (optional pest notes for common crops — use only if consistent with visible evidence):
$rag

Task: Map findings to one of the guide pests when justified; otherwise use a neutral label like "Unconfirmed pest damage".
Explain visible cues only, then IPM steps (non-chemical first). Chemical: defer to local labels.
JSON only:''',
        ),
      ImageAnalysisIntent.plantSpeciesIdentification => (
          '''You are a botany-aware crop assistant.
Identify species, cultivar group, or closest alternatives from the image. If the image is not a plant, say so clearly.
$_jsonKeys''',
          '''$memBlockREFERENCE_CATALOG (optional common names — image wins over catalog):
$rag

Task: Species / common name identification, confidence, and brief cultivation or look-alike disclaimer.
JSON only:''',
        ),
    };

    final raw = await _gemini.generateWithImage(
      systemInstruction: system,
      prompt: prompt,
      imageBytes: u,
      mimeType: mime,
    );
    final report = _parseDiseaseJson(raw);
    final pn = plantName?.trim() ?? '';
    final userLine = 'Vision ${intent.name}${pn.isNotEmpty ? ' ($pn)' : ''}';
    final replyLine = '${report.label}: ${report.advice}';
    await _storage.recordAiToolExchange(
      AiToolIds.diseaseVision,
      userLine,
      replyLine.length > 1200 ? '${replyLine.substring(0, 1200)}…' : replyLine,
    );
    return report;
  }

  static String _mimeFromBytes(Uint8List b) {
    if (b.length >= 2 && b[0] == 0xff && b[1] == 0xd8) return 'image/jpeg';
    if (b.length >= 8 && b[0] == 0x89 && b[1] == 0x50 && b[2] == 0x4e && b[3] == 0x47) return 'image/png';
    if (b.length >= 6 && b[0] == 0x47 && b[1] == 0x49 && b[2] == 0x46) return 'image/gif';
    return 'image/jpeg';
  }

  DiseaseReport _parseDiseaseJson(String raw) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start >= 0 && end > start) {
        final j = jsonDecode(raw.substring(start, end + 1)) as Map<String, dynamic>;
        final label = '${j['label'] ?? 'Result'}';
        final severity = '${j['severity'] ?? 'n/a'}';
        final summary = '${j['summary'] ?? ''}'.trim();
        final findings = '${j['findings'] ?? ''}'.trim();
        final rec = '${j['recommendations'] ?? ''}'.trim();
        final safe = '${j['safetyNote'] ?? ''}'.trim();
        final buf = StringBuffer();
        if (summary.isNotEmpty) buf.writeln(summary);
        if (findings.isNotEmpty) {
          if (buf.isNotEmpty) buf.writeln();
          buf.writeln('What we see');
          buf.writeln(findings);
        }
        if (rec.isNotEmpty) {
          buf.writeln();
          buf.writeln('Recommendations');
          buf.writeln(rec);
        }
        if (safe.isNotEmpty) {
          buf.writeln();
          buf.writeln(safe);
        }
        var advice = buf.toString().trim();
        if (advice.isEmpty) advice = '${j['advice'] ?? raw}';
        advice = _stripStrayMarkdown(advice);
        return DiseaseReport(
          label: _stripStrayMarkdown(label),
          severity: _stripStrayMarkdown(severity),
          advice: advice,
        );
      }
    } catch (_) {}
    return DiseaseReport(
      label: 'Model response',
      severity: 'n/a',
      advice: _stripStrayMarkdown(raw.isEmpty ? 'No response text from model.' : raw),
    );
  }

  static String _stripStrayMarkdown(String s) {
    var t = s;
    t = t.replaceAllMapped(RegExp(r'\*\*([^*]+)\*\*'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r'(?<!\*)\*([^*]+)\*(?!\*)'), (m) => m[1]!);
    t = t.replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => m[1]!);
    t = t.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');
    t = t.replaceAll('**', '');
    return t.trim();
  }
}
