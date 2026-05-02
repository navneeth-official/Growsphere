import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/sensor_notification_coordinator.dart';
import '../providers/providers.dart';

/// Runs sensor delta checks when the app returns to foreground.
class AppResumeScope extends ConsumerStatefulWidget {
  const AppResumeScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppResumeScope> createState() => _AppResumeScopeState();
}

class _AppResumeScopeState extends ConsumerState<AppResumeScope> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final storage = ref.read(growStorageProvider);
      final n = ref.read(notificationServiceProvider);
      SensorNotificationCoordinator.compareAndNotify(
        storage: storage,
        notifications: n,
        bumpInAppRevision: () => ref.read(inAppNotificationsRevisionProvider.notifier).state++,
      );
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
