/// **Firebase:** HTTPS Callable `chatPlantAssistant` with model + user uid audit.
abstract class AiChatRepository {
  Future<String> sendMessage(String userText, {String? plantContext});
}

class LocalKeywordAiRepository implements AiChatRepository {
  @override
  Future<String> sendMessage(String userText, {String? plantContext}) async {
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
    return 'Thanks for your question. This offline assistant gives general guidance only. '
        'For field-specific advice, consult your local extension officer.';
  }
}
