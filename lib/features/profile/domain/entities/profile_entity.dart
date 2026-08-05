import 'package:equatable/equatable.dart';

/// Logged-in admin's own profile (from `GET /users/:id`).
class ProfileEntity extends Equatable {
  const ProfileEntity({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.gender,
    this.dateOfBirth,
    this.phoneNumber,
    this.isVerified = false,
    this.isPrivate = false,
    this.allowComments = true,
    this.allowDirectMsgs = true,
    this.messagePermission = 'EVERYONE',
    this.language = 'en',
    this.theme = 'system',
    this.instagramUrl,
    this.youtubeUrl,
    this.country,
    this.region,
    this.city,
    this.followerCount = 0,
    this.followingCount = 0,
    this.postCount = 0,
    this.totalLikes = 0,
    this.roles = const ['USER'],
    this.isBanned = false,
    this.banReason,
    this.bannedUntil,
    this.createdAt,
    this.updatedAt,
    this.balanceCoins = 0.0,
    this.sentGiftsCount = 0,
    this.receivedGiftsCount = 0,
    this.wonAuctionsCount = 0,
    this.reportsRecvCount = 0,
  });

  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final String? phoneNumber;
  final bool isVerified;
  final bool isPrivate;
  final bool allowComments;
  final bool allowDirectMsgs;
  final String messagePermission;
  final String language;
  final String theme;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? country;
  final String? region;
  final String? city;
  final int followerCount;
  final int followingCount;
  final int postCount;
  final int totalLikes;
  final List<String> roles;
  final bool isBanned;
  final String? banReason;
  final DateTime? bannedUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final double balanceCoins;
  final int sentGiftsCount;
  final int receivedGiftsCount;
  final int wonAuctionsCount;
  final int reportsRecvCount;

  String get displayName {
    final name = fullName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return username;
  }

  ProfileEntity copyWith({
    String? id,
    String? username,
    String? email,
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? gender,
    DateTime? dateOfBirth,
    String? phoneNumber,
    bool? isVerified,
    bool? isPrivate,
    bool? allowComments,
    bool? allowDirectMsgs,
    String? messagePermission,
    String? language,
    String? theme,
    String? instagramUrl,
    String? youtubeUrl,
    String? country,
    String? region,
    String? city,
    int? followerCount,
    int? followingCount,
    int? postCount,
    int? totalLikes,
    List<String>? roles,
    bool? isBanned,
    String? banReason,
    DateTime? bannedUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? balanceCoins,
    int? sentGiftsCount,
    int? receivedGiftsCount,
    int? wonAuctionsCount,
    int? reportsRecvCount,
    bool clearFullName = false,
    bool clearBio = false,
    bool clearAvatarUrl = false,
    bool clearGender = false,
    bool clearDateOfBirth = false,
    bool clearPhoneNumber = false,
    bool clearInstagramUrl = false,
    bool clearYoutubeUrl = false,
    bool clearCountry = false,
    bool clearRegion = false,
    bool clearCity = false,
    bool clearBanReason = false,
    bool clearBannedUntil = false,
  }) {
    return ProfileEntity(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: clearFullName ? null : (fullName ?? this.fullName),
      bio: clearBio ? null : (bio ?? this.bio),
      avatarUrl: clearAvatarUrl ? null : (avatarUrl ?? this.avatarUrl),
      gender: clearGender ? null : (gender ?? this.gender),
      dateOfBirth:
          clearDateOfBirth ? null : (dateOfBirth ?? this.dateOfBirth),
      phoneNumber:
          clearPhoneNumber ? null : (phoneNumber ?? this.phoneNumber),
      isVerified: isVerified ?? this.isVerified,
      isPrivate: isPrivate ?? this.isPrivate,
      allowComments: allowComments ?? this.allowComments,
      allowDirectMsgs: allowDirectMsgs ?? this.allowDirectMsgs,
      messagePermission: messagePermission ?? this.messagePermission,
      language: language ?? this.language,
      theme: theme ?? this.theme,
      instagramUrl:
          clearInstagramUrl ? null : (instagramUrl ?? this.instagramUrl),
      youtubeUrl: clearYoutubeUrl ? null : (youtubeUrl ?? this.youtubeUrl),
      country: clearCountry ? null : (country ?? this.country),
      region: clearRegion ? null : (region ?? this.region),
      city: clearCity ? null : (city ?? this.city),
      followerCount: followerCount ?? this.followerCount,
      followingCount: followingCount ?? this.followingCount,
      postCount: postCount ?? this.postCount,
      totalLikes: totalLikes ?? this.totalLikes,
      roles: roles ?? this.roles,
      isBanned: isBanned ?? this.isBanned,
      banReason: clearBanReason ? null : (banReason ?? this.banReason),
      bannedUntil: clearBannedUntil ? null : (bannedUntil ?? this.bannedUntil),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balanceCoins: balanceCoins ?? this.balanceCoins,
      sentGiftsCount: sentGiftsCount ?? this.sentGiftsCount,
      receivedGiftsCount: receivedGiftsCount ?? this.receivedGiftsCount,
      wonAuctionsCount: wonAuctionsCount ?? this.wonAuctionsCount,
      reportsRecvCount: reportsRecvCount ?? this.reportsRecvCount,
    );
  }

  @override
  List<Object?> get props => [
        id,
        username,
        email,
        fullName,
        bio,
        avatarUrl,
        gender,
        dateOfBirth,
        phoneNumber,
        isVerified,
        isPrivate,
        allowComments,
        allowDirectMsgs,
        messagePermission,
        language,
        theme,
        instagramUrl,
        youtubeUrl,
        country,
        region,
        city,
        followerCount,
        followingCount,
        postCount,
        totalLikes,
        roles,
        isBanned,
        banReason,
        bannedUntil,
        createdAt,
        updatedAt,
        balanceCoins,
        sentGiftsCount,
        receivedGiftsCount,
        wonAuctionsCount,
        reportsRecvCount,
      ];
}
