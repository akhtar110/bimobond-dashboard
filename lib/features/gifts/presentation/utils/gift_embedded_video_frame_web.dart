import 'dart:html' as html;

/// Styles the HTML video element to fill the embedded frame (no letterbox gap).
void styleGiftEmbeddedVideo(String mediaUrl, {double borderRadius = 16}) {
  _apply(mediaUrl, borderRadius, attempt: 0);
}

void _apply(String mediaUrl, double borderRadius, {required int attempt}) {
  final video = _findVideo(mediaUrl);
  if (video == null) {
    if (attempt < 20) {
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        _apply(mediaUrl, borderRadius, attempt: attempt + 1);
      });
    }
    return;
  }

  video.style.setProperty('object-fit', 'cover');
  video.style.setProperty('object-position', 'center');
  video.style.setProperty('width', '100%');
  video.style.setProperty('height', '100%');
  video.style.setProperty('display', 'block');
  video.style.setProperty('margin', '0');
  video.style.setProperty('padding', '0');
  video.style.setProperty('border-radius', '${borderRadius}px');

  html.Element? parent = video.parent as html.Element?;
  var depth = 0;
  while (parent != null && depth < 6) {
    final el = parent!;
    el.style.setProperty('overflow', 'hidden');
    el.style.setProperty('border-radius', '${borderRadius}px');
    el.style.setProperty('width', '100%');
    el.style.setProperty('height', '100%');
    el.style.setProperty('margin', '0');
    el.style.setProperty('padding', '0');
    parent = el.parent as html.Element?;
    depth++;
  }
}

html.VideoElement? _findVideo(String mediaUrl) {
  final needle = mediaUrl.trim();
  if (needle.isEmpty) return null;

  for (final node in html.document.querySelectorAll('video')) {
    if (node is! html.VideoElement) continue;
    final src = node.currentSrc.isNotEmpty ? node.currentSrc : node.src;
    if (src.isEmpty) continue;
    if (src == needle ||
        src.contains(needle) ||
        needle.contains(src) ||
        src.endsWith(needle.split('?').first)) {
      return node;
    }
  }
  return null;
}
