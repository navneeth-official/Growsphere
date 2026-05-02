import 'grow_storage.dart';

/// **Firebase / IoT:** call HTTPS or write `devices/{deviceId}/sprinkler` in RTDB.
abstract class SprinklerRepository {
  Future<void> setOn(bool on, {int? targetWateringSeconds});
  bool get isOn;
  DateTime? get lastCommandAt;
}

class LocalSprinklerRepository implements SprinklerRepository {
  LocalSprinklerRepository(this._storage);

  final GrowStorage _storage;

  @override
  bool get isOn => _storage.sprinklerOn;

  @override
  DateTime? get lastCommandAt => _storage.lastSprinklerAt;

  @override
  Future<void> setOn(bool on, {int? targetWateringSeconds}) async {
    await _storage.setSprinklerOn(on, targetWateringSeconds: targetWateringSeconds);
  }
}
