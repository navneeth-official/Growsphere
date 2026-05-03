import 'dart:convert';

import 'package:http/http.dart' as http;

/// OpenStreetMap Nominatim (free). [Usage policy](https://operations.osmfoundation.org/policies/nominatim/) — one request per second max; cache-friendly.
class ReverseGeocodeService {
  static const _ua = 'Growsphere/1.0 (growsphere local weather; contact: app)';

  /// Short place label (neighbourhood / city / region) or null on failure.
  Future<String?> placeLabel(double lat, double lon) async {
    final uri = Uri.parse(
      'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1',
    );
    try {
      final res = await http.get(
        uri,
        headers: {'User-Agent': _ua, 'Accept-Language': 'en'},
      );
      if (res.statusCode != 200) return null;
      final j = jsonDecode(res.body) as Map<String, dynamic>;
      final addr = j['address'] as Map<String, dynamic>?;
      if (addr == null) return j['display_name'] as String?;
      String? pick(String k) => addr[k] as String?;
      return pick('suburb') ??
          pick('neighbourhood') ??
          pick('village') ??
          pick('town') ??
          pick('city') ??
          pick('municipality') ??
          pick('county') ??
          pick('state_district') ??
          pick('state') ??
          j['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
