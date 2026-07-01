import '../../domain/entities/user_entity.dart';

/// Derives which bulk toolbar actions apply to the current selection.
class SelectedUsersActions {
  const SelectedUsersActions(this.users);

  final List<UserEntity> users;

  bool get allUnbanned => users.isNotEmpty && users.every((u) => !u.isBanned);
  bool get allBanned => users.isNotEmpty && users.every((u) => u.isBanned);

  bool get showBan => !allBanned;
  bool get showUnban => !allUnbanned;

  bool get showPromote =>
      users.any((u) => !u.roles.contains(UserRole.admin));

  bool get showDemote => users.any((u) => u.roles.contains(UserRole.admin));
}
