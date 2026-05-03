/// Bundled hand-held crop photos (PNG files in the repo).
///
/// **On disk:** `assets/images/crops/hands/<plant_id>.png`
/// **Pubspec:** `assets/images/crops/hands/`
/// **Runtime:** wired through [plantWithStableImage] in [plant_image_overrides.dart].
/// **Refresh from Cursor uploads:** `tool/sync_hand_crop_images.ps1`
library;

/// Asset directory (trailing slash omitted — append `/$id.png`).
const bundledHandCropImageDir = 'assets/images/crops/hands';

/// Catalog plant ids that have a named `<id>.png` in [bundledHandCropImageDir].
const bundledHandCropPlantIds = <String>[
  'chilli',
  'tomato',
  'brinjal',
  'cucumber',
  'beans',
  'lettuce',
  'pumpkin',
  'strawberry',
  'banana',
  'mango',
  'citrus',
  'wheat',
  'peas',
  'garlic',
  'onion',
  'potato',
  'carrot',
  'radish',
  'spinach',
];

String bundledHandCropPngPath(String plantId) =>
    '$bundledHandCropImageDir/$plantId.png';
