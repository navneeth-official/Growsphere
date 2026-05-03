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

  /// Hero / carousel cover per browse shelf — files in [assets/images/categories/]
  /// from `agricultural_images_bundle` (same base names: `vegetables.png`, `fruits.png`, …).
  /// [all] uses [all_crops.png] (copy of vegetables bundle art — add a dedicated asset anytime).
  static String coverImageUrl(String categoryId) {
    return switch (categoryId) {
      all => 'assets/images/categories/all_crops.png',
      vegetables => 'assets/images/categories/vegetables.png',
      fruits => 'assets/images/categories/fruits.png',
      kharif => 'assets/images/categories/kharif_crops.png',
      rabi => 'assets/images/categories/rabi_crops.png',
      flowersHerbs => 'assets/images/categories/flowers_herbs.png',
      _ => 'assets/images/categories/all_crops.png',
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
