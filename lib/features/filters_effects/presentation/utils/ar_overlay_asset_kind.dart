import 'dart:typed_data';

/// Detects whether an AR overlay animation asset is Lottie JSON or MP4 video.
///
/// Note: the upload pipeline historically disguises Lottie JSON as `.mp4` for
/// `/posts/upload` MIME checks, so URL extension alone is not reliable —
/// prefer magic-byte sniffing when bytes are available.
enum ArOverlayAssetKind { lottie, video }

bool arOverlayLooksLikeVideoName(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.m4v');
}

bool arOverlayLooksLikeJsonName(String? nameOrUrl) {
  if (nameOrUrl == null || nameOrUrl.isEmpty) return false;
  final lower = nameOrUrl.toLowerCase().split('?').first;
  return lower.endsWith('.json') || lower.endsWith('.lottie');
}

/// ISO BMFF / MP4: bytes[4..7] == 'ftyp'
bool arOverlayBytesLookLikeMp4(List<int> bytes) {
  if (bytes.length < 8) return false;
  return bytes[4] == 0x66 &&
      bytes[5] == 0x74 &&
      bytes[6] == 0x79 &&
      bytes[7] == 0x70;
}

bool arOverlayBytesLookLikeJson(List<int> bytes) {
  if (bytes.isEmpty) return false;
  var i = 0;
  if (bytes.length >= 3 &&
      bytes[0] == 0xEF &&
      bytes[1] == 0xBB &&
      bytes[2] == 0xBF) {
    i = 3;
  }
  while (i < bytes.length && i < 64) {
    final b = bytes[i];
    if (b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D) {
      i++;
      continue;
    }
    return b == 0x7B || b == 0x5B;
  }
  return false;
}

ArOverlayAssetKind? resolveArOverlayAssetKind({
  String? nameOrUrl,
  Uint8List? bytes,
}) {
  if (bytes != null && bytes.isNotEmpty) {
    if (arOverlayBytesLookLikeMp4(bytes)) return ArOverlayAssetKind.video;
    if (arOverlayBytesLookLikeJson(bytes)) return ArOverlayAssetKind.lottie;
  }

  if (arOverlayLooksLikeJsonName(nameOrUrl)) {
    return ArOverlayAssetKind.lottie;
  }

  // Extension-only `.mp4` is ambiguous (disguised JSON uploads). Prefer
  // treating unknown `.mp4` as video only when bytes were unavailable and the
  // name clearly indicates a video pick (not a disguised CDN JSON upload).
  // Callers with network-only URLs should sniff downloaded bytes instead.
  if (bytes == null || bytes.isEmpty) {
    return null;
  }

  if (arOverlayLooksLikeVideoName(nameOrUrl)) {
    return ArOverlayAssetKind.video;
  }

  return null;
}

bool arOverlayIsAcceptedAnimationAsset(String filename, Uint8List bytes) {
  final kind = resolveArOverlayAssetKind(nameOrUrl: filename, bytes: bytes);
  return kind == ArOverlayAssetKind.lottie || kind == ArOverlayAssetKind.video;
}
