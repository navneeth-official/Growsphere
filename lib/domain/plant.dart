/// Crop catalog entry bundled with the app.
/// Firestore mirror: collection `plants` with same field names.
class Plant {
  const Plant({
    required this.id,
    required this.name,
    required this.aliases,
    required this.difficulty,
    required this.wateringLevel,
    required this.climate,
    required this.soil,
    required this.fertilizers,
    required this.harvestDurationDays,
    required this.nutrientHeavy,
    required this.pestNotes,
    required this.typicalPricePerKg,
    this.imageUrl,
  });

  final String id;
  final String name;
  /// Optional cover image (reference V1 used remote crop photos).
  final String? imageUrl;
  final List<String> aliases;
  final String difficulty;
  /// `low` | `medium` | `high` — drives watering intervals.
  final String wateringLevel;
  final String climate;
  final String soil;
  final String fertilizers;
  final int harvestDurationDays;
  final bool nutrientHeavy;
  final String pestNotes;
  final double typicalPricePerKg;

  factory Plant.fromJson(Map<String, dynamic> json) {
    return Plant(
      id: json['id'] as String,
      name: json['name'] as String,
      aliases: (json['aliases'] as List<dynamic>? ?? []).cast<String>(),
      difficulty: json['difficulty'] as String,
      wateringLevel: json['wateringLevel'] as String,
      climate: json['climate'] as String,
      soil: json['soil'] as String,
      fertilizers: json['fertilizers'] as String,
      harvestDurationDays: (json['harvestDurationDays'] as num).toInt(),
      nutrientHeavy: json['nutrientHeavy'] as bool? ?? false,
      pestNotes: json['pestNotes'] as String? ?? '',
      typicalPricePerKg: (json['typicalPricePerKg'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'aliases': aliases,
        'difficulty': difficulty,
        'wateringLevel': wateringLevel,
        'climate': climate,
        'soil': soil,
        'fertilizers': fertilizers,
        'harvestDurationDays': harvestDurationDays,
        'nutrientHeavy': nutrientHeavy,
        'pestNotes': pestNotes,
        'typicalPricePerKg': typicalPricePerKg,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  bool matchesQuery(String q) {
    final s = q.trim().toLowerCase();
    if (s.isEmpty) return true;
    if (name.toLowerCase().contains(s)) return true;
    for (final a in aliases) {
      if (a.toLowerCase().contains(s)) return true;
    }
    return false;
  }
}
