import 'grow_storage.dart';

/// **Firebase / IoT:** call HTTPS or write `devices/{deviceId}/sprinkler` in RTDB.
abstract class SprinklerRepository {
  Future<void> setOn(String gardenInstanceId, bool on, {int? targetWateringSeconds});

  bool isOnFor(String gardenInstanceId);

  DateTime? lastCommandAtFor(String gardenInstanceId);
}

class LocalSprinklerRepository implements SprinklerRepository {
  LocalSprinklerRepository(this._storage);

  final GrowStorage _storage;

  @override
  bool isOnFor(String gardenInstanceId) => _storage.sprinklerOnFor(gardenInstanceId);

  @override
  DateTime? lastCommandAtFor(String gardenInstanceId) => _storage.lastSprinklerAtFor(gardenInstanceId);

  @override
  Future<void> setOn(String gardenInstanceId, bool on, {int? targetWateringSeconds}) async {
    await _storage.setSprinklerOnFor(gardenInstanceId, on, targetWateringSeconds: targetWateringSeconds);
  }
}
