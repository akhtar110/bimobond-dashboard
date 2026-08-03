import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.username,
    super.email,
    super.fullName,
    super.bio,
    super.avatarUrl,
    super.gender,
    super.dateOfBirth,
    super.phoneNumber,
    super.isVerified,
    super.isPrivate,
    super.allowComments,
    super.allowDirectMsgs,
    super.messagePermission,
    super.language,
    super.theme,
    super.instagramUrl,
    super.youtubeUrl,
    super.country,
    super.region,
    super.city,
    super.followerCount,
    super.followingCount,
    super.postCount,
    super.totalLikes,
    super.roles,
    super.isBanned,
    super.banReason,
    super.bannedUntil,
    super.createdAt,
    super.updatedAt,
    super.balanceCoins,
    super.sentGiftsCount,
    super.receivedGiftsCount,
    super.wonAuctionsCount,
    super.reportsRecvCount,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final counts = json['_count'] is Map
        ? Map<String, dynamic>.from(json['_count'] as Map)
        : json['counts'] is Map
            ? Map<String, dynamic>.from(json['counts'] as Map)
            : null;

    final rawAvatar = json['avatarUrl']?.toString();
    final resolvedAvatar = resolveMediaUrl(rawAvatar) ?? rawAvatar;

    final walletMap = json['wallet'] is Map ? json['wallet'] as Map : null;
    final coins = walletMap != null
        ? _readDouble(walletMap['balanceCoins'])
        : _readDouble(json['balanceCoins']);

    final rolesRaw = json['roles'];
    final parsedRoles = rolesRaw is List
        ? rolesRaw.map((e) => e.toString().toUpperCase()).toList()
        : const <String>['USER'];

    return ProfileModel(
      id: json['id']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString(),
      fullName: _readString(json, const ['fullName', 'displayName', 'name']),
      bio: json['bio']?.toString(),
      avatarUrl: resolvedAvatar,
      gender: json['gender']?.toString(),
      dateOfBirth: json['dateOfBirth'] != null
          ? DateTime.tryParse(json['dateOfBirth'].toString())
          : null,
      phoneNumber: json['phoneNumber']?.toString(),
      isVerified: json['isVerified'] == true,
      isPrivate: json['isPrivate'] == true,
      allowComments: json['allowComments'] as bool? ?? true,
      allowDirectMsgs: json['allowDirectMsgs'] as bool? ?? true,
      messagePermission:
          (json['messagePermission']?.toString().trim().isNotEmpty == true)
              ? json['messagePermission'].toString().trim().toUpperCase()
              : 'EVERYONE',
      language: json['language']?.toString() ?? 'en',
      theme: json['theme']?.toString() ?? 'system',
      instagramUrl: json['instagramUrl']?.toString(),
      youtubeUrl: json['youtubeUrl']?.toString(),
      country: json['country']?.toString(),
      region: json['region']?.toString(),
      city: json['city']?.toString(),
      followerCount: _readInt(
            json['followerCount'] ??
                counts?['followers'] ??
                counts?['follower']) ??
          0,
      followingCount: _readInt(
            json['followingCount'] ??
                counts?['following'] ??
                counts?['followings']) ??
          0,
      postCount: _readInt(
            json['postCount'] ?? counts?['posts'] ?? counts?['post']) ??
          0,
      totalLikes: _readInt(json['totalLikes']) ?? 0,
      roles: parsedRoles,
      isBanned: json['isBanned'] == true,
      banReason: json['banReason']?.toString(),
      bannedUntil: json['bannedUntil'] != null
          ? DateTime.tryParse(json['bannedUntil'].toString())
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      balanceCoins: coins ?? 0.0,
      sentGiftsCount: _readInt(counts?['sentGifts']) ?? 0,
      receivedGiftsCount: _readInt(counts?['receivedGifts']) ?? 0,
      wonAuctionsCount: _readInt(counts?['wonAuctions']) ?? 0,
      reportsRecvCount: _readInt(counts?['reportsRecv']) ?? 0,
    );
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim();
      if (value != null && value.isNotEmpty) return value;
    }
    return null;
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _readDouble(Object? value) {
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
