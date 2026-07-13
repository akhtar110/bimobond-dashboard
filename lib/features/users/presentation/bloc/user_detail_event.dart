import '../../domain/entities/user_admin_action_type.dart';
import '../../domain/entities/user_entity.dart';

sealed class UserDetailEvent {}

class LoadUserDetailEvent extends UserDetailEvent {
  LoadUserDetailEvent(this.user);

  final UserEntity user;
}

class ClearUserDetailActionFeedbackEvent extends UserDetailEvent {}

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
