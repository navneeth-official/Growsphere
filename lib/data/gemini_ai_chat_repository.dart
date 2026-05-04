import 'dart:typed_data';

import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/services/gemini_generative_service.dart';
import '../core/services/plant_rag_context_service.dart';
import 'ai_chat_repository.dart';

/// Gemini + in-app RAG for open-ended farming Q&A.
class GeminiAiChatRepository implements AiChatRepository {
  GeminiAiChatRepository({
    required GeminiGenerativeService gemini,
    required PlantRagContextService rag,
  })  : _gemini = gemini,
        _rag = rag;

  final GeminiGenerativeService _gemini;
  final PlantRagContextService _rag;

  static const _system = '''
You are GrowSphere AI Farming Assistant, helping home and small-plot growers.

Rules:
- Each new user turn includes an RAG_CONTEXT block: treat matching crops and the active session as authoritative app data when relevant.
- You may add general agronomy where RAG is silent; label speculation clearly.
- Be helpful and structured. No medical claims; for pesticides and legal doses, tell the user to follow local labels and a certified agronomist.
- If live market or exchange data is required, say figures are indicative and suggest checking local mandi or official apps.

Formatting (critical — answers render in a plain chat bubble):
- Do not use Markdown: no asterisks for bold, no # headings, no backticks, no blockquotes, no --- dividers.
- Use short section titles in Title Case followed by a colon on their own line, or numbered steps 1. 2. 3., and blank lines between sections so the reply is easy to scan on a phone.
''';

  @override
  Future<String> sendMessage(
    String userText, {
    String? plantContext,
    List<AiChatPriorTurn>? priorTurns,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    final prior = priorTurns ?? const [];
    final rag = await _rag.buildContextBlock();
    final extra = plantContext != null && plantContext.isNotEmpty
        ? '\nUSER_GROW_HINT: $plantContext\n'
        : '';
    final body = '''
RAG_CONTEXT:
$rag
$extra
USER_QUESTION:
$userText
''';

    final history = <Content>[];
    for (final turn in prior) {
      if (turn.isUser) {
        history.add(Content.text(turn.text));
      } else {
        history.add(Content.model([TextPart(turn.text)]));
      }
    }

    final bytes = imageBytes;
    final mime = imageMimeType;
    final hasImage = bytes != null && bytes.isNotEmpty && mime != null && mime.isNotEmpty;

    final String out;
    if (prior.isEmpty && !hasImage) {
      out = await _gemini.generateText(systemInstruction: _system, userText: body);
    } else if (prior.isEmpty && hasImage) {
      out = await _gemini.generateWithImage(
        systemInstruction: _system,
        prompt: body,
        imageBytes: bytes!,
        mimeType: mime!,
      );
    } else if (hasImage) {
      out = await _gemini.generateChatReplyMultimodal(
        systemInstruction: _system,
        history: history,
        message: body,
        imageBytes: bytes,
        imageMimeType: mime,
      );
    } else {
      out = await _gemini.generateChatReply(systemInstruction: _system, history: history, message: body);
    }

    final cleaned = _stripStrayMarkdown(out.isEmpty ? 'No response from model. Check API key and model id.' : out);
    return cleaned;
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
