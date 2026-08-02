import 'user_entity.dart';

enum UserAdminActionType {
  ban,
  unban,
  promote,
  demote,
  delete,
}

extension UserAdminActionTypeX on UserAdminActionType {
  String labelKey(UserEntity user) => switch (this) {
        UserAdminActionType.ban => 'ban',
        UserAdminActionType.unban => 'unban',
        UserAdminActionType.promote => 'promoteToAdmin',
        UserAdminActionType.demote => 'demoteToStandardUser',
        UserAdminActionType.delete => 'delete',
      };

  String confirmTitleKey(UserEntity user) => switch (this) {
        UserAdminActionType.ban => 'adminConfirmBanTitle',
        UserAdminActionType.unban => 'adminConfirmUnbanTitle',
        UserAdminActionType.promote => 'adminConfirmPromoteTitle',
        UserAdminActionType.demote => 'adminConfirmDemoteTitle',
        UserAdminActionType.delete => 'deleteUserTitle',
      };

  String confirmMessageKey(UserEntity user) => switch (this) {
        UserAdminActionType.ban => 'confirmBanUserMessage',
        UserAdminActionType.unban => 'confirmUnbanUserMessage',
        UserAdminActionType.promote => 'adminConfirmPromoteMessage',
        UserAdminActionType.demote => 'adminConfirmDemoteMessage',
        UserAdminActionType.delete => 'deleteUserMessage',
      };

  String successKey(UserEntity user) => switch (this) {
        UserAdminActionType.ban => 'adminSuccessBanned',
        UserAdminActionType.unban => 'adminSuccessUnbanned',
        UserAdminActionType.promote => 'adminSuccessPromoted',
        UserAdminActionType.demote => 'adminSuccessDemoted',
        UserAdminActionType.delete => 'adminSuccessDeleted',
      };

  bool isDestructive(UserEntity user) => switch (this) {
        UserAdminActionType.ban ||
        UserAdminActionType.delete ||
        UserAdminActionType.demote =>
          true,
        _ => false,
      };

  bool isVisibleFor(UserEntity user) => switch (this) {
        UserAdminActionType.ban => !user.isBanned,
        UserAdminActionType.unban => user.isBanned,
        // Role changes are rendered as targeted promote/demote options in the UI.
        UserAdminActionType.promote => user.isStandardRole,
        UserAdminActionType.demote => user.isAdminRole,
        UserAdminActionType.delete => true,
      };
}

const _usersPageAdminActions = [
  UserAdminActionType.ban,
  UserAdminActionType.unban,
  UserAdminActionType.promote,
  UserAdminActionType.demote,
  UserAdminActionType.delete,
];

List<UserAdminActionType> visibleUserAdminActions(UserEntity user) {
  return _usersPageAdminActions
      .where((action) => action.isVisibleFor(user))
      .toList(growable: false);
}
