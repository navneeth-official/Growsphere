import 'dart:typed_data';

import 'local_image_bytes_impl.dart'
    if (dart.library.html) 'local_image_bytes_stub.dart' as impl;

Future<Uint8List?> readLocalImageBytesIfAvailable(String path) =>
    impl.readLocalImageBytesIfAvailable(path);
