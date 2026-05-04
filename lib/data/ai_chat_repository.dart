import 'dart:typed_data';

/// Prior chat turns in order: user → model → user → model → … (excludes the latest user message passed as [userText]).
typedef AiChatPriorTurn = ({bool isUser, String text});

/// **Firebase:** HTTPS Callable `chatPlantAssistant` with model + user uid audit.
abstract class AiChatRepository {
  Future<String> sendMessage(
    String userText, {
    String? plantContext,
    List<AiChatPriorTurn>? priorTurns,
    Uint8List? imageBytes,
    String? imageMimeType,
  });
}

class LocalKeywordAiRepository implements AiChatRepository {
  @override
  Future<String> sendMessage(
    String userText, {
    String? plantContext,
    List<AiChatPriorTurn>? priorTurns,
    Uint8List? imageBytes,
    String? imageMimeType,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final t = userText.toLowerCase();
    if (t.contains('water')) {
      return 'For most vegetables, water deeply when the top 2–3 cm of soil dries. '
          'Morning or evening reduces leaf wetness overnight.${plantContext != null ? ' Context: $plantContext.' : ''}';
    }
    if (t.contains('fertil')) {
      return 'Start balanced, shift to lower nitrogen and higher potassium during flowering and fruiting.';
    }
    if (t.contains('pest')) {
      return 'Identify the pest stage first; combine physical removal, rotation, and approved sprays only if needed.';
    }
    if (imageBytes != null && imageBytes.isNotEmpty) {
      return 'Image received. This offline assistant cannot analyze photos — add a Gemini API key for vision, or describe what you see in text.';
    }
    return 'Thanks for your question. This offline assistant gives general guidance only. '
        'For field-specific advice, consult your local extension officer.';
  }
}
