enum UserRole {
  user,
  admin,
  moderator,
}

class UserEntity {
  const UserEntity({
    required this.id,
    this.firebaseUid,
    required this.username,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.bio,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    required this.isVerified,
    this.instagramUrl,
    this.youtubeUrl,
    required this.isPrivate,
    required this.allowComments,
    required this.allowDirectMsgs,
    this.canPost = true,
    required this.language,
    required this.theme,
    this.country,
    this.region,
    this.city,
    required this.followerCount,
    required this.followingCount,
    required this.postCount,
    required this.totalLikes,
    required this.isBanned,
    this.banReason,
    this.bannedUntil,
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
    required this.roles,
  });

  final String id;
  final String? firebaseUid;
  final String username;

  final String? fullName;
  final String? email;
  final String? phoneNumber;

  final String? bio;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;

  final bool isVerified;

  final String? instagramUrl;
  final String? youtubeUrl;

  final bool isPrivate;
  final bool allowComments;
  final bool allowDirectMsgs;
  final bool canPost;
  final String language;
  final String theme;

  final String? country;
  final String? region;
  final String? city;

  final int followerCount;
  final int followingCount;
  final int postCount;
  final int totalLikes;

  final bool isBanned;
  final String? banReason;
  final DateTime? bannedUntil;

  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  final List<UserRole> roles;
}

class UsersPageEntity {
  final List<UserEntity> users;
  final int total;
  final int page;
  final int lastPage;

  const UsersPageEntity({
    required this.users,
    required this.total,
    required this.page,
    required this.lastPage,
  });
}