import 'package:flutter/material.dart';
import 'package:growspehere_v1/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_theme.dart';
import '../data/grow_storage.dart';
import '../providers/base_providers.dart';
import 'app_router.dart';
import 'app_resume_scope.dart';
import '../widgets/watering_haptic_listener.dart';

class GrowsphereApp extends ConsumerWidget {
  const GrowsphereApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(uiTickProvider);
    final storage = ref.watch(growStorageProvider);
    final themeMode = switch (storage.themeModePref) {
      ThemeModePref.light => ThemeMode.light,
      ThemeModePref.dark => ThemeMode.dark,
      ThemeModePref.system => ThemeMode.system,
    };
    final router = ref.watch(goRouterProvider);
    return AppResumeScope(
      child: MaterialApp.router(
        debugShowCheckedModeBanner: false,
        onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        locale: Locale(storage.localeCode),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
        builder: (context, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              if (child != null) child,
              const WateringHapticListener(),
            ],
          );
        },
      ),
    );
  }
}
