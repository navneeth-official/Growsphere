import 'package:flutter/material.dart';

/// Root navigator for dialogs/overlays from non-widget code (e.g. Riverpod notifiers).
final GlobalKey<NavigatorState> growNavigatorKey = GlobalKey<NavigatorState>();
