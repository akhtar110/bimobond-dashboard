import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';

import '../../../../core/config/api_config.dart';
import '../../../../core/utils/media_url_resolver.dart';

typedef FePreviewNetworkImageLoader = Future<ui.Image?> Function(String url);
typedef FePreviewNetworkBytesLoader = Future<Uint8List?> Function(String url);

/// Optional override registered by [FeFilterPreviewSupport] for authenticated fetches.
FePreviewNetworkBytesLoader? fePreviewNetworkBytesLoader;

/// Optional override registered by [FiltersEffectsManagementPage] so LUT previews
/// use the authenticated Dio client and hosted API proxy base.
FePreviewNetworkImageLoader? fePreviewNetworkImageLoader;

/// Loads a remote image for filter/effect live previews.
Future<ui.Image?> loadFePreviewNetworkImage(String url) async {
  if (fePreviewNetworkImageLoader != null) {
    return fePreviewNetworkImageLoader!(url);
  }

  final bytes = await loadFePreviewNetworkBytes(url);
  if (bytes == null || bytes.isEmpty) return null;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  } catch (_) {
    return null;
  }
}

/// Loads raw bytes for `.cube` LUT files and other non-image assets.
Future<Uint8List?> loadFePreviewNetworkBytes(String url) async {
  if (fePreviewNetworkBytesLoader != null) {
    return fePreviewNetworkBytesLoader!(url);
  }

  final resolved = resolveMediaUrl(url) ?? url.trim();
  if (resolved.isEmpty) return null;

  try {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 20),
        responseType: ResponseType.bytes,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    final response = await dio.get<List<int>>(resolved);
    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return Uint8List.fromList(data);
  } catch (_) {
    try {
      final absolute = resolved.startsWith('http')
          ? resolved
          : '${ApiConfig.resolve()}${resolved.startsWith('/') ? resolved : '/$resolved'}';
      final dio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 20),
          responseType: ResponseType.bytes,
        ),
      );
      final response = await dio.get<List<int>>(absolute);
      final data = response.data;
      if (data == null || data.isEmpty) return null;
      return Uint8List.fromList(data);
    } catch (_) {
      return null;
    }
  }
}
