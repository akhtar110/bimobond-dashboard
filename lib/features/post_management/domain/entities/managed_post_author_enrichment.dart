import '../../../../core/utils/media_url_resolver.dart';
import '../../../users/domain/entities/user_entity.dart';
import 'managed_post_entity.dart';

/// Partial author profile used to hydrate [ManagedPostEntity] author fields.
class ManagedPostAuthorSnapshot {
  const ManagedPostAuthorSnapshot({
    this.userId,
    this.userName,
    this.userFullName,
    this.userEmail,
    this.userProfileImage,
    this.userIsVerified,
    this.userFollowersCount,
    this.userFollowingCount,
    this.userPostsCount,
    this.userJoinedAt,
    this.userIsBanned,
  });

  final String? userId;
  final String? userName;
  final String? userFullName;
  final String? userEmail;
  final String? userProfileImage;
  final bool? userIsVerified;
  final int? userFollowersCount;
  final int? userFollowingCount;
  final int? userPostsCount;
  final DateTime? userJoinedAt;
  final bool? userIsBanned;

  factory ManagedPostAuthorSnapshot.fromUserEntity(UserEntity user) {
    return ManagedPostAuthorSnapshot(
      userId: user.id,
      userName: user.username,
      userFullName: user.fullName,
      userEmail: user.email,
      userProfileImage: user.avatarUrl,
      userIsVerified: user.isVerified,
      userFollowersCount: user.followerCount,
      userFollowingCount: user.followingCount,
      userPostsCount: user.postCount,
      userJoinedAt: user.createdAt,
      userIsBanned: user.isBanned,
    );
  }
}

/// Merges author fields from [fallback], [author], and [snapshot] into [primary].
/// Non-empty / non-zero values from [primary] win; gaps are filled from fallbacks.
ManagedPostEntity enrichManagedPostAuthor(
  ManagedPostEntity primary, {
  ManagedPostEntity? fallback,
  UserEntity? author,
  ManagedPostAuthorSnapshot? snapshot,
}) {
  final authorSnap =
      author != null ? ManagedPostAuthorSnapshot.fromUserEntity(author) : null;

  String pickId() => _pickNonEmpty(
        primary.userId,
        fallback?.userId,
        snapshot?.userId,
        authorSnap?.userId,
      );

  String? pickStr(String? a, String? b, String? c, String? d) =>
      _pickNullable(a, b, c, d);

  int pickCount(int a, int? b, int? c, int? d) {
    if (a > 0) return a;
    for (final v in [b, c, d]) {
      if (v != null && v > 0) return v;
    }
    return a;
  }

  bool pickVerified() {
    if (primary.userIsVerified) return true;
    if (fallback?.userIsVerified == true) return true;
    if (snapshot?.userIsVerified == true) return true;
    if (authorSnap?.userIsVerified == true) return true;
    return primary.userIsVerified;
  }

  bool pickBanned() {
    if (primary.userIsBanned) return true;
    if (fallback?.userIsBanned == true) return true;
    if (snapshot?.userIsBanned == true) return true;
    if (authorSnap?.userIsBanned == true) return true;
    return primary.userIsBanned;
  }

  DateTime? pickDate(DateTime? a, DateTime? b, DateTime? c, DateTime? d) =>
      a ?? b ?? c ?? d;

  final userId = pickId();

  return enrichManagedPostContent(
    primary.copyWith(
    userId: userId.isNotEmpty ? userId : primary.userId,
    userName: pickStr(
      primary.userName,
      fallback?.userName,
      snapshot?.userName,
      authorSnap?.userName,
    ),
    userFullName: pickStr(
      primary.userFullName,
      fallback?.userFullName,
      snapshot?.userFullName,
      authorSnap?.userFullName,
    ),
    userEmail: pickStr(
      primary.userEmail,
      fallback?.userEmail,
      snapshot?.userEmail,
      authorSnap?.userEmail,
    ),
    userProfileImage: pickStr(
      primary.userProfileImage,
      fallback?.userProfileImage,
      snapshot?.userProfileImage,
      authorSnap?.userProfileImage,
    ),
    userIsVerified: pickVerified(),
    userFollowersCount: pickCount(
      primary.userFollowersCount,
      fallback?.userFollowersCount,
      snapshot?.userFollowersCount,
      authorSnap?.userFollowersCount,
    ),
    userFollowingCount: pickCount(
      primary.userFollowingCount,
      fallback?.userFollowingCount,
      snapshot?.userFollowingCount,
      authorSnap?.userFollowingCount,
    ),
    userPostsCount: pickCount(
      primary.userPostsCount,
      fallback?.userPostsCount,
      snapshot?.userPostsCount,
      authorSnap?.userPostsCount,
    ),
    userJoinedAt: pickDate(
      primary.userJoinedAt,
      fallback?.userJoinedAt,
      snapshot?.userJoinedAt,
      authorSnap?.userJoinedAt,
    ),
    userIsBanned: pickBanned(),
    ),
    fallback: fallback,
  );
}

