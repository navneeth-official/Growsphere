import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/gemini_runtime_config.dart';
import '../core/services/gemini_generative_service.dart';
import '../core/services/notification_service.dart';
import '../core/services/plant_rag_context_service.dart';
import '../data/ai_chat_repository.dart';
import '../data/disease_analysis_repository.dart';
import '../data/composite_plant_repository.dart';
import '../data/gemini_ai_chat_repository.dart';
import '../data/gemini_crop_research_repository.dart';
import '../data/gemini_disease_analysis_repository.dart';
import '../data/gemini_farm_plan_repository.dart';
import '../data/gemini_market_price_repository.dart';
import '../data/grow_storage.dart';
import '../data/market_price_repository.dart';
import '../data/plant_repository.dart';
import '../data/reverse_geocode_service.dart';
import '../data/sprinkler_repository.dart';
import '../data/weather_repository.dart';
import 'route_refresh.dart';

final growStorageProvider = Provider<GrowStorage>((ref) {
  throw UnimplementedError('growStorageProvider must be overridden in ProviderScope');
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError();
});

final plantRepositoryProvider = Provider<PlantRepository>((ref) {
  return CompositePlantRepository(ref.watch(growStorageProvider));
});

/// Increment to refresh plant catalog + farm plan UIs after local storage writes.
final localDataRevisionProvider = StateProvider<int>((ref) => 0);

/// Null when `GEMINI_API_KEY` is not passed via `--dart-define`.
final geminiGenerativeServiceProvider = Provider<GeminiGenerativeService?>((ref) {
  if (!GeminiRuntimeConfig.isConfigured) return null;
  return GeminiGenerativeService(
    apiKey: GeminiRuntimeConfig.apiKey,
    model: GeminiRuntimeConfig.model,
  );
});

/// Same API key; uses [GeminiRuntimeConfig.effectiveResearchModel] for add-crop research only.
final geminiCropResearchServiceProvider = Provider<GeminiGenerativeService?>((ref) {
  if (!GeminiRuntimeConfig.isConfigured) return null;
  return GeminiGenerativeService(
    apiKey: GeminiRuntimeConfig.apiKey,
    model: GeminiRuntimeConfig.effectiveResearchModel,
  );
});

final geminiCropResearchRepositoryProvider = Provider<GeminiCropResearchRepository?>((ref) {
  final g = ref.watch(geminiCropResearchServiceProvider);
  if (g == null) return null;
  return GeminiCropResearchRepository(gemini: g);
});

final geminiFarmPlanRepositoryProvider = Provider<GeminiFarmPlanRepository?>((ref) {
  final g = ref.watch(geminiGenerativeServiceProvider);
  if (g == null) return null;
  return GeminiFarmPlanRepository(gemini: g);
});

final plantRagContextServiceProvider = Provider<PlantRagContextService>((ref) {
  return PlantRagContextService(
    plantRepository: ref.watch(plantRepositoryProvider),
    growStorage: ref.watch(growStorageProvider),
  );
});

final marketRepositoryProvider = Provider<MarketPriceRepository>((ref) {
  final g = ref.watch(geminiGenerativeServiceProvider);
  final rag = ref.watch(plantRagContextServiceProvider);
  if (g != null) {
    return GeminiMarketPriceRepository(gemini: g, rag: rag);
  }
  return MockMarketPriceRepository();
});

final aiChatRepositoryProvider = Provider<AiChatRepository>((ref) {
  final g = ref.watch(geminiGenerativeServiceProvider);
  final rag = ref.watch(plantRagContextServiceProvider);
  if (g != null) {
    return GeminiAiChatRepository(gemini: g, rag: rag);
  }
  return LocalKeywordAiRepository();
});

final diseaseRepositoryProvider = Provider<DiseaseAnalysisRepository>((ref) {
  final g = ref.watch(geminiGenerativeServiceProvider);
  final rag = ref.watch(plantRagContextServiceProvider);
  if (g != null) {
    return GeminiDiseaseAnalysisRepository(gemini: g, rag: rag);
  }
  return StubDiseaseAnalysisRepository();
});

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) => WeatherRepository());

final reverseGeocodeServiceProvider = Provider<ReverseGeocodeService>((ref) => ReverseGeocodeService());

final sprinklerRepositoryProvider = Provider<SprinklerRepository>((ref) {
  final s = ref.watch(growStorageProvider);
  return LocalSprinklerRepository(s, () {
    ref.read(localDataRevisionProvider.notifier).state++;
  });
});

final routeRefreshProvider = ChangeNotifierProvider<RouteRefreshNotifier>((ref) => RouteRefreshNotifier());

/// Bumped after settings/theme/locale mutations to rebuild [MaterialApp].
final uiTickProvider = StateProvider<int>((ref) => 0);
