import '../domain/plant.dart';

/// Bundled crop photos: most ids use the BGR archive under [assets/images/crops/*.jpg].
/// Hand-held reference photos: named files [assets/images/crops/hands/<plant_id>.png]
/// (see [bundled_hand_crop_asset_paths.dart]).
/// Refresh images: run [tool/sync_hand_crop_images.ps1] after placing files in Downloads\Growsphere_hand_crops
/// (see script header). Legacy: copy_vegetable_hand_crops / copy_fruit_hand_crops / copy_rabi_hand_crops.
const _kBundledAssetByPlantId = <String, String>{
  'tomato': 'assets/images/crops/hands/tomato.png',
  'chilli': 'assets/images/crops/hands/chilli.png',
  'okra': 'assets/images/crops/hands/okra.png',
  'brinjal': 'assets/images/crops/hands/brinjal.png',
  'cucumber': 'assets/images/crops/hands/cucumber.png',
  'beans': 'assets/images/crops/hands/beans.png',
  'peas': 'assets/images/crops/hands/peas.png',
  'spinach': 'assets/images/crops/hands/spinach.png',
  'lettuce': 'assets/images/crops/hands/lettuce.png',
  'coriander': 'assets/images/crops/hands/coriander.png',
  'mint': 'assets/images/crops/hands/mint.png',
  'basil': 'assets/images/crops/hands/basil.png',
  'wheat': 'assets/images/crops/hands/wheat.png',
  'rice': 'assets/images/crops/hands/rice.png',
  'maize': 'assets/images/crops/hands/maize.png',
  'potato': 'assets/images/crops/hands/potato.png',
  'onion': 'assets/images/crops/hands/onion.png',
  'garlic': 'assets/images/crops/hands/garlic.png',
  'carrot': 'assets/images/crops/hands/carrot.png',
  'radish': 'assets/images/crops/hands/radish.png',
  'bottle_gourd': 'assets/images/crops/hands/bottle_gourd.png',
  'pumpkin': 'assets/images/crops/hands/pumpkin.png',
  'strawberry': 'assets/images/crops/hands/strawberry.png',
  'banana': 'assets/images/crops/hands/banana.png',
  'mango': 'assets/images/crops/hands/mango.png',
  'citrus': 'assets/images/crops/hands/citrus.png',
  'sunflower': 'assets/images/crops/hands/sunflower.png',
  'soybean': 'assets/images/crops/hands/soybean.png',
  'groundnut': 'assets/images/crops/hands/groundnut.png',
  'rose': 'assets/images/crops/hands/rose.png',
  'marigold': 'assets/images/crops/hands/marigold.png',
};

/// Stable Wikimedia thumbnails for catalog entries without a bundled asset (no API key).
const _kWikimediaByPlantId = <String, String>{};

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
