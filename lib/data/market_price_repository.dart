/// One point on a simple indicative price trend (model-estimated, not exchange data).
class MarketPriceSpot {
  MarketPriceSpot({required this.label, required this.pricePerKg});

  final String label;
  final double pricePerKg;
}

/// Series for a single crop (e.g. last few days) for sparkline / small board.
class MarketPriceSeries {
  MarketPriceSeries({required this.crop, required this.spots});

  final String crop;
  final List<MarketPriceSpot> spots;
}

/// Mock wholesale-style prices. Wire to agri APIs or Firestore `market_prices/{region}` later.
abstract class MarketPriceRepository {
  /// [regionLabel] human region (e.g. "Pune, Maharashtra"). [geoHint] optional "lat, lon" string for the model.
  Future<MarketBoardResult> fetchBoard({
    required String regionLabel,
    String? geoHint,
  });

  /// Indicative prices for [cropQuery] in [regionLabel] (any crop name; may not be in the app catalog).
  Future<MarketBoardResult> searchCropPrices({
    required String cropQuery,
    required String regionLabel,
    String? geoHint,
  });

  /// Lightweight name hints for the market search field (any crop, not limited to catalog).
  Future<List<String>> suggestCropNames(String partial);
}

class MarketRow {
  MarketRow({
    required this.crop,
    required this.pricePerKg,
    required this.unit,
    required this.updated,
    required this.changePercent,
  });

  final String crop;
  final double pricePerKg;
  final String unit;
  final DateTime updated;
  /// Positive = up (green), negative = down (red).
  final double changePercent;
}

class MarketBoardResult {
  MarketBoardResult({required this.rows, required this.series, this.insightNote});

  final List<MarketRow> rows;
  final List<MarketPriceSeries> series;
  /// Optional model note (search / regional context).
  final String? insightNote;
}

class MockMarketPriceRepository implements MarketPriceRepository {
  static const _kCropLexicon = <String>[
    'Tomato', 'Rice', 'Wheat', 'Potato', 'Onion', 'Brinjal', 'Okra', 'Cabbage', 'Cauliflower', 'Carrot',
    'Beans', 'Green pea', 'Chickpea', 'Moong', 'Urad', 'Tur', 'Groundnut', 'Soybean', 'Sunflower', 'Mustard',
    'Cotton', 'Sugarcane', 'Banana', 'Mango', 'Apple', 'Grapes', 'Watermelon', 'Cucumber', 'Bitter gourd',
    'Bottle gourd', 'Pumpkin', 'Spinach', 'Coriander', 'Mint', 'Garlic', 'Ginger', 'Turmeric', 'Coffee', 'Tea',
  ];

  @override
  Future<MarketBoardResult> fetchBoard({
    required String regionLabel,
    String? geoHint,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    final rows = [
      MarketRow(crop: 'Tomato', pricePerKg: 202.99, unit: 'INR/kg', updated: now, changePercent: 1.16),
      MarketRow(crop: 'Rice', pricePerKg: 97.34, unit: 'INR/kg', updated: now, changePercent: -3.24),
      MarketRow(crop: 'Wheat', pricePerKg: 28.5, unit: 'INR/kg', updated: now, changePercent: 0.42),
      MarketRow(crop: 'Potato', pricePerKg: 24.12, unit: 'INR/kg', updated: now, changePercent: -0.88),
      MarketRow(crop: 'Onion', pricePerKg: 35.6, unit: 'INR/kg', updated: now, changePercent: 2.05),
    ];
    final series = rows.take(3).map((r) {
      final spots = <MarketPriceSpot>[];
      for (var i = 6; i >= 0; i--) {
        final wobble = 1 + (i - 3) * 0.012 * (r.changePercent.sign);
        spots.add(MarketPriceSpot(label: '-${i}d', pricePerKg: (r.pricePerKg * wobble).clamp(0.5, 99999)));
      }
      return MarketPriceSeries(crop: r.crop, spots: spots);
    }).toList();
    return MarketBoardResult(rows: rows, series: series);
  }

  @override
  Future<MarketBoardResult> searchCropPrices({
    required String cropQuery,
    required String regionLabel,
    String? geoHint,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final now = DateTime.now();
    final name = cropQuery.trim().isEmpty ? 'Custom crop' : cropQuery.trim();
    final hash = name.hashCode.abs() % 800;
    final price = 12.0 + (hash % 400);
    final row = MarketRow(crop: name, pricePerKg: price, unit: 'INR/kg', updated: now, changePercent: (hash % 17) - 8);
    final spots = <MarketPriceSpot>[];
    for (var i = 6; i >= 0; i--) {
      final wobble = 1 + (i - 3) * 0.008;
      spots.add(MarketPriceSpot(label: '-${i}d', pricePerKg: (price * wobble).clamp(0.5, 99999)));
    }
    final series = [MarketPriceSeries(crop: name, spots: spots)];
    return MarketBoardResult(
      rows: [row],
      series: series,
      insightNote:
          'Offline demo estimate for “$name” in $regionLabel — connect Gemini for model-guided ranges and tips.',
    );
  }

  @override
  Future<List<String>> suggestCropNames(String partial) async {
    final s = partial.trim().toLowerCase();
    if (s.length < 2) return [];
    return _kCropLexicon.where((c) => c.toLowerCase().contains(s)).take(8).toList();
  }
}
