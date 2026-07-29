import 'message_permission.dart';
import 'user_last_location_entity.dart';
import 'user_wallet_entity.dart';

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
    this.websiteUrl,
    this.tiktokUrl,
    this.twitterUrl,
    this.snapchatUrl,
    this.spotifyUrl,
    this.pronouns,
    this.creatorCategory,
    this.accountType,
    this.verificationBadge,
    this.likedVideosVisibility,
    this.followersListVisibility,
    this.followingListVisibility,
    this.discoverable,
    this.suggestToContacts,
    this.profileViewHistoryEnabled,
    this.showActivityStatus,
    this.restrictedMode,
    this.showShopOnProfile,
    this.allowDuetsDefault,
    this.allowStitchDefault,
    this.allowDownloadsDefault,
    this.allowRepostsDefault,
    this.showRepostsOnProfile,
    required this.isPrivate,
    this.isProfileLocked = false,
    required this.allowComments,
    required this.allowDirectMsgs,
    this.messagePermission = MessagePermission.everyone,
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
    this.wallet,
    this.relationCounts,
    this.lastLocation,
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
  final String? websiteUrl;
  final String? tiktokUrl;
  final String? twitterUrl;
  final String? snapchatUrl;
  final String? spotifyUrl;
  final String? pronouns;
  final String? creatorCategory;
  final String? accountType;
  final String? verificationBadge;
  final String? likedVideosVisibility;
  final String? followersListVisibility;
  final String? followingListVisibility;
  final bool? discoverable;
  final bool? suggestToContacts;
  final bool? profileViewHistoryEnabled;
  final bool? showActivityStatus;
  final bool? restrictedMode;
  final bool? showShopOnProfile;
  final bool? allowDuetsDefault;
  final bool? allowStitchDefault;
  final bool? allowDownloadsDefault;
  final bool? allowRepostsDefault;
  final bool? showRepostsOnProfile;

  final bool isPrivate;
  final bool isProfileLocked;
  final bool allowComments;
  final bool allowDirectMsgs;
  final MessagePermission messagePermission;
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

  /// Nested wallet from list/detail payloads (may be null).
  final UserWalletEntity? wallet;

  /// Nested `_count` relations from list/detail payloads.
  final UserRelationCountsEntity? relationCounts;

  /// Latest GPS point from admin list/detail (`UserLocationHistory` or profile fallback).
  final UserLastLocationEntity? lastLocation;

  bool get isAdminRole => roles.contains(UserRole.admin);

  bool get isModeratorRole =>
      roles.contains(UserRole.moderator) && !isAdminRole;

  /// Standard / regular user (not admin and not moderator).
  bool get isStandardRole => !isAdminRole && !isModeratorRole;
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
