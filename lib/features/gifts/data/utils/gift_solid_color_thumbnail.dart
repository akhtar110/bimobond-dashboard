import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Builds a small solid-color PNG used as the catalog thumbnail for AUDIO gifts
/// (API still requires `thumbnailUrl`; the UI does not upload an image).
Future<Uint8List> buildGiftSolidColorThumbnailPng(
  String? hex, {
  int size = 128,
}) async {
  final color = _parseHex(hex) ?? const Color(0xFFFF2D55);
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final rect = Rect.fromLTWH(0, 0, size.toDouble(), size.toDouble());
  canvas.drawRect(rect, Paint()..color = color);

  // Soft center highlight so tiles don't look completely flat.
  canvas.drawCircle(
    Offset(size / 2, size / 2),
    size * 0.28,
    Paint()..color = Colors.white.withValues(alpha: 0.18),
  );

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  if (bytes == null) {
    throw StateError('Failed to encode solid color gift thumbnail');
  }
  return bytes.buffer.asUint8List();
}

Color? _parseHex(String? raw) {
  if (raw == null) return null;
  final value = raw.trim();
  if (value.isEmpty) return null;
  final withHash = value.startsWith('#') ? value : '#$value';
  if (!RegExp(r'^#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})$').hasMatch(withHash)) {
    return null;
  }
  var hex = withHash.substring(1);
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  final parsed = int.tryParse(hex, radix: 16);
  if (parsed == null) return null;
  return Color(0xFF000000 | parsed);
}
