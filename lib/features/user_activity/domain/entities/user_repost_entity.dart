import '../../../users/domain/entities/user_post_entity.dart';

/// A user in the `repostedBy` field of a unified feed repost item.
class RepostedByEntity {
  const RepostedByEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.isVerified,
    this.repostedAt,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;

  /// Populated when returned inside `post.recentReposters`.
  final DateTime? repostedAt;
}

/// One item from the unified feed where `feedType == "REPOST"`.
class UserRepostEntity {
  const UserRepostEntity({
    this.repostId,
    this.repostedAt,
    this.quote,
    this.repostedBy,
    required this.post,
    this.sortAt,
  });

  final String? repostId;
  final DateTime? repostedAt;

  /// Optional caption the reposter added.
  final String? quote;
  final RepostedByEntity? repostedBy;

  /// The underlying original post.
  final UserPostEntity post;

  /// Ordering timestamp from the feed (`sortAt`).
  final DateTime? sortAt;
}
