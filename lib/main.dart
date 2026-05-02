import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/growsphere_app.dart';
import 'core/services/notification_service.dart';
import 'data/grow_storage.dart';
import 'providers/base_providers.dart';

/// Local notifications: Android 13+ needs POST_NOTIFICATIONS; iOS needs user grant.
/// Exact alarms on Android 12+ may require SCHEDULE_EXACT_ALARM for precise 7am/5pm.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = GrowStorage();
  await storage.init();
  final notifications = NotificationService();
  await notifications.init();
  runApp(
    ProviderScope(
      overrides: [
        growStorageProvider.overrideWithValue(storage),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const GrowsphereApp(),
    ),
  );
}
