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
  /// Replace these files with your own art (e.g. PNG) and update extensions here if needed:
  /// `category_all`, `category_vegetables`, `category_fruits`, `category_kharif`, `category_rabi`, `category_flowers_herbs`.
  static String coverImageUrl(String categoryId) {
    return switch (categoryId) {
      all => 'assets/images/categories/category_all.jpg',
      vegetables => 'assets/images/categories/category_vegetables.jpg',
      fruits => 'assets/images/categories/category_fruits.jpg',
      kharif => 'assets/images/categories/category_kharif.jpg',
      rabi => 'assets/images/categories/category_rabi.jpg',
      flowersHerbs => 'assets/images/categories/category_flowers_herbs.jpg',
      _ => 'assets/images/categories/category_all.jpg',
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
