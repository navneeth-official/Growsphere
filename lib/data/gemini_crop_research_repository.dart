import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../core/services/gemini_generative_service.dart';
import 'ai_tool_ids.dart';
import 'grow_storage.dart';

/// Draft growing-requirements text from crop research.
class GrowingRequirementsDraft {
  const GrowingRequirementsDraft({
    required this.climate,
    required this.soil,
    required this.fertilizer,
  });

  final String climate;
  final String soil;
  final String fertilizer;
}

/// Gemini-backed suggestions for add-crop "Google Research" flow.
class GeminiCropResearchRepository {
  GeminiCropResearchRepository({
    required GeminiGenerativeService gemini,
    required GrowStorage storage,
  })  : _gemini = gemini,
        _storage = storage;

  final GeminiGenerativeService _gemini;
  final GrowStorage _storage;

  static const _jsonSystem = '''
You are an expert agronomist for smallholder and home growers.
Respond with ONLY a single JSON object (no markdown fences) with exactly these string keys:
"climate", "soil", "fertilizer".
Each value must be 2–5 sentences of practical, region-aware guidance (temperature, rainfall/humidity, drainage, organic matter, NPK timing, safety).
If the image is unclear, infer conservatively from the plant name and growth period.
''';

  Future<GrowingRequirementsDraft> suggestFromBasics({
    required String plantName,
    required int growthMonths,
    required Uint8List? imageBytes,
    required String? imageMimeType,
    String? imageUrlHint,
  }) async {
    final user = StringBuffer()
      ..writeln('Plant name: $plantName')
      ..writeln('Typical growth period: $growthMonths months (vegetative to harvest window).')
      ..writeln('Fill climate, soil, and fertilizer JSON values for this crop.');
    if (imageUrlHint != null && imageUrlHint.isNotEmpty) {
      user.writeln('User image reference: $imageUrlHint');
    }

    final mem = _storage.buildAiToolContextBlock(AiToolIds.cropResearch);
    final body = StringBuffer();
    if (mem.isNotEmpty) {
      body.writeln('PRIOR_TOOL_MEMORY (same tool, stay consistent when relevant):');
      body.writeln(mem);
      body.writeln();
    }
    body.write(user.toString());

    final raw = imageBytes != null && imageBytes.isNotEmpty && imageMimeType != null && imageMimeType.isNotEmpty
        ? await _gemini.generateWithImage(
            systemInstruction: _jsonSystem,
            prompt: body.toString(),
            imageBytes: imageBytes,
            mimeType: imageMimeType,
          )
        : await _gemini.generateText(
            systemInstruction: _jsonSystem,
            userText: '${body.toString()}\n(No usable image bytes — rely on plant name and duration.)',
          );

    final draft = _parseDraft(raw);
    await _storage.recordAiToolExchange(
      AiToolIds.cropResearch,
      'Basics: $plantName, ${growthMonths}mo',
      'climate/soil/fertilizer JSON draft (${raw.length} chars)',
    );
    return draft;
  }

  Future<String> enhanceField({
    required String fieldKey,
    required String currentText,
    required String plantName,
    required int growthMonths,
  }) async {
    final label = switch (fieldKey) {
      'climate' => 'climate requirements',
      'soil' => 'soil requirements',
      'fertilizer' => 'fertilizer needs',
      _ => fieldKey,
    };
    final sys = '''
You improve one section of a grow plan. Output plain text only (no JSON, no bullets unless essential).
Field: $label
Plant: $plantName, growth window ~$growthMonths months.
Rewrite or enrich the following draft to be clearer and more actionable; keep similar length (2–5 sentences).
''';
    final mem = _storage.buildAiToolContextBlock(AiToolIds.cropResearch);
    final userBlock = StringBuffer();
    if (mem.isNotEmpty) {
      userBlock.writeln('PRIOR_TOOL_MEMORY:');
      userBlock.writeln(mem);
      userBlock.writeln();
    }
    userBlock.write('Current draft:\n$currentText');
    final out = await _gemini.generateText(
      systemInstruction: sys,
      userText: userBlock.toString(),
    );
    final trimmed = out.trim();
    await _storage.recordAiToolExchange(
      AiToolIds.cropResearch,
      'Enhance $fieldKey for $plantName',
      trimmed.length > 1500 ? '${trimmed.substring(0, 1500)}…' : trimmed,
    );
    return trimmed;
  }

  GrowingRequirementsDraft _parseDraft(String raw) {
    final cleaned = _stripCodeFence(raw);
    final decoded = jsonDecode(cleaned);
    if (decoded is! Map) {
      throw const FormatException('Expected JSON object from crop research');
    }
    final m = decoded.cast<String, dynamic>();
    String s(String k) => (m[k] ?? '').toString().trim();
    final climate = s('climate');
    final soil = s('soil');
    final fert = s('fertilizer');
    if (climate.isEmpty && soil.isEmpty && fert.isEmpty) {
      throw const FormatException('Empty growing requirements from model');
    }
    return GrowingRequirementsDraft(
      climate: climate.isEmpty ? 'Add climate notes manually.' : climate,
      soil: soil.isEmpty ? 'Add soil notes manually.' : soil,
      fertilizer: fert.isEmpty ? 'Add fertilizer notes manually.' : fert,
    );
  }

  static String _stripCodeFence(String s) {
    var t = s.trim();
    if (t.startsWith('```')) {
      final firstNl = t.indexOf('\n');
      if (firstNl != -1) t = t.substring(firstNl + 1);
      final fence = t.lastIndexOf('```');
      if (fence != -1) t = t.substring(0, fence);
    }
    return t.trim();
  }
}

/// Load image bytes from `http(s)://` URL or return null on failure.
Future<Uint8List?> tryLoadImageFromUrl(String url) async {
  final u = url.trim();
  if (!u.startsWith('http://') && !u.startsWith('https://')) return null;
  try {
    final res = await http.get(Uri.parse(u));
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    return Uint8List.fromList(res.bodyBytes);
  } catch (_) {
    return null;
  }
}

String mimeTypeForPathOrUrl(String spec) {
  final lower = spec.toLowerCase().trim();
  if (lower.endsWith('.png')) return 'image/png';
  if (lower.endsWith('.webp')) return 'image/webp';
  if (lower.endsWith('.gif')) return 'image/gif';
  if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
  return 'image/jpeg';
}
