import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/grow_storage.dart';
import '../core/services/notification_service.dart';
import '../core/services/sprinkler_ai_advice_service.dart';
import '../core/services/sensor_notification_coordinator.dart';
import 'base_providers.dart';
import 'session_controller.dart';

enum SprinklerTimingQuality { idle, watering, idealWindow, warnStop, over }

class SprinklerLiveState {
  const SprinklerLiveState({
    required this.moisture,
    required this.temperature,
    required this.humidity,
    required this.batteryPct,
    required this.secondsWatering,
    required this.quality,
    required this.hintLine,
    required this.valveOpen,
  });

  final double moisture;
  final double temperature;
  final double humidity;
  final int batteryPct;
  final int secondsWatering;
  final SprinklerTimingQuality quality;
  final String hintLine;
  final bool valveOpen;

  factory SprinklerLiveState.seed(GrowStorage storage) {
    final on = storage.sprinklerOn;
    final started = storage.sprinklerWaterStartedAt;
    final sec = on && started != null ? DateTime.now().difference(started).inSeconds : 0;
    return SprinklerLiveState(
      moisture: 44.5 + Random().nextDouble() * 0.4,
      temperature: 23.4 + Random().nextDouble() * 0.35,
      humidity: 66.8 + Random().nextDouble() * 0.5,
      batteryPct: 85 + Random().nextInt(4),
      secondsWatering: sec,
      quality: on ? SprinklerTimingQuality.watering : SprinklerTimingQuality.idle,
      hintLine: on ? 'Live sensors updating…' : 'Live preview — values drift slightly like a real probe.',
      valveOpen: on,
    );
  }

  SprinklerLiveState evolve({
    required SprinklerAiPlan plan,
    required bool valveOn,
    required DateTime? waterStart,
  }) {
    final rnd = Random();
    final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
    var m = moisture + sin(t * 1.73) * 0.14 + (rnd.nextDouble() - 0.5) * 0.09;
    var temp = temperature + sin(t * 0.88) * 0.07 + (rnd.nextDouble() - 0.5) * 0.045;
    var hum = humidity + sin(t * 1.09) * 0.16 + (rnd.nextDouble() - 0.5) * 0.11;
    var bat = batteryPct.toDouble() + (rnd.nextDouble() - 0.5) * 0.15;
    var sec = 0;
    if (valveOn && waterStart != null) {
      sec = DateTime.now().difference(waterStart).inSeconds;
      m += 0.38;
      temp -= 0.055;
      hum += 0.11;
      bat -= 0.02;
    }
    m = m.clamp(12.0, 99.0);
    temp = temp.clamp(16.0, 40.0);
    hum = hum.clamp(28.0, 99.0);
    bat = bat.clamp(12.0, 100.0);
    final batPct = bat.round();

    final target = plan.targetMoisturePct.toDouble();
    SprinklerTimingQuality q;
    String hint;
    if (!valveOn) {
      q = SprinklerTimingQuality.idle;
      hint = 'Valve idle — tap Start watering when you are ready.';
    } else if (m > 91 || sec > plan.idealSecondsMax * 2.25) {
      q = SprinklerTimingQuality.over;
      hint = 'Overwatering risk — soil is saturated. Stop watering now.';
    } else if (m >= target - 1.5 && sec >= plan.idealSecondsMin * 0.45) {
      q = SprinklerTimingQuality.idealWindow;
      hint = 'Perfect timing window — moisture nears your crop target. You can stop soon.';
    } else if (sec >= plan.idealSecondsMax) {
      q = SprinklerTimingQuality.warnStop;
      hint = 'AI session length reached — check moisture before continuing.';
    } else {
      q = SprinklerTimingQuality.watering;
      hint = 'Watering… sensors show active irrigation.';
    }

    return SprinklerLiveState(
      moisture: m,
      temperature: temp,
      humidity: hum,
      batteryPct: batPct,
      secondsWatering: sec,
      quality: q,
      hintLine: hint,
      valveOpen: valveOn,
    );
  }
}

class SprinklerLiveNotifier extends AutoDisposeNotifier<SprinklerLiveState> {
  Timer? _timer;
  SprinklerAiPlan _plan = SprinklerAiPlan.fallback;
  bool _overAlertSent = false;
  bool _autoDurationStopSent = false;
  int _lastSnapWriteMs = 0;
  int _lastCompareMs = 0;

  void setAiPlan(SprinklerAiPlan plan) {
    _plan = plan;
  }

  @override
  SprinklerLiveState build() {
    final storage = ref.read(growStorageProvider);
    ref.onDispose(() => _timer?.cancel());
    _timer ??= Timer.periodic(const Duration(milliseconds: 700), (_) => _tick());
    return SprinklerLiveState.seed(storage);
  }

  void _tick() {
    final storage = ref.read(growStorageProvider);
    if (!storage.sprinklerOn) {
      _overAlertSent = false;
      _autoDurationStopSent = false;
    }
    final next = state.evolve(
      plan: _plan,
      valveOn: storage.sprinklerOn,
      waterStart: storage.sprinklerWaterStartedAt,
    );
    state = next;
    final targetSec = storage.sprinklerTargetWateringSeconds;
    if (storage.sprinklerOn &&
        targetSec != null &&
        next.secondsWatering >= targetSec &&
        !_autoDurationStopSent) {
      _autoDurationStopSent = true;
      unawaited(_autoStopAtTarget(storage, next));
    }
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    if (nowMs - _lastSnapWriteMs > 45000) {
      _lastSnapWriteMs = nowMs;
      unawaited(
        storage.setFieldTelemetrySnapshot(
          soilMoisturePct: next.moisture,
          canopyTempC: next.temperature,
          fieldHumidityPct: next.humidity,
          nodeBatteryPct: next.batteryPct,
        ),
      );
    }
    if (nowMs - _lastCompareMs > 90000) {
      _lastCompareMs = nowMs;
      unawaited(
        SensorNotificationCoordinator.compareAndNotify(
          storage: storage,
          notifications: ref.read(notificationServiceProvider),
          bumpInAppRevision: () => ref.read(inAppNotificationsRevisionProvider.notifier).state++,
        ),
      );
    }
    if (storage.sprinklerOn &&
        next.quality == SprinklerTimingQuality.over &&
        !_overAlertSent) {
      _overAlertSent = true;
      final body = next.hintLine;
      unawaited(_fireOverwaterAlerts(body));
    }
  }

  Future<void> _fireOverwaterAlerts(String body) async {
    final n = ref.read(notificationServiceProvider);
    final s = ref.read(growStorageProvider);
    await n.showOverwaterAlert(body);
    await s.addInAppNotification(
      id: 'over_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Overwatering alert',
      body: body,
    );
    ref.read(inAppNotificationsRevisionProvider.notifier).state++;
  }

  Future<void> _autoStopAtTarget(GrowStorage storage, SprinklerLiveState live) async {
    await storage.setSprinklerOn(false);
    final plan = _plan;
    final over = live.quality == SprinklerTimingQuality.over;
    await ref.read(sessionControllerProvider.notifier).finishSprinklerSession(
          overwatered: over,
          secondsWatered: live.secondsWatering,
          idealSecondsMid: plan.idealSecondsMid,
          logCareFromCalendar: storage.pendingSprinklerFromCalendar,
        );
    await storage.setPendingSprinklerFromCalendar(false);
  }
}

final sprinklerLiveProvider =
    AutoDisposeNotifierProvider<SprinklerLiveNotifier, SprinklerLiveState>(SprinklerLiveNotifier.new);

final inAppNotificationsRevisionProvider = StateProvider<int>((ref) => 0);
