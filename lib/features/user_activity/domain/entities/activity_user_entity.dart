class ActivityUserEntity {
  const ActivityUserEntity({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.email,
    this.isVerified = false,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.createdAt,
    this.isBanned = false,
  });

  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? email;
  final bool isVerified;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final DateTime? createdAt;
  final bool isBanned;

  String get displayName {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    return username;
  }
}
