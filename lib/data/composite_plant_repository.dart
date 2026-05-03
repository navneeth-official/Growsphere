import '../domain/plant.dart';
import 'grow_storage.dart';
import 'plant_image_overrides.dart';
import 'plant_repository.dart';

/// Asset catalog plus user-added plants from [GrowStorage].
class CompositePlantRepository implements PlantRepository {
  CompositePlantRepository(this._storage);

  final GrowStorage _storage;
  final AssetPlantRepository _asset = AssetPlantRepository();

  @override
  Future<List<Plant>> loadAll() async {
    final asset = await _asset.loadAll();
    final custom = _storage.loadCustomPlants();
    return [...asset.map(plantWithStableImage), ...custom];
  }

  @override
  Future<Plant?> byId(String id) async {
    final custom = _storage.loadCustomPlants();
    for (final p in custom) {
      if (p.id == id) return p;
    }
    final a = await _asset.byId(id);
    return a == null ? null : plantWithStableImage(a);
  }
}
