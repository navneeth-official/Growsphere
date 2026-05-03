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
const _kSprinklerByGarden = 'sprinkler_by_garden_json_v2';
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
const _kUserJourneyBadges = 'user_journey_badges_json';
const _kProfileDisplayName = 'profile_display_name';
const _kProfilePhotoPath = 'profile_photo_path';
const _kProfileEmail = 'profile_email';
const _kProfilePhone = 'profile_phone';

/// Local key-value store. Swap for Firestore sync layer later.
class GrowStorage {
  Box<dynamic>? _box;

  Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox<dynamic>(_kBox);
    _migrateSprinklerV1ToPerGardenIfNeeded();
  }

  /// One-time: global sprinkler flags → per [gardenInstanceId] map.
  void _migrateSprinklerV1ToPerGardenIfNeeded() {
    if (box.get(_kSprinklerByGarden) != null) return;
    final legacyOn = box.get(_kSprinkler) == true;
    final legacyStart = box.get(_kSprinklerWaterStart);
    final legacyCal = box.get(_kSprinklerFromCalendar) == true;
    if (!legacyOn && legacyStart == null && !legacyCal) {
      box.put(_kSprinklerByGarden, jsonEncode(<String, dynamic>{}));
      return;
    }
    final list = loadGardenListSync();
    final gid = activeGardenInstanceId ?? (list.isNotEmpty ? list.first.gardenInstanceId : null);
    final m = <String, dynamic>{};
    if (gid != null && gid.isNotEmpty) {
      m[gid] = <String, dynamic>{
        'on': legacyOn,
        if (box.get(_kSprinklerAt) != null) 'at': box.get(_kSprinklerAt),
        if (legacyStart != null) 'waterStart': legacyStart,
        if (box.get(_kSprinklerTargetSec) != null) 'targetSec': box.get(_kSprinklerTargetSec),
        'calendar': legacyCal,
      };
    }
    box.put(_kSprinklerByGarden, jsonEncode(m));
    box.delete(_kSprinkler);
    box.delete(_kSprinklerAt);
    box.delete(_kSprinklerWaterStart);
    box.delete(_kSprinklerTargetSec);
    box.delete(_kSprinklerFromCalendar);
  }

  Map<String, dynamic> _sprinklerMapDecoded() {
    _migrateSprinklerV1ToPerGardenIfNeeded();
    final raw = box.get(_kSprinklerByGarden) as String?;
    if (raw == null || raw.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveSprinklerMap(Map<String, dynamic> m) async {
    await box.put(_kSprinklerByGarden, jsonEncode(m));
  }

  Map<String, dynamic> _entryForGarden(String gardenInstanceId) {
    final m = _sprinklerMapDecoded();
    final e = m[gardenInstanceId];
    if (e is Map) return Map<String, dynamic>.from(e);
    return {};
  }

  /// Per-crop valve + timer state (each [gardenInstanceId] has its own sprinkler session).
  bool sprinklerOnFor(String gardenInstanceId) {
    if (gardenInstanceId.isEmpty) return false;
    return _entryForGarden(gardenInstanceId)['on'] == true;
  }

  int? sprinklerTargetWateringSecondsFor(String gardenInstanceId) {
    if (gardenInstanceId.isEmpty) return null;
    final v = _entryForGarden(gardenInstanceId)['targetSec'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }

  DateTime? sprinklerWaterStartedAtFor(String gardenInstanceId) {
    if (gardenInstanceId.isEmpty) return null;
    final s = _entryForGarden(gardenInstanceId)['waterStart'] as String?;
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  bool pendingSprinklerFromCalendarFor(String gardenInstanceId) {
    if (gardenInstanceId.isEmpty) return false;
    return _entryForGarden(gardenInstanceId)['calendar'] == true;
  }

  Future<void> setPendingSprinklerFromCalendarFor(String gardenInstanceId, bool v) async {
    if (gardenInstanceId.isEmpty) return;
    final all = _sprinklerMapDecoded();
    final next = Map<String, dynamic>.from(all[gardenInstanceId] as Map? ?? {});
    if (v) {
      next['calendar'] = true;
    } else {
      next.remove('calendar');
    }
    all[gardenInstanceId] = next;
    await _saveSprinklerMap(all);
  }

  Future<void> setSprinklerOnFor(
    String gardenInstanceId,
    bool on, {
    int? targetWateringSeconds,
  }) async {
    if (gardenInstanceId.isEmpty) return;
    final all = _sprinklerMapDecoded();
    var next = Map<String, dynamic>.from(all[gardenInstanceId] as Map? ?? {});
    next['on'] = on;
    next['at'] = DateTime.now().toIso8601String();
    if (on) {
      next['waterStart'] = DateTime.now().toIso8601String();
      if (targetWateringSeconds != null && targetWateringSeconds > 0) {
        next['targetSec'] = targetWateringSeconds;
      } else {
        next.remove('targetSec');
      }
    } else {
      next.remove('waterStart');
      next.remove('targetSec');
    }
    all[gardenInstanceId] = next;
    await _saveSprinklerMap(all);
  }

  Future<void> clearSprinklerCalendarFlagFor(String gardenInstanceId) async {
    if (gardenInstanceId.isEmpty) return;
    final all = _sprinklerMapDecoded();
    final next = Map<String, dynamic>.from(all[gardenInstanceId] as Map? ?? {});
    next.remove('calendar');
    if (next.isEmpty) {
      all.remove(gardenInstanceId);
    } else {
      all[gardenInstanceId] = next;
    }
    await _saveSprinklerMap(all);
  }

  DateTime? lastSprinklerAtFor(String gardenInstanceId) {
    if (gardenInstanceId.isEmpty) return null;
    final s = _entryForGarden(gardenInstanceId)['at'] as String?;
    if (s == null) return null;
    try {
      return DateTime.parse(s);
    } catch (_) {
      return null;
    }
  }

  /// Legacy: active garden’s valve (for one-off reads). Prefer [sprinklerOnFor].
  bool get sprinklerOn => sprinklerOnFor(activeGardenInstanceId ?? '');

  /// Legacy: active garden (avoid for multi-crop flows).
  int? get sprinklerTargetWateringSeconds =>
      sprinklerTargetWateringSecondsFor(activeGardenInstanceId ?? '');

  Future<void> setSprinklerOn(bool on, {int? targetWateringSeconds}) async {
    final id = activeGardenInstanceId;
    if (id == null || id.isEmpty) return;
    await setSprinklerOnFor(id, on, targetWateringSeconds: targetWateringSeconds);
  }

  DateTime? get sprinklerWaterStartedAt =>
      sprinklerWaterStartedAtFor(activeGardenInstanceId ?? '');

  bool get pendingSprinklerFromCalendar =>
      pendingSprinklerFromCalendarFor(activeGardenInstanceId ?? '');

  Future<void> setPendingSprinklerFromCalendar(bool v) async {
    final id = activeGardenInstanceId;
    if (id == null || id.isEmpty) return;
    await setPendingSprinklerFromCalendarFor(id, v);
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

  DateTime? get lastSprinklerAt => lastSprinklerAtFor(activeGardenInstanceId ?? '');

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
    String? badgeId,
  }) async {
    final list = loadInAppNotifications();
    list.insert(0, {
      'id': id,
      'title': title,
      'body': body,
      'at': DateTime.now().toIso8601String(),
      'read': read,
      if (badgeId != null) 'badgeId': badgeId,
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

  // --- Profile & lifetime journey badges ---

  List<String> loadUserJourneyBadgeIds() {
    final raw = box.get(_kUserJourneyBadges) as String?;
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }

  /// Grants journey badges from [plant] id; returns newly added ids (persisted).
  Future<List<String>> tryGrantJourneyBadgesFromPlant(Plant plant) async {
    final list = List<String>.from(loadUserJourneyBadgeIds());
    final added = <String>[];
    void grant(String id) {
      if (!list.contains(id)) {
        list.add(id);
        added.add(id);
      }
    }

    if (plant.id.startsWith('tool_micro_')) {
      grant('badge_first_microgreens');
    }
    if (plant.id.startsWith('tool_cover_')) {
      grant('badge_first_soil_recovery');
    }
    if (!plant.id.startsWith('tool_')) {
      grant('badge_first_crop');
    }

    if (added.isNotEmpty) {
      await box.put(_kUserJourneyBadges, jsonEncode(list));
    }
    return added;
  }

  String? get profileDisplayName {
    final s = box.get(_kProfileDisplayName) as String?;
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  Future<void> setProfileDisplayName(String? name) async {
    if (name == null || name.trim().isEmpty) {
      await box.delete(_kProfileDisplayName);
    } else {
      await box.put(_kProfileDisplayName, name.trim());
    }
  }

  String? get profilePhotoPath {
    final s = box.get(_kProfilePhotoPath) as String?;
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  Future<void> setProfilePhotoPath(String? path) async {
    if (path == null || path.trim().isEmpty) {
      await box.delete(_kProfilePhotoPath);
    } else {
      await box.put(_kProfilePhotoPath, path.trim());
    }
  }

  String? get profileEmail {
    final s = box.get(_kProfileEmail) as String?;
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  Future<void> setProfileEmail(String? email) async {
    if (email == null || email.trim().isEmpty) {
      await box.delete(_kProfileEmail);
    } else {
      await box.put(_kProfileEmail, email.trim());
    }
  }

  String? get profilePhone {
    final s = box.get(_kProfilePhone) as String?;
    if (s == null || s.trim().isEmpty) return null;
    return s.trim();
  }

  Future<void> setProfilePhone(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      await box.delete(_kProfilePhone);
    } else {
      await box.put(_kProfilePhone, phone.trim());
    }
  }
}

enum ThemeModePref { system, light, dark }
