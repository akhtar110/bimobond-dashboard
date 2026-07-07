import '../../../../core/utils/media_url_resolver.dart';

class PostMediaEntity {
  const PostMediaEntity({
    required this.url,
    required this.mediaType,
    this.order = 0,
    this.id,
  });

  final String url;
  final String mediaType;
  final int order;
  final String? id;

  /// Resolved type after URL/extension inspection (handles mislabeled API data).
  String get effectiveMediaType {
    final normalized = mediaType.trim().toUpperCase();
    if (normalized == 'VIDEO' || normalized == 'AUDIO') return 'VIDEO';
    if (isLikelyVideoFileUrl(url)) return 'VIDEO';
    return 'IMAGE';
  }

  bool get isVideo => effectiveMediaType == 'VIDEO';

  PostMediaEntity normalized() {
    return PostMediaEntity(
      id: id,
      url: url,
      mediaType: effectiveMediaType,
      order: order,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostMediaEntity &&
        other.url == url &&
        other.mediaType == mediaType &&
        other.order == order &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(url, mediaType, order, id);

  factory PostMediaEntity.fromJson(Map<String, dynamic> json) {
    final rawUrl = _readUrl(json);
    final resolvedUrl = resolveMediaUrl(rawUrl) ?? rawUrl;
    final rawType = json['mediaType']?.toString() ??
        json['type']?.toString() ??
        'IMAGE';

    final entity = PostMediaEntity(
      id: json['id']?.toString(),
      url: resolvedUrl,
      mediaType: rawType,
      order: _readInt(json['order']) ?? 0,
    );
    return entity.normalized();
  }

  static String _readUrl(Map<String, dynamic> json) {
    for (final key in ['url', 'mediaUrl', 'src', 'path', 'fileUrl']) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return '';
  }

  static List<PostMediaEntity> listFromJson(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];

    final items = <PostMediaEntity>[];
    for (final entry in raw) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final parsed = PostMediaEntity.fromJson(map);
      if (parsed.url.isEmpty) continue;
      items.add(parsed);
    }

    items.sort((a, b) => a.order.compareTo(b.order));
    return items;
  }

  static int? _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Whether [url] is safe to show as a list/card still image (not a playable video).
bool isUsablePostThumbnailUrl(
  String? url, {
  Iterable<String> excludeUrls = const [],
}) {
  final trimmed = url?.trim();
  if (trimmed == null || trimmed.isEmpty) return false;
  if (isLikelyVideoFileUrl(trimmed)) return false;
  for (final exclude in excludeUrls) {
    final excluded = exclude.trim();
    if (excluded.isNotEmpty && excluded == trimmed) return false;
  }
  return true;
}

/// Resolves the admin preview thumbnail: first IMAGE in [media], else [thumbnailUrl].
String? resolvePostDisplayThumbnailUrl({
  required List<PostMediaEntity> media,
  String? thumbnailUrl,
  Iterable<String> excludeUrls = const [],
}) {
  for (final item in media) {
    if (!item.isVideo &&
        isUsablePostThumbnailUrl(item.url, excludeUrls: excludeUrls)) {
      return item.url;
    }
  }

  if (isUsablePostThumbnailUrl(thumbnailUrl, excludeUrls: excludeUrls)) {
    return thumbnailUrl!.trim();
  }

  return null;
}

bool isLikelyVideoFileUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.webm') ||
      path.endsWith('.mov') ||
      path.endsWith('.m3u8') ||
      path.endsWith('.mkv');
}
