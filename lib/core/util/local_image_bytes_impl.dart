import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readLocalImageBytesIfAvailable(String path) async {
  try {
    final f = File(path);
    if (!await f.exists()) return null;
    return f.readAsBytes();
  } catch (_) {
    return null;
  }
}
