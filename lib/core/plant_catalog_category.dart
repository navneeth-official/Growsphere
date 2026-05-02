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

  /// Hero / carousel cover (Unsplash) per browse shelf.
  static String coverImageUrl(String categoryId) {
    return switch (categoryId) {
      all =>
        'https://images.unsplash.com/photo-1464226184804-fa7b189c6ebb?q=80&w=1200&auto=format&fit=crop',
      vegetables =>
        'https://images.unsplash.com/photo-1540420773420-33685e54c0bf?q=80&w=1200&auto=format&fit=crop',
      fruits =>
        'https://images.unsplash.com/photo-1619566636858-411f3bd938e1?q=80&w=1200&auto=format&fit=crop',
      kharif =>
        'https://images.unsplash.com/photo-1586201375761-83865001e31c?q=80&w=1200&auto=format&fit=crop',
      rabi =>
        'https://images.unsplash.com/photo-1574323347407-f5e1ad6d020b?q=80&w=1200&auto=format&fit=crop',
      flowersHerbs =>
        'https://images.unsplash.com/photo-1490759564078-f34be2b36687?q=80&w=1200&auto=format&fit=crop',
      _ =>
        'https://images.unsplash.com/photo-1464226184804-fa7b189c6ebb?q=80&w=1200&auto=format&fit=crop',
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
