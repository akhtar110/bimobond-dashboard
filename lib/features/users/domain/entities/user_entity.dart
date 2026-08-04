import 'package:intl/intl.dart';

import 'message_permission.dart';
import 'user_last_location_entity.dart';
import 'user_wallet_entity.dart';

enum UserRole {
  user,
  admin,
  moderator,
  superAdmin,
}

extension UserRolesX on Iterable<UserRole> {
  /// Admin or Super Admin (legacy dashboard staff).
  bool get includesAdmin =>
      any((r) => r == UserRole.admin || r == UserRole.superAdmin);

  bool get includesModerator => any((r) => r == UserRole.moderator);

  bool get includesStaff => includesAdmin || includesModerator;
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
    this.lastActive,
    this.isOnlineOverride,
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
  final DateTime? lastActive;
  final bool? isOnlineOverride;

  DateTime? get lastSeen => lastActive ?? updatedAt ?? createdAt;

  bool get isOnline => isOnlineOverride ?? false;

  String get lastSeenFormatted {
    if (lastSeen == null) return '—';
    final diff = DateTime.now().difference(lastSeen!);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 2) return 'Yesterday';
    return DateFormat('MMM d, yyyy').format(lastSeen!);
  }

  final List<UserRole> roles;

  /// Nested wallet from list/detail payloads (may be null).
  final UserWalletEntity? wallet;

  /// Nested `_count` relations from list/detail payloads.
  final UserRelationCountsEntity? relationCounts;

  /// Latest GPS point from admin list/detail (`UserLocationHistory` or profile fallback).
  final UserLastLocationEntity? lastLocation;

  bool get isAdminRole => roles.includesAdmin;

  bool get isModeratorRole =>
      roles.includesModerator && !isAdminRole;

  /// Standard / regular user (not admin and not moderator).
  bool get isStandardRole => !isAdminRole && !isModeratorRole;

  UserEntity copyWith({
    String? id,
    String? firebaseUid,
    String? username,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    bool? isVerified,
    String? instagramUrl,
    String? youtubeUrl,
    String? websiteUrl,
    String? tiktokUrl,
    String? twitterUrl,
    String? snapchatUrl,
    String? spotifyUrl,
    String? pronouns,
    String? creatorCategory,
    String? accountType,
    String? verificationBadge,
    String? likedVideosVisibility,
    String? followersListVisibility,
    String? followingListVisibility,
    bool? discoverable,
    bool? suggestToContacts,
    bool? profileViewHistoryEnabled,
    bool? showActivityStatus,
    bool? restrictedMode,
    bool? showShopOnProfile,
    bool? allowDuetsDefault,
    bool? allowStitchDefault,
    bool? allowDownloadsDefault,
    bool? allowRepostsDefault,
    bool? showRepostsOnProfile,
    bool? isPrivate,
    bool? isProfileLocked,
    bool? allowComments,
    bool? allowDirectMsgs,
    MessagePermission? messagePermission,
    bool? canPost,
    String? language,
    String? theme,
    String? country,
    String? region,
    String? city,
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? totalLikes,
    bool? isBanned,
    String? banReason,
    DateTime? bannedUntil,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastActive,
    bool? isOnlineOverride,
    List<UserRole>? roles,
    UserWalletEntity? wallet,
    UserRelationCountsEntity? relationCounts,
    UserLastLocationEntity? lastLocation,
  }) {
    return UserEntity(
      id: id ?? this.id,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      isVerified: isVerified ?? this.isVerified,
      instagramUrl: instagramUrl ?? this.instagramUrl,
      youtubeUrl: youtubeUrl ?? this.youtubeUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      tiktokUrl: tiktokUrl ?? this.tiktokUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      snapchatUrl: snapchatUrl ?? this.snapchatUrl,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
      pronouns: pronouns ?? this.pronouns,
      creatorCategory: creatorCategory ?? this.creatorCategory,
      accountType: accountType ?? this.accountType,
      verificationBadge: verificationBadge ?? this.verificationBadge,
      likedVideosVisibility: likedVideosVisibility ?? this.likedVideosVisibility,
      followersListVisibility: followersListVisibility ?? this.followersListVisibility,
      followingListVisibility: followingListVisibility ?? this.followingListVisibility,
      discoverable: discoverable ?? this.discoverable,
      suggestToContacts: suggestToContacts ?? this.suggestToContacts,
      profileViewHistoryEnabled: profileViewHistoryEnabled ?? this.profileViewHistoryEnabled,
      showActivityStatus: showActivityStatus ?? this.showActivityStatus,
      restrictedMode: restrictedMode ?? this.restrictedMode,
      showShopOnProfile: showShopOnProfile ?? this.showShopOnProfile,
      allowDuetsDefault: allowDuetsDefault ?? this.allowDuetsDefault,
      allowStitchDefault: allowStitchDefault ?? this.allowStitchDefault,
      allowDownloadsDefault: allowDownloadsDefault ?? this.allowDownloadsDefault,
      allowRepostsDefault: allowRepostsDefault ?? this.allowRepostsDefault,
      showRepostsOnProfile: showRepostsOnProfile ?? this.showRepostsOnProfile,
      isPrivate: isPrivate ?? this.isPrivate,
      isProfileLocked: isProfileLocked ?? this.isProfileLocked,
      allowComments: allowComments ?? this.allowComments,
      allowDirectMsgs: allowDirectMsgs ?? this.allowDirectMsgs,
      messagePermission: messagePermission ?? this.messagePermission,
      canPost: canPost ?? this.canPost,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      totalLikes: totalLikes ?? this.totalLikes,
      isBanned: isBanned ?? this.isBanned,
      banReason: banReason ?? this.banReason,
      bannedUntil: bannedUntil ?? this.bannedUntil,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastActive: lastActive ?? this.lastActive,
      isOnlineOverride: isOnlineOverride ?? this.isOnlineOverride,
      roles: roles ?? this.roles,
      wallet: wallet ?? this.wallet,
      relationCounts: relationCounts ?? this.relationCounts,
      lastLocation: lastLocation ?? this.lastLocation,
    );
  }
}

class UsersPageEntity {
  final List<UserEntity> users;
  final int total;
  final int page;
  final int lastPage;
  final int onlineCount;

  const UsersPageEntity({
    required this.users,
    required this.total,
    required this.page,
    required this.lastPage,
    this.onlineCount = 0,
  });
}
