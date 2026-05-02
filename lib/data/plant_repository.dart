import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/plant.dart';

/// Local asset-backed catalog.
///
/// **Firebase:** replace with `FirebasePlantRepository` reading `plants` collection
/// and optional Algolia/Typesense for search.
abstract class PlantRepository {
  Future<List<Plant>> loadAll();
  Future<Plant?> byId(String id);
}

class AssetPlantRepository implements PlantRepository {
  List<Plant>? _cache;

  @override
  Future<List<Plant>> loadAll() async {
    _cache ??= await _read();
    return _cache!;
  }

  @override
  Future<Plant?> byId(String id) async {
    final all = await loadAll();
    try {
      return all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<List<Plant>> _read() async {
    final s = await rootBundle.loadString('assets/data/plants.json');
    final list = jsonDecode(s) as List<dynamic>;
    return list.map((e) => Plant.fromJson(e as Map<String, dynamic>)).toList();
  }
}