/// Immutable copy of a feed row captured before opening post management.
ManagedPostEntity snapshotPostListBaseline(ManagedPostEntity post) {
  return hydrateManagedPostMedia(
    post.copyWith(media: List<PostMediaEntity>.from(post.media)),
  );
}

/// Normalizes legacy/relative media URL fields before detail navigation.
ManagedPostEntity normalizeManagedPostMediaFields(ManagedPostEntity post) {
  final media = post.media
      .map(
        (item) => PostMediaEntity(
          id: item.id,
          url: resolveMediaUrl(item.url) ?? item.url,
          mediaType: item.mediaType,
          order: item.order,
        ).normalized(),
      )
      .toList(growable: false);

  return post.copyWith(
    videoUrl: resolveMediaUrl(post.videoUrl),
    hlsUrl: resolveMediaUrl(post.hlsUrl),
    thumbnailUrl: resolveMediaUrl(post.thumbnailUrl),
    animatedCoverUrl: resolveMediaUrl(post.animatedCoverUrl),
    media: media,
  );
}

/// Same hydration pipeline used by [PostsPage] before opening post management.
ManagedPostEntity prepareManagedPostForDetailNavigation(
  ManagedPostEntity post, {
  UserEntity? sourceUser,
}) {
  var prepared = normalizeManagedPostMediaFields(post);
  if (sourceUser != null &&
      (prepared.userId.isEmpty || prepared.userId == sourceUser.id)) {
    prepared = enrichManagedPostAuthor(prepared, author: sourceUser);
  }
  return snapshotPostListBaseline(hydrateManagedPostMedia(prepared));
}

/// Keeps list/card thumbnails when a detail or PATCH payload omits media URLs.
ManagedPostEntity mergeManagedPostForListDisplay(
  ManagedPostEntity existing,
  ManagedPostEntity incoming,
) {
  return hydrateManagedPostMedia(
    enrichManagedPostContent(incoming, fallback: existing),
  );
}

/// Combines carousel items so feed-only IMAGE entries survive detail payloads
/// that only include playable VIDEO items.
List<PostMediaEntity> mergePostMediaLists(
  List<PostMediaEntity> primary,
  List<PostMediaEntity> fallback,
) {
  final items = <PostMediaEntity>[];
  final seenUrls = <String>{};

  void add(PostMediaEntity item) {
    final normalized = item.normalized();
    if (normalized.url.isEmpty || seenUrls.contains(normalized.url)) return;
    seenUrls.add(normalized.url);
    items.add(normalized);
  }

  for (final item in primary) {
    add(item);
  }

  for (final item in fallback) {
    if (!item.isVideo) {
      add(item);
    }
  }

  if (items.isEmpty) {
    for (final item in fallback) {
      add(item);
    }
  }

  items.sort((a, b) => a.order.compareTo(b.order));
  return items;
}

