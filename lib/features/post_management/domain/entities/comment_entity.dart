class CommentEntity {
  const CommentEntity({
    required this.id,
    required this.content,
    required this.postId,
    required this.userId,
    this.parentId,
    required this.likeCount,
    required this.replyCount,
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });

  final String id;
  final String content;
  final String postId;
  final String userId;
  final String? parentId;
  final int likeCount;
  final int replyCount;
  final DateTime createdAt;
  final String? username;
  final String? avatarUrl;

  String get displayName => username ?? userId;
}

class PostCommentsPageEntity {
  const PostCommentsPageEntity({
    required this.comments,
    required this.page,
    required this.hasMore,
  });

  final List<CommentEntity> comments;
  final int page;
  final bool hasMore;
}
