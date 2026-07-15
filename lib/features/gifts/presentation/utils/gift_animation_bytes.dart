import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/utils/media_url_resolver.dart';

/// ISO BMFF / MP4: bytes[4..7] == 'ftyp'
bool giftBytesLookLikeMp4(List<int> bytes) {
  if (bytes.length < 8) return false;
  return bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70;
}

/// In-memory cache so we never re-download (or log) the same animation URL.
class GiftAnimationBytesCache {
  GiftAnimationBytesCache._();

  static final Map<String, Uint8List> _cache = <String, Uint8List>{};
  static final Map<String, Future<Uint8List>> _inflight =
      <String, Future<Uint8List>>{};

  static String _key(String rawUrl) => resolveMediaUrl(rawUrl) ?? rawUrl;

  static void put(String rawUrl, Uint8List bytes) {
    if (rawUrl.trim().isEmpty || bytes.isEmpty) return;
    _cache[_key(rawUrl)] = bytes;
  }

  static Uint8List? peek(String rawUrl) {
    if (rawUrl.trim().isEmpty) return null;
    return _cache[_key(rawUrl)];
  }

  /// Downloads once per URL. Uses a bare [Dio] (no LogInterceptor) so binary
  /// bodies are never printed to the console.
  static Future<Uint8List> get(String rawUrl) async {
    final url = _key(rawUrl);
    final cached = _cache[url];
    if (cached != null) return cached;

    final pending = _inflight[url];
    if (pending != null) return pending;

    final future = _download(url);
    _inflight[url] = future;
    try {
      final bytes = await future;
      _cache[url] = bytes;
      return bytes;
    } finally {
      _inflight.remove(url);
    }
  }

  static Future<Uint8List> _download(String url) async {
    if (kDebugMode) {
      debugPrint('GiftAnimationBytesCache: downloading (${url.length} chars)');
    }
    // Intentionally no shared Dio / LogInterceptor — binary dumps are huge.
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
      throw StateError('Empty animation download');
    }
    final bytes = Uint8List.fromList(data);
    if (kDebugMode) {
      debugPrint(
        'GiftAnimationBytesCache: got ${bytes.length} bytes'
        '${giftBytesLookLikeMp4(bytes) ? ' (mp4/ftyp)' : ''}',
      );
    }
    return bytes;
  }
}
