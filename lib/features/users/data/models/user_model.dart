import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_last_location_entity.dart';
import '../../domain/entities/user_wallet_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    super.firebaseUid,
    required super.username,
    super.fullName,
    super.email,
    super.phoneNumber,
    super.bio,
    super.avatarUrl,
    super.gender,
    super.dateOfBirth,
    required super.isVerified,
    super.instagramUrl,
    super.youtubeUrl,
    super.websiteUrl,
    super.tiktokUrl,
    super.twitterUrl,
    super.snapchatUrl,
    super.spotifyUrl,
    super.pronouns,
    super.creatorCategory,
    super.accountType,
    super.verificationBadge,
    super.likedVideosVisibility,
    super.followersListVisibility,
    super.followingListVisibility,
    super.discoverable,
    super.suggestToContacts,
    super.profileViewHistoryEnabled,
    super.showActivityStatus,
    super.restrictedMode,
    super.showShopOnProfile,
    super.allowDuetsDefault,
    super.allowStitchDefault,
    super.allowDownloadsDefault,
    super.allowRepostsDefault,
    super.showRepostsOnProfile,
    required super.isPrivate,
    super.isProfileLocked,
    required super.allowComments,
    required super.allowDirectMsgs,
    super.messagePermission,
    super.canPost,
    required super.language,
    required super.theme,
    super.country,
    super.region,
    super.city,
    required super.followerCount,
    required super.followingCount,
    required super.postCount,
    required super.totalLikes,
    required super.isBanned,
    super.banReason,
    super.bannedUntil,
    super.fcmToken,
    super.createdAt,
    super.updatedAt,
    super.lastActive,
    super.isOnlineOverride,
    required super.roles,
    super.wallet,
    super.relationCounts,
    super.lastLocation,
  });

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? counts,
  }) {
    final resolvedCounts = counts ??
        (json['_count'] is Map
            ? Map<String, dynamic>.from(json['_count'] as Map)
            : json['counts'] is Map
                ? Map<String, dynamic>.from(json['counts'] as Map)
                : null);
    final relationCounts = UserRelationCountsEntity.tryParse(resolvedCounts);
    final wallet = UserWalletEntity.tryParse(json['wallet']);

    return UserModel(
      id: json['id'],
      firebaseUid: json['firebaseUid'],
      username: json['username'],
      fullName: json['fullName'],
      email: json['email'],
      phoneNumber: json['phoneNumber'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      gender: json['gender'],
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      isVerified: json['isVerified'] ?? false,
      instagramUrl: json['instagramUrl'],
      youtubeUrl: json['youtubeUrl'],
      websiteUrl: json['websiteUrl'],
      tiktokUrl: json['tiktokUrl'],
      twitterUrl: json['twitterUrl'],
      snapchatUrl: json['snapchatUrl'],
      spotifyUrl: json['spotifyUrl'],
      pronouns: json['pronouns'],
      creatorCategory: json['creatorCategory'],
      accountType: json['accountType']?.toString(),
      verificationBadge: json['verificationBadge']?.toString(),
      likedVideosVisibility: json['likedVideosVisibility']?.toString(),
      followersListVisibility: json['followersListVisibility']?.toString(),
      followingListVisibility: json['followingListVisibility']?.toString(),
      discoverable: json['discoverable'] as bool?,
      suggestToContacts: json['suggestToContacts'] as bool?,
      profileViewHistoryEnabled: json['profileViewHistoryEnabled'] as bool?,
      showActivityStatus: json['showActivityStatus'] as bool?,
      restrictedMode: json['restrictedMode'] as bool?,
      showShopOnProfile: json['showShopOnProfile'] as bool?,
      allowDuetsDefault: json['allowDuetsDefault'] as bool?,
      allowStitchDefault: json['allowStitchDefault'] as bool?,
      allowDownloadsDefault: json['allowDownloadsDefault'] as bool?,
      allowRepostsDefault: json['allowRepostsDefault'] as bool?,
      showRepostsOnProfile: json['showRepostsOnProfile'] as bool?,
      isPrivate: json['isPrivate'] ?? false,
      isProfileLocked: json['isProfileLocked'] ?? false,
      allowComments: json['allowComments'] ?? true,
      allowDirectMsgs: json['allowDirectMsgs'] ?? true,
      messagePermission: MessagePermissionX.fromApi(
        json['messagePermission']?.toString(),
        allowDirectMsgsFallback: json['allowDirectMsgs'] ?? true,
      ),
      canPost: json['canPost'] ?? !(json['isPostingBlocked'] as bool? ?? false),
      language: json['language'] ?? 'en',
      theme: json['theme'] ?? 'system',
      country: json['country'],
      region: json['region'],
      city: json['city'],
      followerCount: readInt(
            json['followerCount'] ??
                relationCounts?.followers ??
                resolvedCounts?['followers'] ??
                resolvedCounts?['follower']) ??
          0,
      followingCount: readInt(
            json['followingCount'] ??
                relationCounts?.following ??
                resolvedCounts?['following'] ??
                resolvedCounts?['followings']) ??
          0,
      postCount: readInt(
            json['postCount'] ??
                relationCounts?.posts ??
                resolvedCounts?['posts'] ??
                resolvedCounts?['post']) ??
          0,
      totalLikes: readInt(
            json['totalLikes'] ??
                json['likesCount'] ??
                json['likesReceived'] ??
                json['postLikes'] ??
                json['likes'] ??
                resolvedCounts?['postLikes'] ??
                resolvedCounts?['likesReceived'] ??
                resolvedCounts?['totalLikes'] ??
                resolvedCounts?['likes']) ??
          0,
      isBanned: json['isBanned'] ?? false,
      banReason: json['banReason'],
      bannedUntil: json['bannedUntil'] != null
          ? DateTime.tryParse(json['bannedUntil'].toString())
          : null,
      fcmToken: json['fcmToken'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      lastActive: (json['lastActive'] ?? json['lastSeen'] ?? json['lastActiveAt'] ?? json['lastSeenAt']) != null
          ? DateTime.tryParse((json['lastActive'] ?? json['lastSeen'] ?? json['lastActiveAt'] ?? json['lastSeenAt']).toString())
          : null,
      isOnlineOverride: json['isOnline'] is bool ? json['isOnline'] as bool : (json['online'] is bool ? json['online'] as bool : null),
      roles: json['roles'] is List
          ? (json['roles'] as List).map((e) => _mapRole(e.toString())).toList()
          : json['roles'] is Map
              ? (json['roles'] as Map).entries.map((entry) {
                  if (entry.value == true) {
                    return _mapRole(entry.key.toString());
                  }
                  return _mapRole(entry.value.toString());
                }).toList()
              : json['role'] != null
                  ? [_mapRole(json['role'].toString())]
                  : const [UserRole.user],
      wallet: wallet,
      relationCounts: relationCounts,
      lastLocation: UserLastLocationEntity.tryParse(json['lastLocation']),
    );
  }

  static int? readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  @override
  UserModel copyWith({
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
    return UserModel(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firebaseUid': firebaseUid,
      'username': username,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'bio': bio,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'isVerified': isVerified,
      'instagramUrl': instagramUrl,
      'youtubeUrl': youtubeUrl,
      'websiteUrl': websiteUrl,
      'tiktokUrl': tiktokUrl,
      'twitterUrl': twitterUrl,
      'snapchatUrl': snapchatUrl,
      'spotifyUrl': spotifyUrl,
      'pronouns': pronouns,
      'creatorCategory': creatorCategory,
      'accountType': accountType,
      'verificationBadge': verificationBadge,
      'likedVideosVisibility': likedVideosVisibility,
      'followersListVisibility': followersListVisibility,
      'followingListVisibility': followingListVisibility,
      'discoverable': discoverable,
      'suggestToContacts': suggestToContacts,
      'profileViewHistoryEnabled': profileViewHistoryEnabled,
      'showActivityStatus': showActivityStatus,
      'restrictedMode': restrictedMode,
      'showShopOnProfile': showShopOnProfile,
      'allowDuetsDefault': allowDuetsDefault,
      'allowStitchDefault': allowStitchDefault,
      'allowDownloadsDefault': allowDownloadsDefault,
      'allowRepostsDefault': allowRepostsDefault,
      'showRepostsOnProfile': showRepostsOnProfile,
      'isPrivate': isPrivate,
      'isProfileLocked': isProfileLocked,
      'allowComments': allowComments,
      'allowDirectMsgs': allowDirectMsgs,
      'messagePermission': messagePermission.apiValue,
      'canPost': canPost,
      'language': language,
      'theme': theme,
      'country': country,
      'region': region,
      'city': city,
      'followerCount': followerCount,
      'followingCount': followingCount,
      'postCount': postCount,
      'totalLikes': totalLikes,
      'isBanned': isBanned,
      'banReason': banReason,
      'bannedUntil': bannedUntil?.toIso8601String(),
      'fcmToken': fcmToken,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      // Legacy Role enum only — never emit SUPER_ADMIN.
      'roles': roles.map(_legacyRoleApiValue).toList(),
    };
  }

  /// Maps dashboard roles to the coarse `Role` enum (`USER`/`MODERATOR`/`ADMIN`).
  /// Legacy `ADMIN` maps to RBAC `admin` on the server — never `super_admin`.
  static String _legacyRoleApiValue(UserRole role) => switch (role) {
        UserRole.admin => 'ADMIN',
        // Legacy Role enum has no SUPER_ADMIN — coarsen for PATCH payloads.
        UserRole.superAdmin => 'ADMIN',
        UserRole.moderator => 'MODERATOR',
        UserRole.user => 'USER',
      };

  static UserRole _mapRole(String role) {
    switch (role.toUpperCase().replaceAll('-', '_')) {
      case 'ADMIN':
        return UserRole.admin;
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
        return UserRole.superAdmin;
      case 'MODERATOR':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }
}
