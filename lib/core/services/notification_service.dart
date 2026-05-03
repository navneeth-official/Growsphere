import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/grow_session.dart';
import '../../domain/grow_task.dart';

/// Local reminders at 07:00 and 17:00. Replace with FCM topics when Firebase is added.
///
/// Android 13+: POST_NOTIFICATIONS runtime permission required (requested from UI).
/// iOS: request permissions on first schedule.
class NotificationService {
  final _plugin = FlutterLocalNotificationsPlugin();
  static const _channelId = 'growsphere_water';
  static const _morningId = 701;
  static const _eveningId = 1701;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
    const android = AndroidInitializationSettings('@drawable/ic_brand_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  Future<bool> requestPermissionsIfNeeded() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final r = await _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return r ?? false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidImpl = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final granted = await androidImpl?.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  Future<void> scheduleWaterReminders() async {
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_eveningId);

    final android = AndroidNotificationDetails(
      _channelId,
      'Watering',
      channelDescription: 'Daily plant watering reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);

    final loc = tz.local;
    var next7 = _nextInstanceOf(7, 0, loc);
    var next17 = _nextInstanceOf(17, 0, loc);

    await _plugin.zonedSchedule(
      _morningId,
      'Growsphere',
      'Good morning — check if your plants need water.',
      next7,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _plugin.zonedSchedule(
      _eveningId,
      'Growsphere',
      'Evening care — a quick water check keeps streaks alive.',
      next17,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelWaterReminders() async {
    await _plugin.cancel(_morningId);
    await _plugin.cancel(_eveningId);
  }

  static const _farmTasksId = 8801;
  static const _channelFarm = 'growsphere_farm';
  static const _channelAlerts = 'growsphere_alerts';

  Future<void> cancelFarmTasksDigest() async {
    await _plugin.cancel(_farmTasksId);
  }

  /// Daily 09:00 local digest (body should be short; reschedule when session/tasks change).
  Future<void> scheduleFarmTasksDigest(String body) async {
    await _plugin.cancel(_farmTasksId);
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;

    final android = AndroidNotificationDetails(
      _channelFarm,
      'Farm calendar',
      channelDescription: 'Today\'s grow tasks from your active crop',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);
    final loc = tz.local;
    final next9 = _nextInstanceOf(9, 0, loc);

    await _plugin.zonedSchedule(
      _farmTasksId,
      'Growsphere — today on the farm',
      trimmed.length > 180 ? '${trimmed.substring(0, 177)}…' : trimmed,
      next9,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// High-priority local alert (works when app is in background on supported devices).
  Future<void> showOverwaterAlert(String body) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(2000000000);
    final android = AndroidNotificationDetails(
      _channelAlerts,
      'Smart farm alerts',
      channelDescription: 'Sprinkler and soil warnings',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      'Sprinkler — overwatering risk',
      body,
      NotificationDetails(android: android, iOS: ios),
    );
  }

  Future<void> showFieldNodeAlert({required String title, required String body}) async {
    final id = DateTime.now().millisecondsSinceEpoch.remainder(2000000000);
    final android = AndroidNotificationDetails(
      _channelAlerts,
      'Field node',
      channelDescription: 'Soil probe, canopy, humidity, and power alerts',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    await _plugin.show(
      id,
      title,
      body,
      NotificationDetails(android: android, iOS: ios),
    );
  }

  static const _taskDeadlineBaseId = 15200;
  static const _taskDeadlineCount = 48;
  static const _sensorSlot1 = 9101;
  static const _sensorSlot2 = 9102;
  static const _sensorSlot3 = 9103;
  static const _eodIncompleteId = 9200;

  Future<void> cancelTaskDeadlineReminders() async {
    for (var i = 0; i < _taskDeadlineCount; i++) {
      await _plugin.cancel(_taskDeadlineBaseId + i);
    }
  }

  Future<void> cancelSensorReadingReminders() async {
    await _plugin.cancel(_sensorSlot1);
    await _plugin.cancel(_sensorSlot2);
    await _plugin.cancel(_sensorSlot3);
  }

  Future<void> cancelEodIncompleteReminder() async {
    await _plugin.cancel(_eodIncompleteId);
  }

  /// One-shot reminders for incomplete tasks (next few due dates at [GrowTask.dueHour]).
  Future<void> rescheduleTaskDeadlineReminders({
    required String plantName,
    required List<GrowTask> tasks,
  }) async {
    await cancelTaskDeadlineReminders();
    final loc = tz.local;
    final nowLocal = tz.TZDateTime.now(loc);
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final android = AndroidNotificationDetails(
      _channelFarm,
      'Farm calendar',
      channelDescription: 'Task deadline reminders',
      importance: Importance.high,
      priority: Priority.high,
    );
    const ios = DarwinNotificationDetails(presentAlert: true, presentSound: true, presentBadge: true);
    final details = NotificationDetails(android: android, iOS: ios);

    var idx = 0;
    final sorted = tasks.where((e) => !e.completed).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    for (final t in sorted) {
      if (idx >= _taskDeadlineCount) break;
      final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      if (d.isBefore(today)) continue;
      var at = tz.TZDateTime(loc, d.year, d.month, d.day, t.dueHour.clamp(0, 23), 0);
      if (!at.isAfter(nowLocal)) continue;
      await _plugin.zonedSchedule(
        _taskDeadlineBaseId + idx,
        'Growsphere — $plantName',
        'Due now: ${t.title}',
        at,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
      idx++;
    }
  }

  /// Nudge to open the app and sync simulated field-node readings (local schedule).
  Future<void> scheduleSensorReadingReminders() async {
    await cancelSensorReadingReminders();
    final loc = tz.local;
    final android = AndroidNotificationDetails(
      _channelAlerts,
      'Field node',
      channelDescription: 'Periodic field sensor check-ins',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);
    const body =
        'Open Growsphere to review soil probe moisture, canopy temperature, field humidity, and node battery.';

    Future<void> slot(int id, int hour) => _plugin.zonedSchedule(
          id,
          'Field node check-in',
          body,
          _nextInstanceOf(hour, 0, loc),
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );

    await slot(_sensorSlot1, 10);
    await slot(_sensorSlot2, 14);
    await slot(_sensorSlot3, 18);
  }

  /// Daily reminder if any grow tasks may still be open (user should confirm in app).
  Future<void> scheduleEodIncompleteReminder() async {
    await cancelEodIncompleteReminder();
    final loc = tz.local;
    final android = AndroidNotificationDetails(
      _channelFarm,
      'Farm calendar',
      channelDescription: 'End-of-day task sweep',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails();
    final details = NotificationDetails(android: android, iOS: ios);
    await _plugin.zonedSchedule(
      _eodIncompleteId,
      'Growsphere — farm tasks',
      'Wrap up: check today\'s tasks and field node readings in Growsphere.',
      _nextInstanceOf(20, 0, loc),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static const _nudgeBaseId = 15400;
  static const _nudgeCount = 20;

  Future<void> cancelPendingTaskNudges() async {
    for (var i = 0; i < _nudgeCount; i++) {
      await _plugin.cancel(_nudgeBaseId + i);
    }
  }

  /// Friendly rotating reminders for today's open tasks (~12-14 min apart, capped).
  Future<void> reschedulePendingTaskNudges({
    required String plantName,
    required List<GrowTask> tasks,
    required int currentStreak,
    required int bestStreak,
  }) async {
    await cancelPendingTaskNudges();
    final loc = tz.local;
    final nowLocal = tz.TZDateTime.now(loc);
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    final pending = tasks.where((t) {
      if (t.completed) return false;
      final d = DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day);
      return d == today;
    }).toList();
    if (pending.isEmpty) return;

    final android = AndroidNotificationDetails(
      _channelFarm,
      'Farm calendar',
      channelDescription: 'Task nudges during the day',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails(presentAlert: true, presentSound: false);
    final details = NotificationDetails(android: android, iOS: ios);

    final tips = <String>[
      if (currentStreak > 0)
        'Streak: $currentStreak day(s). Badges unlock at 3, 7, 14, and 30 perfect days in a row.',
      if (bestStreak > currentStreak) 'Best on this crop: $bestStreak — beat your record.',
      'Complete today\'s care to keep soil probe and canopy readings aligned.',
    ];

    for (var i = 0; i < _nudgeCount; i++) {
      final at = nowLocal.add(Duration(minutes: 10 + i * 13));
      if (at.hour >= 21) break;
      if (!at.isAfter(nowLocal)) continue;
      final t = pending[i % pending.length];
      final tip = tips[i % tips.length];
      await _plugin.zonedSchedule(
        _nudgeBaseId + i,
        'Growsphere — $plantName · still to do',
        '${t.title}\n$tip',
        at,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
  }

  static const _schedGrowBaseId = 16100;
  static const _schedGrowMaxSlots = 520;

  /// Clears one-shot “countdown to planned farming start” notifications.
  Future<void> cancelScheduledGrowReminders() async {
    for (var i = 0; i < _schedGrowMaxSlots; i++) {
      await _plugin.cancel(_schedGrowBaseId + i);
    }
  }

  /// Daily 09:00 reminders until each scheduled grow’s [GrowSession.effectiveFarmingStart].
  Future<void> rescheduleScheduledGrowReminders(List<GrowSession> garden) async {
    await cancelScheduledGrowReminders();
    final loc = tz.local;
    final nowLocal = tz.TZDateTime.now(loc);
    final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);

    final android = AndroidNotificationDetails(
      _channelFarm,
      'Scheduled grows',
      channelDescription: 'Reminders before your planned farming start date',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const ios = DarwinNotificationDetails(presentAlert: true, presentSound: false);
    final details = NotificationDetails(android: android, iOS: ios);

    var slot = 0;
    for (final s in garden) {
      if (!s.farmingLockedOn(DateTime.now())) continue;
      final start = s.effectiveFarmingStart;
      final daysTotal = start.difference(today).inDays;
      if (daysTotal <= 0) continue;

      for (var d = 0; d <= daysTotal && d < 60; d++) {
        if (slot >= _schedGrowMaxSlots) return;
        final day = today.add(Duration(days: d));
        var at = tz.TZDateTime(loc, day.year, day.month, day.day, 9, 0);
        if (!at.isAfter(nowLocal)) continue;
        final daysLeft = start.difference(day).inDays;
        final body = daysLeft <= 0
            ? '${s.plantName}: farming starts today — open Growsphere to unlock tasks.'
            : '${s.plantName}: farming starts in $daysLeft day(s).';
        await _plugin.zonedSchedule(
          _schedGrowBaseId + slot,
          'Growsphere — upcoming grow',
          body,
          at,
          details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
        slot++;
      }
    }
  }

  tz.TZDateTime _nextInstanceOf(int hour, int minute, tz.Location location) {
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
