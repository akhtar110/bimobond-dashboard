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
    required super.allowComments,
    required super.allowDirectMsgs,
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

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
      allowComments: json['allowComments'] ?? true,
      allowDirectMsgs: json['allowDirectMsgs'] ?? true,
      language: json['language'] ?? 'en',
      theme: json['theme'] ?? 'system',
      country: json['country'],
      region: json['region'],
      city: json['city'],
      followerCount: json['followerCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      postCount: json['postCount'] ?? 0,
      totalLikes: json['totalLikes'] ?? 0,
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
      'allowComments': allowComments,
      'allowDirectMsgs': allowDirectMsgs,
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
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'MODERATOR':
        return UserRole.moderator;
      default:
        return UserRole.user;
    }
  }
}