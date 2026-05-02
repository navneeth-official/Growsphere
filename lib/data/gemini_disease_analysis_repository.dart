import 'dart:convert';
import 'dart:typed_data';

import '../core/services/gemini_generative_service.dart';
import '../core/services/plant_rag_context_service.dart';
import 'disease_analysis_repository.dart';

/// Multimodal Gemini analysis for plant health, pests, or species ID.
class GeminiDiseaseAnalysisRepository implements DiseaseAnalysisRepository {
  GeminiDiseaseAnalysisRepository({
    required GeminiGenerativeService gemini,
    required PlantRagContextService rag,
  })  : _gemini = gemini,
        _rag = rag;

  final GeminiGenerativeService _gemini;
  final PlantRagContextService _rag;

  @override
  Future<DiseaseReport> analyzeImageBytes(
    List<int> bytes, {
    String? plantName,
    ImageAnalysisIntent intent = ImageAnalysisIntent.plantHealthAndDisease,
  }) async {
    final rag = await _rag.buildContextBlock();
    final u = Uint8List.fromList(bytes);
    final mime = _mimeFromBytes(u);

    final (String system, String prompt) = switch (intent) {
      ImageAnalysisIntent.plantHealthAndDisease => (
          '''You are an agricultural image assistant for GrowSphere.
Use the RAG block for crop-specific hints. Describe visible issues conservatively.
Output **only** valid JSON with keys: label (short title), severity (short string), advice (2–5 sentences).''',
          '''RAG_CONTEXT:
$rag

${plantName != null ? 'User says they are growing: $plantName\n' : ''}
Task: Assess plant health and any likely diseases or abiotic stress from the image.
JSON only:''',
        ),
      ImageAnalysisIntent.pestIdentification => (
          '''You are a pest identification assistant. Output **only** valid JSON: label, severity, advice.
If uncertain, say so in advice.''',
          '''RAG_CONTEXT (crop pest notes may help):
$rag

${plantName != null ? 'Crop context: $plantName\n' : ''}
Task: Identify likely pests or damage signatures from the image.
JSON only:''',
        ),
      ImageAnalysisIntent.plantSpeciesIdentification => (
          '''You are a plant identification assistant. Output **only** valid JSON: label (best species/common name guess), severity (confidence short phrase), advice (care + disclaimer).''',
          '''RAG_CONTEXT:
$rag

Task: Identify plant species or closest candidates from the image.
JSON only:''',
        ),
    };

    final raw = await _gemini.generateWithImage(
      systemInstruction: system,
      prompt: prompt,
      imageBytes: u,
      mimeType: mime,
    );
    return _parseDiseaseJson(raw);
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
        return DiseaseReport(
          label: '${j['label'] ?? 'Result'}',
          severity: '${j['severity'] ?? 'n/a'}',
          advice: '${j['advice'] ?? raw}',
        );
      }
    } catch (_) {}
    return DiseaseReport(
      label: 'Model response',
      severity: 'n/a',
      advice: raw.isEmpty ? 'No response text from model.' : raw,
    );
  }
}
