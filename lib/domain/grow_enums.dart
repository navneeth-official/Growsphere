enum GrowLocationType { indoor, balcony, terrace }

enum SunlightLevel { low, medium, high }

extension GrowLocationTypeLabel on GrowLocationType {
  String get storageName => name;
}

extension SunlightLevelLabel on SunlightLevel {
  String get storageName => name;
}
