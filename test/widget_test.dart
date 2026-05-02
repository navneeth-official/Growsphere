import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:growspehere_v1/app/growsphere_app.dart';
import 'package:growspehere_v1/core/services/notification_service.dart';
import 'package:growspehere_v1/data/grow_storage.dart';
import 'package:growspehere_v1/providers/base_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Growsphere app loads', (WidgetTester tester) async {
    final storage = GrowStorage();
    await storage.init();
    await storage.wipeAll();
    final notifications = NotificationService();
    await notifications.init();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          growStorageProvider.overrideWithValue(storage),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const GrowsphereApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(GrowsphereApp), findsOneWidget);
  });
}
