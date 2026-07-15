/// Who can start a new direct-message chat with a user.
enum MessagePermission {
  everyone,
  followers,
  friends,
  nobody,
}

extension MessagePermissionX on MessagePermission {
  String get apiValue => switch (this) {
        MessagePermission.everyone => 'EVERYONE',
        MessagePermission.followers => 'FOLLOWERS',
        MessagePermission.friends => 'FRIENDS',
        MessagePermission.nobody => 'NOBODY',
      };

  String get labelKey => switch (this) {
        MessagePermission.everyone => 'everyone',
        MessagePermission.followers => 'messagePermissionFollowers',
        MessagePermission.friends => 'messagePermissionFriends',
        MessagePermission.nobody => 'messagePermissionNobody',
      };

  static MessagePermission fromApi(
    String? value, {
    bool allowDirectMsgsFallback = true,
  }) {
    switch ((value ?? '').trim().toUpperCase()) {
      case 'EVERYONE':
        return MessagePermission.everyone;
      case 'FOLLOWERS':
        return MessagePermission.followers;
      case 'FRIENDS':
        return MessagePermission.friends;
      case 'NOBODY':
        return MessagePermission.nobody;
      default:
        return allowDirectMsgsFallback
            ? MessagePermission.everyone
            : MessagePermission.nobody;
    }
  }
}
