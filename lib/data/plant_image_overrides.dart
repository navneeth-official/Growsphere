import '../domain/plant.dart';

/// Stable Wikimedia Commons thumbnails (no API key). Replaces flaky Unsplash hotlinks in [plants.json].
const _kWikimediaByPlantId = <String, String>{
  'tomato':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/88/Bright_red_tomato_and_cross_section02.jpg/640px-Bright_red_tomato_and_cross_section02.jpg',
  'chilli':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/3/38/Chili_peppers_dried_and_fresh.jpg/640px-Chili_peppers_dried_and_fresh.jpg',
  'okra':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/f/ff/Okra_in_Kerala.jpg/640px-Okra_in_Kerala.jpg',
  'brinjal':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/Frucht_der_Aubergine.jpg/640px-Frucht_der_Aubergine.jpg',
  'cucumber':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9e/Cucumber.jpg/640px-Cucumber.jpg',
  'beans':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/cf/French_beans_Whole.jpg/640px-French_beans_Whole.jpg',
  'peas':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/11/Peas_in_pods_-_Studio.jpg/640px-Peas_in_pods_-_Studio.jpg',
  'spinach':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/9a/Spinacia_oleracea_9.JPG/640px-Spinacia_oleracea_9.JPG',
  'lettuce':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d2/Lactuca_sativa_leaf.jpg/640px-Lactuca_sativa_leaf.jpg',
  'coriander':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/A_scene_of_Coriander_leaves.JPG/640px-A_scene_of_Coriander_leaves.JPG',
  'mint':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/48/Mentha_%28Mint%29_plant.jpg/640px-Mentha_%28Mint%29_plant.jpg',
  'basil':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Basil-Basilico-Ocimum_basilicum-albahaca.jpg/640px-Basil-Basilico-Ocimum_basilicum-albahaca.jpg',
  'wheat':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/44/Wheat_close-up.JPG/640px-Wheat_close-up.JPG',
  'rice':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/7/7b/Oryza_sativa_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-232.jpg/640px-Oryza_sativa_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-232.jpg',
  'maize':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e3/Zea_mays_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-283.jpg/640px-Zea_mays_-_K%C3%B6hler%E2%80%93s_Medizinal-Pflanzen-283.jpg',
  'potato':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/47/Patates.jpg/640px-Patates.jpg',
  'onion':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/25/Onions.jpg/640px-Onions.jpg',
  'garlic':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/0/04/Garlic.jpg/640px-Garlic.jpg',
  'carrot':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5f/Carrots_at_Ljubljana_Central_Market.jpg/640px-Carrots_at_Ljubljana_Central_Market.jpg',
  'radish':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d1/Radish_Whole.jpg/640px-Radish_Whole.jpg',
  'bottle_gourd':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1d/Calabash_Bottle_Gourd.jpg/640px-Calabash_Bottle_Gourd.jpg',
  'pumpkin':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/5c/Fruit_gourd.jpg/640px-Fruit_gourd.jpg',
  'strawberry':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/29/Perfect_strawberry.jpg/640px-Perfect_strawberry.jpg',
  'banana':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4c/Bananas_white_background_DS.jpg/640px-Bananas_white_background_DS.jpg',
  'mango':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/9/90/Mango_and_cross_section.jpg/640px-Mango_and_cross_section.jpg',
  'citrus':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Orange_fruit.jpg/640px-Orange_fruit.jpg',
  'rose':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Rosa_rubiginosa_1.jpg/640px-Rosa_rubiginosa_1.jpg',
  'marigold':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tagetes_erecta%2C_2015-07-17%2C_Sm%C3%B6gen%2C_01.jpg/640px-Tagetes_erecta%2C_2015-07-17%2C_Sm%C3%B6gen%2C_01.jpg',
  'sunflower':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/4/40/Sunflower_sky_backdrop.jpg/640px-Sunflower_sky_backdrop.jpg',
  'soybean':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/5/51/Soybean.USDA.jpg/640px-Soybean.USDA.jpg',
  'groundnut':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/b/b0/Arachis_hypogaea_004.JPG/640px-Arachis_hypogaea_004.JPG',
};

Plant plantWithStableImage(Plant p) {
  final u = _kWikimediaByPlantId[p.id];
  if (u == null) return p;
  return Plant(
    id: p.id,
    name: p.name,
    aliases: p.aliases,
    difficulty: p.difficulty,
    wateringLevel: p.wateringLevel,
    climate: p.climate,
    soil: p.soil,
    fertilizers: p.fertilizers,
    harvestDurationDays: p.harvestDurationDays,
    nutrientHeavy: p.nutrientHeavy,
    pestNotes: p.pestNotes,
    typicalPricePerKg: p.typicalPricePerKg,
    imageUrl: u,
  );
}
