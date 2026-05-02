import '../../data/grow_storage.dart';
import 'notification_service.dart';

/// Human-readable labels for simulated field-node channels.
abstract final class FieldTelemetryLabels {
  static const soilMoisture = 'Soil probe moisture';
  static const canopyTemp = 'Canopy air temperature';
  static const fieldHumidity = 'Field relative humidity';
  static const nodeBattery = 'Node battery';
}

/// Compares last telemetry snapshot to baseline; notifies on significant drift.
class SensorNotificationCoordinator {
  SensorNotificationCoordinator._();

  static Future<void> compareAndNotify({
    required GrowStorage storage,
    required NotificationService notifications,
    required void Function() bumpInAppRevision,
  }) async {
    final snap = storage.getFieldTelemetrySnapshot();
    if (snap == null) return;

    double g(String k) => (snap[k] is num) ? (snap[k] as num).toDouble() : 0;
    final m = g('soilMoisturePct');
    final t = g('canopyTempC');
    final h = g('fieldHumidityPct');
    final b = (snap['nodeBatteryPct'] as num?)?.toInt() ?? 0;

    final base = storage.getFieldTelemetryBaseline();
    if (base == null) {
      await storage.setFieldTelemetryBaselineFromSnapshot();
      return;
    }

    double gb(String k) => (base[k] is num) ? (base[k] as num).toDouble() : 0;
    final m0 = gb('soilMoisturePct');
    final t0 = gb('canopyTempC');
    final h0 = gb('fieldHumidityPct');
    final b0 = (base['nodeBatteryPct'] as num?)?.toInt() ?? 0;

    final lines = <String>[];
    if ((m - m0).abs() >= 8) {
      lines.add('${FieldTelemetryLabels.soilMoisture} shifted ${m >= m0 ? '+' : ''}${(m - m0).toStringAsFixed(1)}% (now ${m.toStringAsFixed(1)}%).');
    }
    if ((t - t0).abs() >= 2.0) {
      lines.add('${FieldTelemetryLabels.canopyTemp} moved ${(t - t0).toStringAsFixed(1)}°C (now ${t.toStringAsFixed(1)}°C).');
    }
    if ((h - h0).abs() >= 10) {
      lines.add('${FieldTelemetryLabels.fieldHumidity} moved ${(h - h0).toStringAsFixed(1)}% (now ${h.toStringAsFixed(1)}%).');
    }
    if ((b - b0).abs() >= 5) {
      lines.add('${FieldTelemetryLabels.nodeBattery} changed by ${b - b0}% (now $b%).');
    }

    if (lines.isEmpty) return;

    final body = lines.join(' ');
    await notifications.showFieldNodeAlert(
      title: 'Field node readings changed',
      body: body,
    );
    await storage.addInAppNotification(
      id: 'tel_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Field node readings changed',
      body: body,
    );
    bumpInAppRevision();
    await storage.setFieldTelemetryBaselineFromSnapshot();
  }
}
