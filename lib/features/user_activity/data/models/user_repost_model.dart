import '../../../../core/utils/media_url_resolver.dart';
import '../../../users/data/models/user_post_model.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../../domain/entities/user_repost_entity.dart';

class RepostedByModel extends RepostedByEntity {
  const RepostedByModel({
    required super.id,
    required super.username,
    super.fullName,
    super.avatarUrl,
    required super.isVerified,
    super.repostedAt,
  });

  factory RepostedByModel.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ??
        json['_id']?.toString() ??
        json['userId']?.toString() ??
        '';
    final username = json['username']?.toString() ??
        json['userName']?.toString() ??
        '';
    return RepostedByModel(
      id: id,
      username: username,
      fullName: json['fullName']?.toString() ??
          json['name']?.toString() ??
          json['displayName']?.toString(),
      avatarUrl: resolveMediaUrl(
        json['avatarUrl']?.toString() ??
            json['profileImage']?.toString() ??
            json['userProfileImage']?.toString(),
      ),
      isVerified: json['isVerified'] as bool? ?? false,
      repostedAt: _parseDate(json['repostedAt']),
    );
  }
}

class UserRepostModel extends UserRepostEntity {
  const UserRepostModel({
    super.repostId,
    super.repostedAt,
    super.quote,
    super.repostedBy,
    required super.post,
    super.sortAt,
  });

  /// Parse one item from `GET /users/:id/reposts`.
  ///
  /// Response shape (README 16):
  /// ```json
  /// {
  ///   "id": "repost-uuid",
  ///   "userId": "user-uuid",
  ///   "postId": "post-uuid",
  ///   "quote": "Must watch!",
  ///   "createdAt": "2026-06-03T14:00:00.000Z",
  ///   "post": { ... },
  ///   "user": { ... }   // optional – the reposter's profile
  /// }
  /// ```
  factory UserRepostModel.fromApiItem(Map<String, dynamic> json) {
    final postJson = json['post'] as Map<String, dynamic>? ?? {};
    final userJson = json['user'] ??
        json['repostedBy'] ??
        json['reposter'];

    RepostedByEntity? repostedBy;
    if (userJson is Map<String, dynamic>) {
      repostedBy = RepostedByModel.fromJson(userJson);
    } else if (json['userId'] != null) {
      repostedBy = RepostedByModel(
        id: json['userId'].toString(),
        username: '',
        isVerified: false,
      );
    }

    final repostedAt = _parseDate(json['createdAt']);

    return UserRepostModel(
      repostId: json['id']?.toString(),
      repostedAt: repostedAt,
      quote: json['quote']?.toString(),
      repostedBy: repostedBy,
      post: UserPostModel.fromJson(postJson),
      sortAt: repostedAt,
    );
  }

  /// Builds a repost entity from a unified activity feed item (`type: REPOST`).
  factory UserRepostModel.fromActivityItem(
    UserActivityItemEntity item, {
    UserEntity? sourceUser,
  }) {
    final postId = item.detailString('postId') ?? '';
    final now = DateTime.now();

    RepostedByEntity? repostedBy;
    if (sourceUser != null) {
      repostedBy = RepostedByModel(
        id: sourceUser.id,
        username: sourceUser.username,
        fullName: sourceUser.fullName,
        avatarUrl: sourceUser.avatarUrl,
        isVerified: sourceUser.isVerified,
        repostedAt: item.createdAt,
      );
    }

    final postJson = item.details['post'];
    final post = postJson is Map<String, dynamic>
        ? UserPostModel.fromJson(postJson)
        : UserPostModel(
            id: postId,
            userId: sourceUser?.id ?? '',
            type: 'VIDEO',
            description: item.detailString('postDescription'),
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

    return UserRepostModel(
      repostId: item.id,
      repostedAt: item.createdAt,
      quote: item.detailString('quote'),
      repostedBy: repostedBy,
      post: post,
      sortAt: item.createdAt,
    );
  }
}

/// Parses the response from `GET /users/:id/reposts`.
///
/// ```json
/// { "reposts": [...], "meta": { "total", "page", "lastPage" } }
/// ```
class UserRepostFeedResponse {
  const UserRepostFeedResponse({
    required this.reposts,
    required this.page,
    required this.lastPage,
    required this.total,
  });

  final List<UserRepostEntity> reposts;
  final int page;
  final int lastPage;
  final int total;

  factory UserRepostFeedResponse.fromJson(Map<String, dynamic> json) {
    // The API returns the list under the "reposts" key.
    final rawList = json['reposts'] as List? ?? [];
    final meta = json['meta'] as Map<String, dynamic>? ?? {};

    final reposts = rawList
        .whereType<Map<String, dynamic>>()
        .map((e) => UserRepostModel.fromApiItem(e))
        .toList();

    return UserRepostFeedResponse(
      reposts: reposts,
      page: _int(meta['page']) ?? 1,
      lastPage: _int(meta['lastPage']) ?? 1,
      total: _int(meta['total']) ?? reposts.length,
    );
  }

  PaginatedPage<UserRepostEntity> toPaginatedPage() => PaginatedPage(
        items: reposts,
        page: page,
        lastPage: lastPage,
        total: total,
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

int? _int(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
