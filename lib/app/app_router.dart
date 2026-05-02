import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/add_crop/add_crop_screen.dart';
import '../features/ai_chat/ai_chat_screen.dart';
import '../features/disease/disease_screen.dart';
import '../features/environment/environment_screen.dart';
import '../features/home/home_screen.dart';
import '../features/market/market_screen.dart';
import '../features/pest/pest_screen.dart';
import '../features/plant/plant_detail_screen.dart';
import '../features/plant/plant_pick_screen.dart';
import '../features/research/plant_research_center_screen.dart';
import '../features/research/research_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/soil/soil_recovery_screen.dart';
import '../features/notifications/notifications_screen.dart';
import '../features/sprinkler/sprinkler_screen.dart';
import '../features/streaks/streaks_screen.dart';
import '../features/tools/tools_hub_screen.dart';
import '../features/weather/weather_screen.dart';
import '../features/welcome/welcome_screen.dart';
import '../providers/providers.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.read(routeRefreshProvider);
  final storage = ref.read(growStorageProvider);
  final initial = storage.initialRoute();
  return GoRouter(
    initialLocation: initial,
    refreshListenable: refresh,
    redirect: (context, state) {
      try {
        final container = ProviderScope.containerOf(context);
        final session = container.read(sessionControllerProvider);
        final path = state.matchedLocation;
        if (path == '/home' && session == null) return '/plants';
      } catch (_) {}
      return null;
    },
    routes: [
      GoRoute(path: '/welcome', builder: (_, __) => const WelcomeScreen()),
      GoRoute(path: '/plants', builder: (_, __) => const PlantPickScreen()),
      GoRoute(path: '/tools', builder: (_, __) => const ToolsHubScreen()),
      GoRoute(path: '/add-crop', builder: (_, __) => const AddCropScreen()),
      GoRoute(
        path: '/research',
        builder: (_, __) => const ResearchScreen(),
        routes: [
          GoRoute(
            path: 'center',
            builder: (_, __) => const PlantResearchCenterScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/plant/:id',
        builder: (_, s) => PlantDetailScreen(plantId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/environment/:id',
        builder: (_, s) => EnvironmentScreen(plantId: s.pathParameters['id']!),
      ),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/pest', builder: (_, __) => const PestScreen()),
      GoRoute(path: '/market', builder: (_, __) => const MarketScreen()),
      GoRoute(path: '/chat', builder: (_, __) => const AiChatScreen()),
      GoRoute(path: '/disease', builder: (_, __) => const DiseaseScreen()),
      GoRoute(path: '/soil', builder: (_, __) => const SoilRecoveryScreen()),
      GoRoute(
        path: '/sprinkler',
        builder: (_, s) => SprinklerScreen(
          autoWater: s.uri.queryParameters['autoWater'] == '1',
        ),
      ),
      GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/weather', builder: (_, __) => const WeatherScreen()),
      GoRoute(path: '/streaks', builder: (_, __) => const StreaksScreen()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    ],
  );
});