/// Normalizes carousel items and fills gaps from legacy URL fields.
ManagedPostEntity hydrateManagedPostMedia(ManagedPostEntity post) {
  final items = <PostMediaEntity>[];
  final seenUrls = <String>{};

  void addItem(PostMediaEntity item) {
    final normalized = item.normalized();
    if (normalized.url.isEmpty || seenUrls.contains(normalized.url)) return;
    seenUrls.add(normalized.url);
    items.add(normalized);
  }

  for (final item in post.media) {
    addItem(item);
  }

  final video = post.videoUrl?.trim();
  final hls = post.hlsUrl?.trim();
  final thumb = post.thumbnailUrl?.trim();
  final animated = post.animatedCoverUrl?.trim();

  final hasPlayableVideo = items.any((item) => item.isVideo);
  if (!hasPlayableVideo) {
    if (video != null && video.isNotEmpty) {
      addItem(PostMediaEntity(url: video, mediaType: 'VIDEO'));
    } else if (hls != null && hls.isNotEmpty) {
      addItem(PostMediaEntity(url: hls, mediaType: 'VIDEO'));
    }
  }

  if (items.isEmpty) {
    final imageUrl = (thumb != null && thumb.isNotEmpty)
        ? thumb
        : (animated != null && animated.isNotEmpty ? animated : null);
    if (imageUrl != null) {
      addItem(PostMediaEntity(url: imageUrl, mediaType: 'IMAGE'));
    }
  } else if (thumb != null &&
      thumb.isNotEmpty &&
      !seenUrls.contains(thumb) &&
      !isLikelyVideoFileUrl(thumb)) {
    final hasImage = items.any((item) => !item.isVideo);
    final isVideoPost = post.type.toUpperCase() == 'VIDEO';
    if (!hasImage && !isVideoPost) {
      addItem(PostMediaEntity(url: thumb, mediaType: 'IMAGE', order: -1));
      items.sort((a, b) => a.order.compareTo(b.order));
    }
  }

  final playbackMedia = _mediaForDetailPlayback(items, post);
  if (playbackMedia.isEmpty) return post;
  return post.copyWith(media: playbackMedia);
}

/// Detail/playback carousel: video posts show the player only — not [thumbnailUrl].
List<PostMediaEntity> _mediaForDetailPlayback(
  List<PostMediaEntity> items,
  ManagedPostEntity post,
) {
  if (items.isEmpty) return items;
  if (!items.any((item) => item.isVideo)) return items;

  final thumb = post.thumbnailUrl?.trim();
  final animated = post.animatedCoverUrl?.trim();
  final isVideoPost = post.type.toUpperCase() == 'VIDEO';
  final onlyVideos = items.every((item) => item.isVideo);

  if (isVideoPost || onlyVideos) {
    return items.where((item) => item.isVideo).toList(growable: false);
  }

  return items.where((item) {
    if (item.isVideo) return true;
    final url = item.url.trim();
    if (thumb != null && thumb.isNotEmpty && url == thumb) return false;
    if (animated != null && animated.isNotEmpty && url == animated) {
      return false;
    }
    return true;
  }).toList(growable: false);
}

