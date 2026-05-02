import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../domain/grow_session.dart';
import '../domain/plant.dart';

const _kBox = 'growsphere_box';
const _kSession = 'session_json';
const _kGardenList = 'garden_sessions_json_v1';
const _kActiveGardenInstanceId = 'active_garden_instance_id';
const _kSeenWelcome = 'has_seen_welcome';
const _kTheme = 'theme_mode';
const _kLocale = 'locale_code';
const _kSprinkler = 'sprinkler_on';
const _kSprinklerAt = 'sprinkler_at_iso';
const _kPushNotif = 'pref_push_notifications';
const _kWaterRemind = 'pref_watering_reminders';
const _kSmartSprinkler = 'pref_smart_sprinkler_control';
const _kCustomPlants = 'custom_plants_json';
const _kFarmPlanMonths = 'farm_plan_start_month_by_plant_json';
const _kSprinklerWaterStart = 'sprinkler_water_start_iso';
const _kSprinklerTargetSec = 'sprinkler_target_sec';
const _kInAppNotifications = 'in_app_notifications_json';
const _kSprinklerFromCalendar = 'sprinkler_pending_from_calendar';
const _kFieldTelemetrySnap = 'field_telemetry_snap_json';
const _kFieldTelemetryBaseline = 'field_telemetry_baseline_json';
const _kWateringDurMin = 'watering_duration_minutes';
const _kGrowArchives = 'grow_session_archives_json';

