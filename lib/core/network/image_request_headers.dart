/// Some CDNs (e.g. Unsplash) expect a non-empty User-Agent for hotlinked images.
abstract final class ImageRequestHeaders {
  static const Map<String, String> standard = {
    'User-Agent': 'GrowSphere/1.0 (Flutter; educational app)',
  };
}
