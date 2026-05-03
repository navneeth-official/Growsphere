/// High-level browse groups for the plant catalog (Indian + general horticulture).
abstract final class PlantCatalogCategory {
  static const all = 'all';
  static const vegetables = 'vegetables';
  static const fruits = 'fruits';
  static const kharif = 'kharif';
  static const rabi = 'rabi';
  static const flowersHerbs = 'flowers_herbs';

  static const carouselShelfOrder = <String>[all, vegetables, fruits, kharif, rabi, flowersHerbs];

  static String labelOf(String id) => switch (id) {
        all => 'All crops',
        vegetables => 'Vegetables',
        fruits => 'Fruits',
        kharif => 'Kharif crops',
        rabi => 'Rabi crops',
        flowersHerbs => 'Flowers & herbs',
        _ => 'Browse',
      };

  /// Hero / carousel cover per browse shelf — bundled under [assets/images/categories/].
  ///
  /// Source bundle: `Vegetables.png`, `Fruits.png`, `Kharif.png`, `Rabi.png`, `Herbs and Flowers.png`.
  /// [all] uses `category_all.png` (same art as Kharif when no separate “all” image is provided).
  static String coverImageUrl(String categoryId) {
    return switch (categoryId) {
      all => 'assets/images/categories/category_all.png',
      vegetables => 'assets/images/categories/category_vegetables.png',
      fruits => 'assets/images/categories/category_fruits.png',
      kharif => 'assets/images/categories/category_kharif.png',
      rabi => 'assets/images/categories/category_rabi.png',
      flowersHerbs => 'assets/images/categories/category_flowers_herbs.png',
      _ => 'assets/images/categories/category_all.png',
    };
  }

  /// Single primary shelf for each bundled crop id.
  static String inferForPlantId(String plantId) {
    switch (plantId) {
      case 'rice':
      case 'maize':
      case 'soybean':
      case 'groundnut':
      case 'okra':
      case 'bottle_gourd':
        return kharif;
      case 'wheat':
      case 'peas':
      case 'garlic':
      case 'onion':
      case 'potato':
      case 'carrot':
      case 'radish':
      case 'spinach':
        return rabi;
      case 'strawberry':
      case 'banana':
      case 'mango':
      case 'citrus':
        return fruits;
      case 'rose':
      case 'marigold':
      case 'sunflower':
      case 'mint':
      case 'basil':
      case 'coriander':
        return flowersHerbs;
      default:
        return vegetables;
    }
  }
}