CategoryEntity? _mergeCategoryEntity(
  CategoryEntity? primary,
  CategoryEntity? fallback,
  String? categoryName,
) {
  if (primary != null && primary.id.isNotEmpty) {
    if (primary.name.trim().isNotEmpty) return primary;
    final name = fallback?.name.trim().isNotEmpty == true
        ? fallback!.name
        : categoryName?.trim();
    if (name != null && name.isNotEmpty) {
      return CategoryEntity(
        id: primary.id,
        name: name,
        slug: primary.slug,
        description: primary.description,
        iconUrl: primary.iconUrl,
        isActive: primary.isActive,
        order: primary.order,
        createdAt: primary.createdAt,
        updatedAt: primary.updatedAt,
        parentId: primary.parentId,
        children: primary.children,
      );
    }
    return primary;
  }

  if (fallback != null && fallback.id.isNotEmpty) return fallback;
  if (categoryName != null && categoryName.trim().isNotEmpty) {
    return CategoryEntity(
      id: '',
      name: categoryName.trim(),
      slug: '',
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
  return null;
}

/// Keeps caption, category, and media from [fallback] when the primary payload omits them.
ManagedPostEntity enrichManagedPostContent(
  ManagedPostEntity primary, {
  ManagedPostEntity? fallback,
}) {
  if (fallback == null) return hydrateManagedPostMedia(primary);

  final description = _pickNonEmptyStr(primary.description, fallback.description);
  final category = _pickNonEmptyStr(primary.category, fallback.category);
  final categoryEntity = _mergeCategoryEntity(
    primary.categoryEntity,
    fallback.categoryEntity,
    category,
  );
  final videoUrl = _pickNonEmptyStr(primary.videoUrl, fallback.videoUrl);
  final hlsUrl = _pickNonEmptyStr(primary.hlsUrl, fallback.hlsUrl);
  final media = mergePostMediaLists(primary.media, fallback.media);
  final thumbnailExclude = <String>[
    if (videoUrl != null) videoUrl,
    if (hlsUrl != null) hlsUrl,
    for (final item in media)
      if (item.isVideo) item.url,
  ];
  final thumbnailUrl = _pickBestThumbnailUrl(
    primary.thumbnailUrl,
    fallback.thumbnailUrl,
    excludeUrls: thumbnailExclude,
  );
  final animatedCoverUrl = _pickBestThumbnailUrl(
    primary.animatedCoverUrl,
    fallback.animatedCoverUrl,
    excludeUrls: thumbnailExclude,
  );
  final type = _pickNonEmptyStr(primary.type, fallback.type) ?? primary.type;

  if (description == primary.description &&
      category == primary.category &&
      categoryEntity == primary.categoryEntity &&
      videoUrl == primary.videoUrl &&
      hlsUrl == primary.hlsUrl &&
      thumbnailUrl == primary.thumbnailUrl &&
      animatedCoverUrl == primary.animatedCoverUrl &&
      media == primary.media &&
      type == primary.type) {
    return hydrateManagedPostMedia(primary);
  }

  return hydrateManagedPostMedia(
    primary.copyWith(
      description: description,
      category: category,
      categoryEntity: categoryEntity,
      videoUrl: videoUrl,
      hlsUrl: hlsUrl,
      thumbnailUrl: thumbnailUrl,
      animatedCoverUrl: animatedCoverUrl,
      media: media,
      type: type,
    ),
  );
}

String? _pickNonEmptyStr(String? primary, String? fallback) {
  if (primary != null && primary.trim().isNotEmpty) return primary;
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  return primary ?? fallback;
}

/// Prefers a still-image URL; never lets a playable video URL win over a feed thumbnail.
String? _pickBestThumbnailUrl(
  String? primary,
  String? fallback, {
  Iterable<String> excludeUrls = const [],
}) {
  for (final candidate in [primary, fallback]) {
    if (isUsablePostThumbnailUrl(candidate, excludeUrls: excludeUrls)) {
      return candidate!.trim();
    }
  }
  return _pickNonEmptyStr(primary, fallback);
}

String _pickNonEmpty(String? a, String? b, String? c, String? d) {
  for (final v in [a, b, c, d]) {
    if (v != null && v.isNotEmpty) return v;
  }
  return '';
}

String? _pickNullable(String? a, String? b, String? c, String? d) {
  for (final v in [a, b, c, d]) {
    if (v != null && v.isNotEmpty) return v;
  }
  return null;
}

/// Minimal post shell for navigation when only an id is known.
ManagedPostEntity managedPostSeed(
  String postId, {
  UserEntity? author,
  ManagedPostAuthorSnapshot? authorSnapshot,
}) {
  final now = DateTime.now();
  final base = ManagedPostEntity(
    id: postId,
    userId: author?.id ?? authorSnapshot?.userId ?? '',
    type: 'VIDEO',
    status: 'PUBLISHED',
    viewCount: 0,
    shareCount: 0,
    downloadCount: 0,
    likeCount: 0,
    commentCount: 0,
    saveCount: 0,
    isAd: false,
    privacyStatus: 'PUBLIC',
    allowComments: true,
    allowDuets: true,
    allowStitch: true,
    isStory: false,
    isAuctionable: false,
    createdAt: now,
    updatedAt: now,
  );
  return hydrateManagedPostMedia(
    enrichManagedPostAuthor(
      base,
      author: author,
      snapshot: authorSnapshot,
    ),
  );
}
