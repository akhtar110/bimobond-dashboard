import '../../domain/entities/user_admin_action_type.dart';
import '../../domain/entities/user_detail_entity.dart';

sealed class UserDetailState {}

class UserDetailInitial extends UserDetailState {}

class UserDetailLoading extends UserDetailState {}

class UserDetailLoaded extends UserDetailState {
  UserDetailLoaded({
    required this.userDetail,
    this.executingAction,
    this.actionFeedback,
    this.actionFeedbackIsError = false,
    this.userDeleted = false,
    this.isSavingPrivacy = false,
    this.isRefreshing = false,
  });

  final UserDetailEntity userDetail;
  final UserAdminActionType? executingAction;
  final String? actionFeedback;
  final bool actionFeedbackIsError;
  final bool userDeleted;
  final bool isSavingPrivacy;
  final bool isRefreshing;

  bool get isBusy => executingAction != null || isSavingPrivacy || isRefreshing;

  UserDetailLoaded copyWith({
    UserDetailEntity? userDetail,
    UserAdminActionType? executingAction,
    bool clearExecutingAction = false,
    String? actionFeedback,
    bool clearActionFeedback = false,
    bool? actionFeedbackIsError,
    bool? userDeleted,
    bool? isSavingPrivacy,
    bool? isRefreshing,
  }) {
    return UserDetailLoaded(
      userDetail: userDetail ?? this.userDetail,
      executingAction:
          clearExecutingAction ? null : executingAction ?? this.executingAction,
      actionFeedback:
          clearActionFeedback ? null : actionFeedback ?? this.actionFeedback,
      actionFeedbackIsError:
          actionFeedbackIsError ?? this.actionFeedbackIsError,
      userDeleted: userDeleted ?? this.userDeleted,
      isSavingPrivacy: isSavingPrivacy ?? this.isSavingPrivacy,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

class UserDetailError extends UserDetailState {
  UserDetailError(this.message);

  final String message;
}
