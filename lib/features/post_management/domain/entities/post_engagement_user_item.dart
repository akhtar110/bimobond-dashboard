class PostEngagementUserItem {
  const PostEngagementUserItem({
    required this.id,
    required this.userId,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.isVerified = false,
    this.isBanned = false,
    required this.createdAt,
    this.subtitle,
  });

  final String id;
  final String userId;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
  final bool isBanned;
  final DateTime createdAt;
  final String? subtitle;
}

class PostEngagementUsersPageEntity {
  const PostEngagementUsersPageEntity({
    required this.items,
    required this.page,
    required this.hasMore,
  });

  final List<PostEngagementUserItem> items;
  final int page;
  final bool hasMore;
}

enum PostEngagementKind { likes, views, mentions }
