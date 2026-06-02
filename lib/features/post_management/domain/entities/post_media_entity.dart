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
    return PostMediaEntity(
      id: json['id']?.toString(),
      url: json['url']?.toString() ?? '',
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
