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

  /// Multi-turn chat: [history] is complete prior turns (user, model, user, model, …); [message] is the new user turn.
  Future<String> generateChatReply({
    required String systemInstruction,
    required List<Content> history,
    required String message,
  }) async {
    final model = _textModel(systemInstruction);
    final chat = model.startChat(history: history);
    final res = await chat.sendMessage(Content.text(message));
    return res.text?.trim() ?? '';
  }

  /// Multi-turn chat; latest user turn may include an image.
  Future<String> generateChatReplyMultimodal({
    required String systemInstruction,
    required List<Content> history,
    required String message,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final model = _textModel(systemInstruction);
    final chat = model.startChat(history: history);
    final Content userContent;
    if (imageBytes != null && imageBytes.isNotEmpty && imageMimeType != null && imageMimeType.isNotEmpty) {
      userContent = Content.multi([
        TextPart(message),
        DataPart(imageMimeType, imageBytes),
      ]);
    } else {
      userContent = Content.text(message);
    }
    final res = await chat.sendMessage(userContent);
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
