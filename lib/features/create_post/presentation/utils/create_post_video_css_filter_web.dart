import 'dart:html' as html;

const _svgHostId = 'create-post-video-filter-svg-host';

/// Applies one or more Flutter-style 5×4 color matrices to the HTML <video>
/// that is playing [objectUrl]. [ColorFiltered] cannot tint web platform views.
void applyCssColorMatricesToVideoUrl(
  String objectUrl,
  List<List<double>> matrices, {
  int attempt = 0,
}) {
  final video = _findVideoByObjectUrl(objectUrl);
  if (video == null) {
    // VideoPlayer may insert the <video> a frame or two later.
    if (attempt < 12) {
      Future<void>.delayed(const Duration(milliseconds: 40), () {
        applyCssColorMatricesToVideoUrl(
          objectUrl,
          matrices,
          attempt: attempt + 1,
        );
      });
    }
    return;
  }

  if (matrices.isEmpty) {
    video.style.removeProperty('filter');
    return;
  }

  final filterId = _ensureSvgFilter(objectUrl, matrices);
  video.style.setProperty('filter', 'url(#$filterId)');
}

void clearCssColorFilterForVideoUrl(String objectUrl) {
  final video = _findVideoByObjectUrl(objectUrl);
  video?.style.removeProperty('filter');
}

html.VideoElement? _findVideoByObjectUrl(String objectUrl) {
  final videos = html.document.querySelectorAll('video');
  for (final node in videos) {
    if (node is! html.VideoElement) continue;
    final src = node.currentSrc.isNotEmpty ? node.currentSrc : node.src;
    if (src == objectUrl || src.endsWith(objectUrl) || src.contains(objectUrl)) {
      return node;
    }
  }
  return null;
}

String _filterDomId(String objectUrl) {
  final hash = objectUrl.hashCode.toUnsigned(32).toRadixString(16);
  return 'cpvf_$hash';
}

String _ensureSvgFilter(String objectUrl, List<List<double>> matrices) {
  final filterId = _filterDomId(objectUrl);
  var host = html.document.getElementById(_svgHostId);
  if (host == null) {
    host = html.DivElement()
      ..id = _svgHostId
      ..style.position = 'absolute'
      ..style.width = '0'
      ..style.height = '0'
      ..style.overflow = 'hidden'
      ..style.pointerEvents = 'none';
    html.document.body?.append(host);
  }

  host.querySelector('#$filterId')?.remove();

  final matrixNodes = StringBuffer();
  for (final matrix in matrices) {
    if (matrix.length < 20) continue;
    matrixNodes.write(
      '<feColorMatrix type="matrix" values="${_svgMatrixValues(matrix)}"/>',
    );
  }

  final svg = html.Element.html(
    '<svg xmlns="http://www.w3.org/2000/svg" width="0" height="0">'
    '<filter id="$filterId" color-interpolation-filters="sRGB">'
    '$matrixNodes'
    '</filter>'
    '</svg>',
    treeSanitizer: html.NodeTreeSanitizer.trusted,
  );
  host.append(svg);
  return filterId;
}

/// Flutter color-matrix bias columns are 0–255; SVG feColorMatrix uses 0–1.
String _svgMatrixValues(List<double> m) {
  final parts = <String>[];
  for (var row = 0; row < 4; row++) {
    for (var col = 0; col < 5; col++) {
      final raw = m[row * 5 + col];
      final value = col == 4 ? raw / 255.0 : raw;
      parts.add(value.toStringAsFixed(6));
    }
  }
  return parts.join(' ');
}
