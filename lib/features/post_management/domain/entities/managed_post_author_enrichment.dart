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

/// Keeps caption/category from [fallback] when the primary payload omits them.
ManagedPostEntity enrichManagedPostContent(
  ManagedPostEntity primary, {
  ManagedPostEntity? fallback,
}) {
  if (fallback == null) return primary;

  final description = _pickNonEmptyStr(primary.description, fallback.description);
  final category = _pickNonEmptyStr(primary.category, fallback.category);
  final categoryEntity = primary.categoryEntity ?? fallback.categoryEntity;

  if (description == primary.description &&
      category == primary.category &&
      categoryEntity == primary.categoryEntity) {
    return primary;
  }

  return primary.copyWith(
    description: description,
    category: category,
    categoryEntity: categoryEntity,
  );
}

String? _pickNonEmptyStr(String? primary, String? fallback) {
  if (primary != null && primary.trim().isNotEmpty) return primary;
  if (fallback != null && fallback.trim().isNotEmpty) return fallback;
  return primary ?? fallback;
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
  return enrichManagedPostAuthor(
    base,
    author: author,
    snapshot: authorSnapshot,
  );
}
