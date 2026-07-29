/// Request body for `PATCH /users/admin/:id` (all fields optional).
class UpdateUserAdminRequest {
  const UpdateUserAdminRequest({
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
    this.profileViewHistoryEnabled,
    this.showActivityStatus,
    this.discoverable,
    this.suggestToContacts,
    this.restrictedMode,
    this.showShopOnProfile,
    this.allowDuetsDefault,
    this.allowStitchDefault,
    this.allowDownloadsDefault,
    this.allowRepostsDefault,
    this.showRepostsOnProfile,
    this.country,
    this.region,
    this.city,
    this.canPost,
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
  final bool? profileViewHistoryEnabled;
  final bool? showActivityStatus;
  final bool? discoverable;
  final bool? suggestToContacts;
  final bool? restrictedMode;
  final bool? showShopOnProfile;
  final bool? allowDuetsDefault;
  final bool? allowStitchDefault;
  final bool? allowDownloadsDefault;
  final bool? allowRepostsDefault;
  final bool? showRepostsOnProfile;
  final String? country;
  final String? region;
  final String? city;
  final bool? canPost;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    void put(String key, Object? value) {
      if (value != null) map[key] = value;
    }

    put('username', username);
    put('fullName', fullName);
    put('bio', bio);
    put('avatarUrl', avatarUrl);
    put('dateOfBirth', dateOfBirth?.toIso8601String());
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
    put('websiteUrl', websiteUrl);
    put('tiktokUrl', tiktokUrl);
    put('twitterUrl', twitterUrl);
    put('snapchatUrl', snapchatUrl);
    put('spotifyUrl', spotifyUrl);
    put('pronouns', pronouns);
    put('creatorCategory', creatorCategory);
    put('accountType', accountType);
    put('verificationBadge', verificationBadge);
    put('likedVideosVisibility', likedVideosVisibility);
    put('followersListVisibility', followersListVisibility);
    put('followingListVisibility', followingListVisibility);
    put('profileViewHistoryEnabled', profileViewHistoryEnabled);
    put('showActivityStatus', showActivityStatus);
    put('discoverable', discoverable);
    put('suggestToContacts', suggestToContacts);
    put('restrictedMode', restrictedMode);
    put('showShopOnProfile', showShopOnProfile);
    put('allowDuetsDefault', allowDuetsDefault);
    put('allowStitchDefault', allowStitchDefault);
    put('allowDownloadsDefault', allowDownloadsDefault);
    put('allowRepostsDefault', allowRepostsDefault);
    put('showRepostsOnProfile', showRepostsOnProfile);
    put('country', country);
    put('region', region);
    put('city', city);
    put('canPost', canPost);
    return map;
  }

  bool get isEmpty => toJson().isEmpty;
}
