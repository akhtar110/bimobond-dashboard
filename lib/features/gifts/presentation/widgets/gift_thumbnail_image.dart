import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/utils/media_url_resolver.dart';
import 'gift_native_svg_view.dart';

/// Whether [name], [url], or [bytes] look like an SVG asset.
bool giftLooksLikeSvg({
  String? name,
  String? url,
  Uint8List? bytes,
}) {
  final candidates = <String>[
    ?name,
    ?url,
  ];
  for (final raw in candidates) {
    final value = raw.trim().toLowerCase();
    if (value.isEmpty) continue;
    final path = value.split('?').first.split('#').first;
    if (path.endsWith('.svg') ||
        path.contains('.svg.') ||
        value.contains('image/svg') ||
        value.contains('image%2fsvg') ||
        // CDN / upload paths sometimes keep "svg" in the filename segment.
        RegExp(r'(^|[_\-./])svg([_\-./]|$)').hasMatch(path)) {
      return true;
    }
  }

  if (bytes == null || bytes.isEmpty) return false;
  final headLen = bytes.length < 512 ? bytes.length : 512;
  try {
    final head = utf8
        .decode(bytes.sublist(0, headLen), allowMalformed: true)
        .replaceAll('\uFEFF', '')
        .toLowerCase();
    return head.contains('<svg');
  } catch (_) {
    return false;
  }
}

/// Renders a gift thumbnail from network URL and/or in-memory bytes.
///
/// On web, SVGs use a native HTML `<img>` so CSS-styled SVGs display correctly.
/// Raster formats keep using [Image] / [CachedNetworkImage].
class GiftThumbnailImage extends StatelessWidget {
  const GiftThumbnailImage({
    super.key,
    this.networkUrl,
    this.bytes,
    this.fileName,
    this.fit = BoxFit.contain,
    this.width,
    this.height,
    this.memCacheWidth,
    this.placeholder,
    this.errorWidget,
  });

  final String? networkUrl;
  final Uint8List? bytes;
  final String? fileName;
  final BoxFit fit;
  final double? width;
  final double? height;
  final int? memCacheWidth;
  final Widget? placeholder;
  final Widget? errorWidget;

  String? get _resolvedUrl {
    final raw = networkUrl?.trim() ?? '';
    if (raw.isEmpty) return null;
    return resolveMediaUrl(raw) ?? raw;
  }

  Widget _fill(Widget child) {
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: child);
    }
    return SizedBox.expand(child: child);
  }

  Widget _svg({
    required Uint8List? svgBytes,
    required String? url,
    required Widget fallback,
  }) {
    // Prefer browser-native rendering on web (create / edit / preview / cards).
    if (kIsWeb) {
      return _fill(
        GiftNativeSvgView(
          key: ValueKey(
            'svg-${svgBytes != null ? identityHashCode(svgBytes) : url}',
          ),
          bytes: svgBytes,
          networkUrl: url,
          fit: fit,
          errorWidget: fallback,
        ),
      );
    }

    if (svgBytes != null && svgBytes.isNotEmpty) {
      return _fill(
        SvgPicture.memory(
          svgBytes,
          fit: fit,
          width: width,
          height: height,
          allowDrawingOutsideViewBox: true,
          placeholderBuilder: (_) => placeholder ?? fallback,
        ),
      );
    }

    if (url != null && url.isNotEmpty) {
      return _fill(
        SvgPicture.network(
          url,
          fit: fit,
          width: width,
          height: height,
          allowDrawingOutsideViewBox: true,
          placeholderBuilder: (_) => placeholder ?? fallback,
        ),
      );
    }

    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final fallback = errorWidget ?? placeholder ?? const SizedBox.shrink();
    final hasBytes = bytes != null && bytes!.isNotEmpty;
    final url = _resolvedUrl ?? '';

    if (hasBytes) {
      if (giftLooksLikeSvg(name: fileName, url: url, bytes: bytes)) {
        return _svg(svgBytes: bytes, url: url.isEmpty ? null : url, fallback: fallback);
      }
      return _fill(
        Image.memory(
          bytes!,
          fit: fit,
          width: width,
          height: height,
          errorBuilder: (_, _, _) => fallback,
        ),
      );
    }

    if (url.isEmpty) return fallback;

    if (giftLooksLikeSvg(name: fileName, url: url)) {
      return _svg(svgBytes: null, url: url, fallback: fallback);
    }

    // Raster path — if decode fails (SVG without .svg extension), fall back
    // to native SVG rendering so cards/preview still show the gift art.
    return _fill(
      CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        memCacheWidth: memCacheWidth,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (_, _) => placeholder ?? fallback,
        errorWidget: (_, _, _) => _svg(
          svgBytes: null,
          url: url,
          fallback: fallback,
        ),
      ),
    );
  }
}
