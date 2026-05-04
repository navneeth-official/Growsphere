/// Stable ids for persisted AI tool conversation memory (Hive via [GrowStorage]).
abstract final class AiToolIds {
  static const farmPlan = 'farm_plan';
  static const cropResearch = 'crop_research';
  static const diseaseVision = 'disease_vision';
  static const marketPrices = 'market_prices';
  static const marketCropSearch = 'market_crop_search';
  static const marketNameSuggest = 'market_name_suggest';
  static const locationCropSuggest = 'location_crop_suggest';
  static const plantWaterSetup = 'plant_water_setup';
  static const sprinklerAdvice = 'sprinkler_advice';
  static const weatherFallback = 'weather_fallback';
  static const gardenCoachTip = 'garden_coach_tip';

  static const List<(String id, String title)> settingsRows = [
    (farmPlan, 'Farm plan generator'),
    (cropResearch, 'Add crop — research assistant'),
    (diseaseVision, 'Plant health & image tools'),
    (marketPrices, 'Market board & crop prices'),
    (marketCropSearch, 'Market — crop search'),
    (marketNameSuggest, 'Market — name suggestions'),
    (locationCropSuggest, 'Browse — location crop picks'),
    (plantWaterSetup, 'Plant setup — watering note'),
    (sprinklerAdvice, 'Sprinkler AI timing'),
    (weatherFallback, 'Weather screen — AI fallback'),
    (gardenCoachTip, 'My garden — combined tip'),
  ];
}
