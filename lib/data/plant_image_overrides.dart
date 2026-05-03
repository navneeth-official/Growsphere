import '../domain/plant.dart';

/// Bundled 224×224 crop photos copied from the local archive
/// `BGR_224x224/BGR_224x224/test/<class folder>/` (first `.jpg` per folder; pumpkin uses a second file
/// from the gourds folder). Coriander and basil use parsley / oregano class folders as the archive
/// has no dedicated coriander or sweet-basil class names matching the app catalog.
const _kBundledAssetByPlantId = <String, String>{
  'tomato': 'assets/images/crops/tomato.jpg',
  'chilli': 'assets/images/crops/chilli.jpg',
  'okra': 'assets/images/crops/okra.jpg',
  'brinjal': 'assets/images/crops/brinjal.jpg',
  'cucumber': 'assets/images/crops/cucumber.jpg',
  'beans': 'assets/images/crops/beans.jpg',
  'peas': 'assets/images/crops/peas.jpg',
  'spinach': 'assets/images/crops/spinach.jpg',
  'lettuce': 'assets/images/crops/lettuce.jpg',
  'coriander': 'assets/images/crops/coriander.jpg',
  'mint': 'assets/images/crops/mint.jpg',
  'basil': 'assets/images/crops/basil.jpg',
  'wheat': 'assets/images/crops/wheat.jpg',
  'rice': 'assets/images/crops/rice.jpg',
  'maize': 'assets/images/crops/maize.jpg',
  'potato': 'assets/images/crops/potato.jpg',
  'onion': 'assets/images/crops/onion.jpg',
  'garlic': 'assets/images/crops/garlic.jpg',
  'carrot': 'assets/images/crops/carrot.jpg',
  'radish': 'assets/images/crops/radish.jpg',
  'bottle_gourd': 'assets/images/crops/bottle_gourd.jpg',
  'pumpkin': 'assets/images/crops/pumpkin.jpg',
  'strawberry': 'assets/images/crops/strawberry.jpg',
  'banana': 'assets/images/crops/banana.jpg',
  'mango': 'assets/images/crops/mango.jpg',
  'citrus': 'assets/images/crops/citrus.jpg',
  'sunflower': 'assets/images/crops/sunflower.jpg',
  'soybean': 'assets/images/crops/soybean.jpg',
  'groundnut': 'assets/images/crops/groundnut.jpg',
};

/// Stable Wikimedia thumbnails for catalog entries without a bundled asset (no API key).
const _kWikimediaByPlantId = <String, String>{
  'rose':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2a/Rosa_rubiginosa_1.jpg/640px-Rosa_rubiginosa_1.jpg',
  'marigold':
      'https://upload.wikimedia.org/wikipedia/commons/thumb/8/89/Tagetes_erecta%2C_2015-07-17%2C_Sm%C3%B6gen%2C_01.jpg/640px-Tagetes_erecta%2C_2015-07-17%2C_Sm%C3%B6gen%2C_01.jpg',
};

Plant plantWithStableImage(Plant p) {
  final bundled = _kBundledAssetByPlantId[p.id];
  if (bundled != null) {
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
      imageUrl: bundled,
    );
  }
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
