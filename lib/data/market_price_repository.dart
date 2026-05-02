/// Mock wholesale-style prices. Wire to agri APIs or Firestore `market_prices/{region}` later.
abstract class MarketPriceRepository {
  Future<List<MarketRow>> latestRows();
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

class MockMarketPriceRepository implements MarketPriceRepository {
  @override
  Future<List<MarketRow>> latestRows() async {
    await Future<void>.delayed(const Duration(milliseconds: 900));
    final now = DateTime.now();
    return [
      MarketRow(crop: 'Tomato', pricePerKg: 202.99, unit: 'INR/kg', updated: now, changePercent: 1.16),
      MarketRow(crop: 'Rice', pricePerKg: 97.34, unit: 'INR/kg', updated: now, changePercent: -3.24),
      MarketRow(crop: 'Wheat', pricePerKg: 28.5, unit: 'INR/kg', updated: now, changePercent: 0.42),
      MarketRow(crop: 'Potato', pricePerKg: 24.12, unit: 'INR/kg', updated: now, changePercent: -0.88),
      MarketRow(crop: 'Onion', pricePerKg: 35.6, unit: 'INR/kg', updated: now, changePercent: 2.05),
    ];
  }
}
