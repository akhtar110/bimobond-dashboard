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

  factory PostMediaEntity.fromJson(Map<String, dynamic> json) {
    // Resolve relative paths returned by the API (e.g. /uploads/media/…) to
    // absolute URLs so CachedNetworkImage / VideoPlayerController can load them.
    final rawUrl = json['url']?.toString() ?? '';
    final resolvedUrl = resolveMediaUrl(rawUrl) ?? rawUrl;

    return PostMediaEntity(
      id: json['id']?.toString(),
      url: resolvedUrl,
      mediaType: json['mediaType']?.toString() ?? 'IMAGE',
      order: _readInt(json['order']) ?? 0,
    );
  }

  static List<PostMediaEntity> listFromJson(dynamic raw) {
    if (raw is! List || raw.isEmpty) return const [];

    final items = <PostMediaEntity>[];
    for (final entry in raw) {
      if (entry is! Map<String, dynamic>) continue;
      final parsed = PostMediaEntity.fromJson(entry);
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

/// Resolves the admin preview thumbnail: first IMAGE in [media], else [thumbnailUrl].
String? resolvePostDisplayThumbnailUrl({
  required List<PostMediaEntity> media,
  String? thumbnailUrl,
}) {
  for (final item in media) {
    if (item.mediaType.toUpperCase() == 'IMAGE' && item.url.isNotEmpty) {
      return item.url;
    }
  }

  if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
    return thumbnailUrl;
  }

  return null;
}

bool isLikelyVideoFileUrl(String url) {
  final path = Uri.tryParse(url)?.path.toLowerCase() ?? url.toLowerCase();
  return path.endsWith('.mp4') ||
      path.endsWith('.webm') ||
      path.endsWith('.mov') ||
      path.endsWith('.m3u8');
}