/// Local key-value store. Swap for Firestore sync layer later.
class GrowStorage {
  Box<dynamic>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_kBox);
  }

  Box<dynamic> get box {
    final b = _box;
    if (b == null) throw StateError('GrowStorage not initialized');
    return b;
  }

  String initialRoute() {
    if (box.get(_kSeenWelcome) != true) return '/welcome';
    return '/garden';
  }

  void _migrateLegacySingleSessionIfNeeded() {
    if (box.get(_kGardenList) != null) return;
    final raw = box.get(_kSession) as String?;
    if (raw == null || raw.isEmpty) return;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw) as Map<String, dynamic>);
      if (map['gardenInstanceId'] == null) {
        final pid = map['plantId'] as String? ?? 'plant';
        final started = map['startedAt'] as String? ?? DateTime.now().toIso8601String();
        map['gardenInstanceId'] = 'migrated_${pid}_$started';
      }
      box.put(_kGardenList, jsonEncode([map]));
      box.put(_kActiveGardenInstanceId, map['gardenInstanceId'] as String);
      box.delete(_kSession);
    } catch (_) {}
  }

  List<GrowSession> loadGardenListSync() {
    _migrateLegacySingleSessionIfNeeded();
    final raw = box.get(_kGardenList) as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => GrowSession.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveGardenList(List<GrowSession> sessions) async {
    await box.put(_kGardenList, jsonEncode(sessions.map((e) => e.toJson()).toList()));
  }

  String? get activeGardenInstanceId => box.get(_kActiveGardenInstanceId) as String?;

  Future<void> setActiveGardenInstanceId(String? id) async {
    if (id == null || id.isEmpty) {
      await box.delete(_kActiveGardenInstanceId);
    } else {
      await box.put(_kActiveGardenInstanceId, id);
    }
  }

  GrowSession? loadActiveSessionFromGarden() {
    final list = loadGardenListSync();
    if (list.isEmpty) return null;
    final id = activeGardenInstanceId;
    if (id != null) {
      for (final s in list) {
        if (s.gardenInstanceId == id) return s;
      }
    }
    return list.first;
  }

  Future<void> mergeSessionIntoGardenList(GrowSession session) async {
    final list = List<GrowSession>.from(loadGardenListSync());
    final i = list.indexWhere((e) => e.gardenInstanceId == session.gardenInstanceId);
    if (i >= 0) {
      list[i] = session;
    } else {
      list.add(session);
    }
    await saveGardenList(list);
  }

  GrowSession? loadSessionSync() => loadActiveSessionFromGarden();

  Future<void> saveSession(GrowSession? session) async {
    if (session == null) {
      await saveGardenList([]);
      await setActiveGardenInstanceId(null);
      await box.delete(_kSession);
    } else {
      await mergeSessionIntoGardenList(session);
      await setActiveGardenInstanceId(session.gardenInstanceId);
    }
  }

  bool get hasSeenWelcome => box.get(_kSeenWelcome) == true;

  Future<void> setHasSeenWelcome(bool v) => box.put(_kSeenWelcome, v);

  ThemeModePref get themeModePref {
    final s = box.get(_kTheme) as String? ?? 'system';
    return ThemeModePref.values.firstWhere(
      (e) => e.name == s,
      orElse: () => ThemeModePref.system,
    );
  }

  Future<void> setThemeModePref(ThemeModePref m) => box.put(_kTheme, m.name);

  String get localeCode => box.get(_kLocale) as String? ?? 'en';

  Future<void> setLocaleCode(String code) => box.put(_kLocale, code);

  bool get sprinklerOn => box.get(_kSprinkler) == true;

  /// When set, auto-stop valve after this many seconds of watering.
  int? get sprinklerTargetWateringSeconds {
    final v = box.get(_kSprinklerTargetSec);
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  Future<void> setSprinklerOn(bool on, {int? targetWateringSeconds}) async {
    await box.put(_kSprinkler, on);
    await box.put(_kSprinklerAt, DateTime.now().toIso8601String());
    if (on) {
      await box.put(_kSprinklerWaterStart, DateTime.now().toIso8601String());
      if (targetWateringSeconds != null && targetWateringSeconds > 0) {
        await box.put(_kSprinklerTargetSec, targetWateringSeconds);
      } else {
        await box.delete(_kSprinklerTargetSec);
      }
    } else {
      await box.delete(_kSprinklerWaterStart);
      await box.delete(_kSprinklerTargetSec);
    }
  }

  DateTime? get sprinklerWaterStartedAt {
    final s = box.get(_kSprinklerWaterStart) as String?;
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> loadInAppNotifications() {
    final raw = box.get(_kInAppNotifications) as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveInAppNotifications(List<Map<String, dynamic>> items) async {
    await box.put(_kInAppNotifications, jsonEncode(items));
  }

  Future<void> addInAppNotification({
    required String id,
    required String title,
    required String body,
    bool read = false,
  }) async {
    final list = loadInAppNotifications();
    list.insert(0, {
      'id': id,
      'title': title,
      'body': body,
      'at': DateTime.now().toIso8601String(),
      'read': read,
    });
    while (list.length > 80) {
      list.removeLast();
    }
    await saveInAppNotifications(list);
  }

  Future<void> markAllNotificationsRead() async {
    final list = loadInAppNotifications();
    for (final m in list) {
      m['read'] = true;
    }
    await saveInAppNotifications(list);
  }

  int unreadNotificationCount() {
    return loadInAppNotifications().where((m) => m['read'] != true).length;
  }

  bool get pendingSprinklerFromCalendar => box.get(_kSprinklerFromCalendar) == true;

  Future<void> setPendingSprinklerFromCalendar(bool v) async {
    if (v) {
      await box.put(_kSprinklerFromCalendar, true);
    } else {
      await box.delete(_kSprinklerFromCalendar);
    }
  }

  DateTime? get lastSprinklerAt {
    final s = box.get(_kSprinklerAt) as String?;
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  bool get pushNotificationsEnabled => box.get(_kPushNotif) != false;

  Future<void> setPushNotificationsEnabled(bool v) => box.put(_kPushNotif, v);

  bool get wateringRemindersEnabled => box.get(_kWaterRemind) != false;

  Future<void> setWateringRemindersEnabled(bool v) => box.put(_kWaterRemind, v);

  bool get smartSprinklerControlEnabled => (box.get(_kSmartSprinkler) as bool?) ?? true;

  Future<void> setSmartSprinklerControlEnabled(bool v) => box.put(_kSmartSprinkler, v);

  /// Last simulated field-node readings (from sprinkler live view).
  Future<void> setFieldTelemetrySnapshot({
    required double soilMoisturePct,
    required double canopyTempC,
    required double fieldHumidityPct,
    required int nodeBatteryPct,
  }) async {
    await box.put(
      _kFieldTelemetrySnap,
      jsonEncode({
        'soilMoisturePct': soilMoisturePct,
        'canopyTempC': canopyTempC,
        'fieldHumidityPct': fieldHumidityPct,
        'nodeBatteryPct': nodeBatteryPct,
        'at': DateTime.now().toIso8601String(),
      }),
    );
  }

  Map<String, dynamic>? getFieldTelemetrySnapshot() {
    final raw = box.get(_kFieldTelemetrySnap) as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? getFieldTelemetryBaseline() {
    final raw = box.get(_kFieldTelemetryBaseline) as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> setFieldTelemetryBaselineFromSnapshot() async {
    final s = getFieldTelemetrySnapshot();
    if (s == null) return;
    await box.put(_kFieldTelemetryBaseline, jsonEncode(s));
  }

  /// Manual watering slider (minutes, 0.5 step). Default 15.
  double get wateringDurationMinutes {
    final v = box.get(_kWateringDurMin);
    if (v is num) return v.toDouble().clamp(0.5, 30.0);
    return 15.0;
  }

  Future<void> setWateringDurationMinutes(double minutes) async {
    final snapped = ((minutes / 0.5).round() * 0.5).clamp(0.5, 30.0);
    await box.put(_kWateringDurMin, snapped);
  }

  List<Map<String, dynamic>> loadGrowArchives() {
    final raw = box.get(_kGrowArchives) as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendGrowArchive(Map<String, dynamic> sessionJson) async {
    final list = loadGrowArchives()
      ..insert(0, {...sessionJson, 'archivedAt': DateTime.now().toIso8601String()});
    while (list.length > 30) {
      list.removeLast();
    }
    await box.put(_kGrowArchives, jsonEncode(list));
  }

  Future<void> clearInAppNotifications() async {
    await box.delete(_kInAppNotifications);
  }

  Future<void> wipeAll() async {
    await box.clear();
  }

  /// User-added plants (Add Plant form). Merged with asset catalog at runtime.
  List<Plant> loadCustomPlants() {
    final raw = box.get(_kCustomPlants) as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => Plant.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveCustomPlants(List<Plant> plants) async {
    await box.put(_kCustomPlants, jsonEncode(plants.map((e) => e.toJson()).toList()));
  }

  Future<void> addCustomPlant(Plant p) async {
    final list = loadCustomPlants();
    list.add(p);
    await saveCustomPlants(list);
  }

  /// 1–12 = January–December; used for farm planning month labels on Calendar + plant detail.
  int? farmPlanStartMonthForPlant(String plantId) {
    final raw = box.get(_kFarmPlanMonths) as String?;
    if (raw == null || raw.isEmpty) return null;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final v = m[plantId];
      if (v is num) return v.toInt().clamp(1, 12);
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> setFarmPlanStartMonth(String plantId, int month1To12) async {
    final m = <String, dynamic>{};
    final raw = box.get(_kFarmPlanMonths) as String?;
    if (raw != null && raw.isNotEmpty) {
      try {
        m.addAll(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {}
    }
    m[plantId] = month1To12.clamp(1, 12);
    await box.put(_kFarmPlanMonths, jsonEncode(m));
  }
}

enum ThemeModePref { system, light, dark }
