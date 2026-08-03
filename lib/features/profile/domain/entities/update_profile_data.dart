/// Request body for `PATCH /users/me` (all fields optional).
class UpdateProfileData {
  const UpdateProfileData({
    this.username,
    this.fullName,
    this.bio,
    this.avatarUrl,
    this.dateOfBirth,
    this.isPrivate,
    this.allowComments,
    this.allowDirectMsgs,
    this.messagePermission,
    this.language,
    this.theme,
    this.phoneNumber,
    this.gender,
    this.instagramUrl,
    this.youtubeUrl,
    this.country,
    this.region,
    this.city,
  });

  final String? username;
  final String? fullName;
  final String? bio;
  final String? avatarUrl;
  final DateTime? dateOfBirth;
  final bool? isPrivate;
  final bool? allowComments;
  final bool? allowDirectMsgs;
  final String? messagePermission;
  final String? language;
  final String? theme;
  final String? phoneNumber;
  final String? gender;
  final String? instagramUrl;
  final String? youtubeUrl;
  final String? country;
  final String? region;
  final String? city;

  static final usernamePattern = RegExp(r'^[a-zA-Z0-9_]{3,20}$');

  bool get isEmpty => toJson().isEmpty;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    void put(String key, Object? value) {
      if (value != null) map[key] = value;
    }

    put('username', username);
    put('fullName', fullName);
    put('bio', bio);
    put('avatarUrl', avatarUrl);
    put('dateOfBirth', dateOfBirth?.toUtc().toIso8601String());
    put('isPrivate', isPrivate);
    put('allowComments', allowComments);
    put('allowDirectMsgs', allowDirectMsgs);
    put('messagePermission', messagePermission);
    put('language', language);
    put('theme', theme);
    put('phoneNumber', phoneNumber);
    put('gender', gender);
    put('instagramUrl', instagramUrl);
    put('youtubeUrl', youtubeUrl);
    put('country', country);
    put('region', region);
    put('city', city);
    return map;
  }
}
