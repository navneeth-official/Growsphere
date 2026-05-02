import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/sprinkler_ai_advice_service.dart';
import '../domain/grow_session.dart';
import 'base_providers.dart';
import 'session_controller.dart';
import 'sprinkler_live_provider.dart';

export 'base_providers.dart';
export 'sprinkler_live_provider.dart';

final sessionControllerProvider = NotifierProvider<SessionController, GrowSession?>(SessionController.new);

final sprinklerAiPlanProvider = FutureProvider.autoDispose<SprinklerAiPlan>((ref) async {
  final session = ref.watch(sessionControllerProvider);
  final g = ref.watch(geminiGenerativeServiceProvider);
  if (session == null) return SprinklerAiPlan.fallback;
  if (g == null) return SprinklerAiPlan.fallback;
  return SprinklerAiPlan.fetchFromGemini(
    gemini: g,
    plantName: session.plantName,
    wateringLevel: session.wateringLevel,
    climateHint: '${session.climate} ${session.soil}',
  );
});
