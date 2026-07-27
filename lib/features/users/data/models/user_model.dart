import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_entity.dart';

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
    required super.roles,
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
          ? DateTime.parse(json['dateOfBirth'])
          : null,
      isVerified: json['isVerified'] ?? false,
      instagramUrl: json['instagramUrl'],
      youtubeUrl: json['youtubeUrl'],
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
                resolvedCounts?['followers'] ??
                resolvedCounts?['follower']) ??
          0,
      followingCount: readInt(
            json['followingCount'] ??
                resolvedCounts?['following'] ??
                resolvedCounts?['followings']) ??
          0,
      postCount: readInt(
            json['postCount'] ??
                resolvedCounts?['posts'] ??
                resolvedCounts?['post']) ??
          0,
      // Denormalized totalLikes is often stale/0; also accept count aliases.
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
          ? DateTime.parse(json['bannedUntil'])
          : null,
      fcmToken: json['fcmToken'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
      roles: json['roles'] is List
          ? (json['roles'] as List).map((e) => _mapRole(e.toString())).toList()
          : json['roles'] is Map
              ? (json['roles'] as Map).entries.map((entry) {
                  if (entry.value == true) {
                    return _mapRole(entry.key.toString());
                  }
                  return _mapRole(entry.value.toString());
                }).toList()
              : [],
    );
  }

  static int? readInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  UserModel copyWith({
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? totalLikes,
  }) {
    return UserModel(
      id: id,
      firebaseUid: firebaseUid,
      username: username,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      bio: bio,
      avatarUrl: avatarUrl,
      gender: gender,
      dateOfBirth: dateOfBirth,
      isVerified: isVerified,
      instagramUrl: instagramUrl,
      youtubeUrl: youtubeUrl,
      isPrivate: isPrivate,
      isProfileLocked: isProfileLocked,
      allowComments: allowComments,
      allowDirectMsgs: allowDirectMsgs,
      messagePermission: messagePermission,
      canPost: canPost,
      language: language,
      theme: theme,
      country: country,
      region: region,
      city: city,
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      totalLikes: totalLikes ?? this.totalLikes,
      isBanned: isBanned,
      banReason: banReason,
      bannedUntil: bannedUntil,
      fcmToken: fcmToken,
      createdAt: createdAt,
      updatedAt: updatedAt,
      roles: roles,
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
      'roles': roles.map((e) => e.name.toUpperCase()).toList(),
    };
  }

  static UserRole _mapRole(String role) {
    switch (role.toUpperCase().replaceAll('-', '_')) {
      case 'ADMIN':
        return UserRole.admin;
      case 'SUPER_ADMIN':
      case 'SUPERADMIN':
        // Legacy directory may label platform owners this way; treat as admin
        // for dashboard access while RBAC resolves the precise super-admin role.
        return UserRole.admin;
      case 'MODERATOR':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }
}