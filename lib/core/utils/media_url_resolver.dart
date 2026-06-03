/// Converts relative media paths returned by the API into absolute URLs.
///
/// The backend stores and returns relative paths like:
///   /uploads/media/files-1715694000000-123456789.mp4
///
/// These must be made absolute before passing to [CachedNetworkImage],
/// [Image.network], or [VideoPlayerController.networkUrl].
///
/// Usage:
///   1. Call [MediaUrlResolver.init] once during DI setup.
///   2. Use the top-level [resolveMediaUrl] helper everywhere else.
class MediaUrlResolver {
  MediaUrlResolver._();

  static String _baseUrl = '';

  /// Initialise with the API base URL (e.g. "http://192.168.1.123:3000").
  /// Must be called before any [resolve] / [resolveMediaUrl] call.
  static void init(String apiBaseUrl) {
    _baseUrl = apiBaseUrl.trimRight().replaceAll(RegExp(r'/+$'), '');
  }

  /// Returns an absolute URL for [url].
  ///
  /// Rules:
  ///  - `null` or whitespace-only          → `null`
  ///  - Already absolute (`http(s)://…`)   → returned unchanged
  ///  - Relative path starting with `/`    → prepended with [_baseUrl]
  ///  - Anything else                      → returned unchanged
  static String? resolve(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final t = url.trim();
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('/')) return '$_baseUrl$t';
    return t;
  }
}

/// Convenience top-level wrapper for [MediaUrlResolver.resolve].
String? resolveMediaUrl(String? url) => MediaUrlResolver.resolve(url);
