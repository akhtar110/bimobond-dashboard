import '../../domain/entities/message_permission.dart';
import '../../domain/entities/user_admin_action_type.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/entities/user_follow_entity.dart';
sealed class UserDetailEvent {}

class LoadUserDetailEvent extends UserDetailEvent {
  LoadUserDetailEvent(this.user);

  final UserEntity user;
}

class RefreshUserDetailEvent extends UserDetailEvent {}

class UserDetailPresenceChangedEvent extends UserDetailEvent {
  UserDetailPresenceChangedEvent(this.update);

  final dynamic update;
}

class ClearUserDetailActionFeedbackEvent extends UserDetailEvent {}

/// Optimistically adjust follower/following counts after admin edge removal.
class AdjustUserFollowCountsEvent extends UserDetailEvent {
  AdjustUserFollowCountsEvent({required this.kind});

  final UserFollowListKind kind;
}
/// Admin updates a user's privacy / messaging settings
/// (`PATCH /users/admin/:id`).
class UpdateUserPrivacySettingsEvent extends UserDetailEvent {
  UpdateUserPrivacySettingsEvent({
    this.isPrivate,
    this.allowComments,
    this.allowDirectMsgs,
    this.messagePermission,
  });

  final bool? isPrivate;
  final bool? allowComments;
  final bool? allowDirectMsgs;
  final MessagePermission? messagePermission;
}

sealed class UserDetailAdminActionEvent extends UserDetailEvent {
  UserAdminActionType get actionType;
}

class BanUserEvent extends UserDetailAdminActionEvent {
  @override
  UserAdminActionType get actionType => UserAdminActionType.ban;
}

class UnbanUserEvent extends UserDetailAdminActionEvent {
  @override
  UserAdminActionType get actionType => UserAdminActionType.unban;
}

class PromoteUserEvent extends UserDetailAdminActionEvent {
  @override
  UserAdminActionType get actionType => UserAdminActionType.promote;
}

class DemoteUserEvent extends UserDetailAdminActionEvent {
  @override
  UserAdminActionType get actionType => UserAdminActionType.demote;
}

class DeleteUserAccountEvent extends UserDetailAdminActionEvent {
  @override
  UserAdminActionType get actionType => UserAdminActionType.delete;
}

/// Assign a single legacy role (`user` / `moderator` / `admin`).
class SetUserDetailRoleEvent extends UserDetailEvent {
  SetUserDetailRoleEvent(this.role);

  final UserRole role;
}

UserDetailAdminActionEvent userDetailAdminActionEventFor(
  UserAdminActionType action,
) {
  return switch (action) {
    UserAdminActionType.ban => BanUserEvent(),
    UserAdminActionType.unban => UnbanUserEvent(),
    UserAdminActionType.promote => PromoteUserEvent(),
    UserAdminActionType.demote => DemoteUserEvent(),
    UserAdminActionType.delete => DeleteUserAccountEvent(),
  };
}
