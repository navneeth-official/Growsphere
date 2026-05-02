import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

/// Look up localized strings via [AppLocalizations.of].
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = locale;

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
  ];

  String get appTitle;
  String get startGrowing;
  String get welcomeTagline;
  String get whichPlant;
  String get searchPlantsHint;
  String get difficulty;
  String get watering;
  String get continueLabel;
  String get climate;
  String get soil;
  String get fertilizers;
  String get environmentTitle;
  String get locationLabel;
  String get sunlightLabel;
  String get indoor;
  String get balcony;
  String get terrace;
  String get sunLow;
  String get sunMedium;
  String get sunHigh;
  String get wateringRecommendation;
  String get iWatered;
  String get perfectTiming;
  String get overwateringRisk;
  String get missedCare;
  String get suboptimalTiming;
  String get plantHealth;
  String get streak;
  String get activityCalendar;
  String get tasks;
  String get settings;
  String get darkMode;
  String get language;
  String get clearAllData;
  String get clearAllConfirm;
  String get cancel;
  String get pestControl;
  String get marketPrices;
  String get aiChat;
  String get diseasePhoto;
  String get soilRecovery;
  String get sprinkler;
  String get weather;
  String get streaksBadges;
  String get home;
  String get growsphereTitle;
  String get learnMore;
  String get addNewPlant;
  String get defaultBadge;
  String get customBadge;
  String get tabPlants;
  String get tabCalendar;
  String get tabTools;
  String get tabAddPlant;
  String get tabResearch;
  String get backToTools;
  String get addPlantComingSoon;
  String get openPlantCatalog;

  String get tabMyGarden;
  String get myGardenTitle;
  String get myGardenLocationHint;
  String get myGardenEmpty;
  String get addToGarden;
  String get gardenSetupTitle;
  String get gardenYourPlants;
  String gardenPlantsCount(int count);
  String get plantTipHeader;
  String get wateringAdjustmentHeader;
  String get gardenAiTipLoading;
  String get gardenWeatherUnavailable;
  String get gardenWeatherLoadError;
  String get gardenHumidityShort;
  String get gardenRainChanceShort;
  String get recoPrefix;
  String get farmMonthLabel;
  String locationSunLine(String location, String sun);

  String get sprinklerControlTitle;
  String get toolsScreenTitle;
  String get openTool;
  String get appearance;
  String get appearanceDarkSubtitle;
  String get notifications;
  String get pushNotifications;
  String get pushNotificationsSubtitle;
  String get wateringReminders;
  String get wateringRemindersSubtitle;
  String get sprinklerSystem;
  String get smartControl;
  String get smartControlSubtitle;
  String get appInformation;
  String get versionLabel;
  String get lastUpdatedLabel;
  String get storageUsedLabel;
  String get plantManagement;
  String get restoreDefaultPlants;
  String get restoreDefaultPlantsDetail;
  String get dangerZone;
  String get clearAllDataFooter;
  String get addNewCropTitle;
  String get googleResearch;
  String get basicInformation;
  String get plantNameLabel;
  String get growthPeriodMonthsLabel;
  String get plantImageLabel;
  String get growingRequirements;
  String get researchTipsTitle;
  String get researchTipsBody;
  String get plantResearchCenter;
  String get googlePlantResearch;
  String get searchPlantInfoHint;
  String get searchPlantInfoFooter;
  String get quickResearchTopics;
  String get soilMoisture;
  String get temperature;
  String get humidity;
  String get battery;
  String get online;
  String get connectedSprinkler;
  String get manualControl;
  String get sprinklerStatus;
  String get readyToWater;
  String get startWatering;
  String get duration;
  String get minutes15;
  String get smartWatering;
  String get autoMode;
  String get autoModeSubtitle;
  String get autoSettings;
  String get statusMedium;
  String get normal;
  String get good;
  String get aiChatAssistantTitle;
  String get aiChatAssistantDesc;
  String get plantPhotoDetectionTitle;
  String get plantPhotoDetectionDesc;
  String get soilAnalysisTitle;
  String get soilAnalysisDesc;
  String get pestControlGuideTitle;
  String get pestControlGuideDesc;
  String get climateRequirementsTitle;
  String get soilRequirementsTitle;
  String get fertilizerNeedsTitle;
  String get whenPlanFarmTitle;
  String get farmStartMonthHint;
  String get createActivityCalendar;
  String get farmPlanningSectionTitle;
  String get soilGuidanceTitle;
  String get soilGuidanceDesc;
  String get microgreensGuideTitle;
  String get microgreensGuideDesc;

  String streaksIncreasedNTimes(int n);
  String growthPeriodMonths(int months);
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
  }
  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale".',
  );
}
