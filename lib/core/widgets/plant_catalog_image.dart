import 'dart:io';

import 'package:flutter/material.dart';

import '../network/image_request_headers.dart';

/// Catalog [Plant.imageUrl]: remote `http`, bundled `assets/…`, or device [File] path.
Widget plantCatalogImage(
  String imageUrl, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  ImageErrorWidgetBuilder? errorBuilder,
}) {
  Widget fallback() => const Center(child: Icon(Icons.broken_image));
  final err = errorBuilder ?? (_, __, ___) => fallback();
  if (imageUrl.startsWith('http')) {
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      headers: ImageRequestHeaders.standard,
      errorBuilder: err,
    );
  }
  if (imageUrl.startsWith('assets/')) {
    return Image.asset(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: err,
    );
  }
  return Image.file(
    File(imageUrl),
    fit: fit,
    width: width,
    height: height,
    errorBuilder: err,
  );
}
