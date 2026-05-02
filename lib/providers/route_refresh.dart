import 'package:flutter/foundation.dart';

/// Notifies [GoRouter] to re-run redirects when local session changes.
class RouteRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}
