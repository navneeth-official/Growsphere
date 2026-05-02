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
You are **GrowSphere AI Farming Assistant**, helping home and small-plot growers.

Rules:
- Each user message begins with an `RAG_CONTEXT` section: treat matching crops and the active session as **authoritative app data**.
- You may add **general agronomy** where RAG is silent, and clearly separate speculation from facts.
- Be concise (short paragraphs or bullets). No medical claims; pesticides/legal doses → tell user to follow local labels and consult a certified agronomist.
- If the question needs live market/exchange data you do not have, say estimates may differ and suggest checking local mandi/apps.
''';

  @override
  Future<String> sendMessage(String userText, {String? plantContext}) async {
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
    final out = await _gemini.generateText(
      systemInstruction: _system,
      userText: body,
    );
    return out.isEmpty ? 'No response from model. Check API key and model id.' : out;
  }
}
