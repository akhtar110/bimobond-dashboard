class UserFollowSummaryEntity {
  const UserFollowSummaryEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.isVerified,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isVerified;
}

class UserFollowListPageEntity {
  const UserFollowListPageEntity({
    required this.users,
    required this.total,
    required this.page,
    required this.lastPage,
  });

  final List<UserFollowSummaryEntity> users;
  final int total;
  final int page;
  final int lastPage;

  bool get hasMore => page < lastPage;
}

enum UserFollowListKind { followers, following }
