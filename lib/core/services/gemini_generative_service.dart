import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../config/gemini_runtime_config.dart';

/// Thin wrapper around Gemini for text + image+text calls used by RAG-backed repositories.
class GeminiGenerativeService {
  GeminiGenerativeService({
    required String apiKey,
    String? model,
  })  : _modelId = model ?? GeminiRuntimeConfig.model,
        _apiKey = apiKey;

  final String _apiKey;
  final String _modelId;

  GenerativeModel _textModel(String systemInstruction) {
    return GenerativeModel(
      model: _modelId,
      apiKey: _apiKey,
      systemInstruction: Content.system(systemInstruction),
    );
  }

  /// Plain text generation (chat / market JSON / etc.).
  Future<String> generateText({
    required String systemInstruction,
    required String userText,
  }) async {
    final model = _textModel(systemInstruction);
    final res = await model.generateContent([Content.text(userText)]);
    return res.text?.trim() ?? '';
  }

  /// Multimodal: one image + text prompt. [mimeType] e.g. `image/jpeg` or `image/png`.
  Future<String> generateWithImage({
    required String systemInstruction,
    required String prompt,
    required Uint8List imageBytes,
    required String mimeType,
  }) async {
    final model = _textModel(systemInstruction);
    final res = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, imageBytes),
      ]),
    ]);
    return res.text?.trim() ?? '';
  }
}
