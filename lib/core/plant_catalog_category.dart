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

  /// Hero / carousel cover per browse shelf (Wikimedia Commons thumbnails — reliable hotlinking).
  static String coverImageUrl(String categoryId) {
    return switch (categoryId) {
      all =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Agriculture_in_Volcano.jpg/960px-Agriculture_in_Volcano.jpg',
      vegetables =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Bright_red_tomato_and_cross_section02.jpg/960px-Bright_red_tomato_and_cross_section02.jpg',
      fruits =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c4/Pomegranates.jpg/960px-Pomegranates.jpg',
      kharif =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/09/Rice_plants_(IRRI).jpg/960px-Rice_plants_(IRRI).jpg',
      rabi =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Spikes_of_wheat.jpg/960px-Spikes_of_wheat.jpg',
      flowersHerbs =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9b/Marigold_big_flower_2013.jpg/960px-Marigold_big_flower_2013.jpg',
      _ =>
        'https://upload.wikimedia.org/wikipedia/commons/thumb/6/6e/Agriculture_in_Volcano.jpg/960px-Agriculture_in_Volcano.jpg',
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
