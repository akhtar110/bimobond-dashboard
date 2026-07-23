import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/services.dart';

import '../constants/fe_preview_assets.dart';

/// Cross-open caches for filter preview scene + LUT network bytes.
abstract final class FePreviewCache {
  static ui.Image? _sceneImage;
  static Future<ui.Image?>? _sceneLoad;
  static final Map<String, Uint8List> _lutBytesByUrl = {};
  static const int _maxLutEntries = 24;

  /// Cached decoded scene image used as LUT source (shared, never disposed).
  static Future<ui.Image?> loadSceneImage() {
    if (_sceneImage != null) return Future.value(_sceneImage);
    return _sceneLoad ??= _decodeScene();
  }

  static Future<ui.Image?> _decodeScene() async {
    try {
      final data = await rootBundle.load(FePreviewAssets.previewScene);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      _sceneImage = frame.image;
      return _sceneImage;
    } catch (_) {
      _sceneLoad = null;
      return null;
    }
  }

  static Uint8List? lutBytes(String url) => _lutBytesByUrl[url];

  static void putLutBytes(String url, Uint8List bytes) {
    if (url.isEmpty || bytes.isEmpty) return;
    if (_lutBytesByUrl.length >= _maxLutEntries &&
        !_lutBytesByUrl.containsKey(url)) {
      _lutBytesByUrl.remove(_lutBytesByUrl.keys.first);
    }
    _lutBytesByUrl[url] = bytes;
  }
}
