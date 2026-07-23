import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/utils/media_url_resolver.dart';
import 'fe_preview_cache.dart';
import 'fe_preview_image_loader.dart';

/// Ensures filter LUT previews use authenticated fetches **without** dumping
/// binary PNG/CUBE bodies through [LogInterceptor].
abstract final class FeFilterPreviewSupport {
  static Dio? _binaryDio;
  static bool _configured = false;

  static void ensureConfigured() {
    if (_configured) return;
    _configured = true;
    MediaUrlResolver.init(ApiConfig.resolve());
    _binaryDio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        responseType: ResponseType.bytes,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 400,
      ),
    );
    // Intentionally no LogInterceptor — LUT PNG bodies are huge.
    fePreviewNetworkImageLoader = _loadPreviewImage;
    fePreviewNetworkBytesLoader = _loadPreviewBytes;
    // Warm the scene decode so the first LUT preview opens faster.
    unawaited(FePreviewCache.loadSceneImage());
  }

  static String resolveFetchUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return trimmed;

    var resolved = resolveMediaUrl(trimmed) ?? trimmed;
    final parsed = Uri.tryParse(resolved);
    if (parsed == null) return resolved;

    if (ApiConfig.usesHostedApiProxy) {
      final backend = Uri.tryParse(ApiConfig.backendUrl);
      if (backend != null &&
          parsed.host == backend.host &&
          parsed.scheme == backend.scheme) {
        final path = parsed.hasQuery
            ? '${parsed.path}?${parsed.query}'
            : parsed.path;
        resolved = '${Uri.base.origin}${ApiConfig.hostedApiProxyPath}$path';
      }
    }

    return resolved;
  }

  static Future<ui.Image?> _loadPreviewImage(String url) async {
    final bytes = await _loadPreviewBytes(url);
    if (bytes == null || bytes.isEmpty) return null;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (_) {
      return null;
    }
  }

  static Future<Uint8List?> _loadPreviewBytes(String url) async {
    final dio = _binaryDio;
    if (dio == null) return null;

    final fetchUrl = resolveFetchUrl(url);
    if (fetchUrl.isEmpty) return null;

    final cached = FePreviewCache.lutBytes(fetchUrl);
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final headers = <String, dynamic>{};
      try {
        final user = FirebaseAuth.instance.currentUser;
        // Prefer cached token; force refresh only if missing.
        final token = await user?.getIdToken(false);
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }
      } catch (_) {}

      final response = await dio.get<List<int>>(
        fetchUrl,
        options: Options(headers: headers, responseType: ResponseType.bytes),
      );
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      final bytes = Uint8List.fromList(data);
      FePreviewCache.putLutBytes(fetchUrl, bytes);
      if (kDebugMode) {
        debugPrint(
          'FeFilterPreviewSupport: loaded ${bytes.length} LUT bytes',
        );
      }
      return bytes;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FeFilterPreviewSupport: LUT fetch failed: $e');
      }
      return null;
    }
  }
}
