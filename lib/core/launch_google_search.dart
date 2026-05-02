import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

Uri googleSearchUri(String query) {
  final q = query.trim();
  final effective = q.isEmpty ? 'plant growing guide' : q;
  return Uri.https('www.google.com', '/search', {'q': effective});
}

Future<bool> launchGoogleSearch(String query) async {
  final uri = googleSearchUri(query);
  try {
    final can = await canLaunchUrl(uri);
    if (can) {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return true;
    }
    return await launchUrl(uri, mode: LaunchMode.platformDefault);
  } catch (e, st) {
    debugPrint('launchGoogleSearch failed: $e\n$st');
    return false;
  }
}
