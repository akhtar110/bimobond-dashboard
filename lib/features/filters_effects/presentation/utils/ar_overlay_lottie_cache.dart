import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/utils/media_url_resolver.dart';

/// In-memory bytes + composition cache so overlay previews do not re-download
/// or re-parse the same Lottie URL on every dialog open.
class ArOverlayLottieCache {
  ArOverlayLottieCache._();

  static final Map<String, Uint8List> _bytes = <String, Uint8List>{};
  static final Map<String, Future<Uint8List>> _inflight =
      <String, Future<Uint8List>>{};
  static final Map<String, LottieComposition> _compositions =
      <String, LottieComposition>{};

  static String _key(String rawUrl) => resolveMediaUrl(rawUrl) ?? rawUrl.trim();

  static void putBytes(String rawUrl, Uint8List bytes) {
    if (rawUrl.trim().isEmpty || bytes.isEmpty) return;
    _bytes[_key(rawUrl)] = bytes;
  }

  static Uint8List? peekBytes(String rawUrl) {
    if (rawUrl.trim().isEmpty) return null;
    return _bytes[_key(rawUrl)];
  }

  static LottieComposition? peekComposition(String cacheKey) =>
      _compositions[cacheKey];

  static void putComposition(String cacheKey, LottieComposition composition) {
    _compositions[cacheKey] = composition;
  }

  static Future<Uint8List> getBytes(String rawUrl) async {
    final url = _key(rawUrl);
    final cached = _bytes[url];
    if (cached != null) return cached;

    final pending = _inflight[url];
    if (pending != null) return pending;

    final future = _download(url);
    _inflight[url] = future;
    try {
      final bytes = await future;
      _bytes[url] = bytes;
      return bytes;
    } finally {
      _inflight.remove(url);
    }
  }

  static Future<Uint8List> _download(String url) async {
    if (kDebugMode) {
      debugPrint('ArOverlayLottieCache: downloading (${url.length} chars)');
    }
    final dio = Dio();
    final response = await dio.get<List<int>>(
      url,
      options: Options(
        responseType: ResponseType.bytes,
        followRedirects: true,
        validateStatus: (code) => code != null && code >= 200 && code < 400,
      ),
    );
    final data = response.data;
    if (data == null || data.isEmpty) {
      throw StateError('Empty Lottie download');
    }
    return Uint8List.fromList(data);
  }
}
