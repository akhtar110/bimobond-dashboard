import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/api_error_messages.dart';
import '../../data/models/user_model.dart';
import '../../domain/entities/user_admin_action_type.dart';
import '../../domain/entities/user_detail_entity.dart';
import '../../domain/entities/user_entity_follow_counts.dart';
import '../../domain/entities/user_follow_entity.dart';
import '../../domain/usecases/ban_user.dart';
import '../../domain/usecases/delete_user.dart';
import '../../domain/usecases/demote_user.dart';
import '../../domain/usecases/get_user_by_id.dart';
import '../../domain/usecases/get_user_posts.dart';
import '../../domain/usecases/promote_to_admin.dart';
import '../../domain/usecases/update_user_privacy_settings.dart';
import '../../domain/usecases/unban_user.dart';
import 'user_detail_event.dart';
import 'user_detail_state.dart';

class UserDetailBloc extends Bloc<UserDetailEvent, UserDetailState> {
  UserDetailBloc({
    required GetUserById getUserById,
    required GetUserPosts getUserPosts,
    required BanUser banUser,
    required UnbanUser unbanUser,
    required PromoteUser promoteUser,
    required DemoteUser demoteUser,
    required DeleteUser deleteUser,
    required UpdateUserPrivacySettings updateUserPrivacySettings,
  })  : _getUserById = getUserById,
        _getUserPosts = getUserPosts,
        _banUser = banUser,
        _unbanUser = unbanUser,
        _promoteUser = promoteUser,
        _demoteUser = demoteUser,
        _deleteUser = deleteUser,
        _updateUserPrivacySettings = updateUserPrivacySettings,
        super(UserDetailInitial()) {
    on<LoadUserDetailEvent>(_onLoad);
    on<UserDetailAdminActionEvent>(_onAdminAction);
    on<UpdateUserPrivacySettingsEvent>(_onUpdatePrivacySettings);
    on<ClearUserDetailActionFeedbackEvent>(_onClearFeedback);
    on<AdjustUserFollowCountsEvent>(_onAdjustFollowCounts);
  }

  final GetUserById _getUserById;
  final GetUserPosts _getUserPosts;
  final BanUser _banUser;
  final UnbanUser _unbanUser;
  final PromoteUser _promoteUser;
  final DemoteUser _demoteUser;
  final DeleteUser _deleteUser;
  final UpdateUserPrivacySettings _updateUserPrivacySettings;

  Future<void> _onLoad(
    LoadUserDetailEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    emit(UserDetailLoading());

    try {
      final userDetail = await _fetchUserDetail(event.user.id);
      emit(UserDetailLoaded(userDetail: userDetail));
    } catch (e) {
      emit(UserDetailError(_messageFromError(e)));
    }
  }

  Future<void> _onAdminAction(
    UserDetailAdminActionEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    final current = state;
    if (current is! UserDetailLoaded) return;
    if (current.isBusy) return;

    final userId = current.userDetail.user.id;
    final action = event.actionType;

    emit(
      current.copyWith(
        executingAction: action,
        clearActionFeedback: true,
      ),
    );

    try {
      await _executeAction(action, userId);

      if (action == UserAdminActionType.delete) {
        emit(
          current.copyWith(
            clearExecutingAction: true,
            actionFeedback: action.successKey(current.userDetail.user),
            userDeleted: true,
          ),
        );
        return;
      }

      final userDetail = await _fetchUserDetail(userId);
      emit(
        current.copyWith(
          userDetail: userDetail,
          clearExecutingAction: true,
          actionFeedback: action.successKey(userDetail.user),
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          clearExecutingAction: true,
          actionFeedback: _messageFromError(e),
          actionFeedbackIsError: true,
        ),
      );
    }
  }

  Future<void> _onUpdatePrivacySettings(
    UpdateUserPrivacySettingsEvent event,
    Emitter<UserDetailState> emit,
  ) async {
    final current = state;
    if (current is! UserDetailLoaded) return;
    if (current.isBusy) return;

    final userId = current.userDetail.user.id;
    emit(current.copyWith(isSavingPrivacy: true, clearActionFeedback: true));

    try {
      await _updateUserPrivacySettings(
        userId,
        isPrivate: event.isPrivate,
        allowComments: event.allowComments,
        allowDirectMsgs: event.allowDirectMsgs,
        messagePermission: event.messagePermission,
      );

      final userDetail = await _fetchUserDetail(userId);
      emit(
        current.copyWith(
          userDetail: userDetail,
          isSavingPrivacy: false,
          actionFeedback: 'adminSuccessPrivacyUpdated',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isSavingPrivacy: false,
          actionFeedback: ApiErrorMessages.from(e),
          actionFeedbackIsError: true,
        ),
      );
    }
  }

  void _onAdjustFollowCounts(
    AdjustUserFollowCountsEvent event,
    Emitter<UserDetailState> emit,
  ) {
    final current = state;
    if (current is! UserDetailLoaded) return;

    final user = current.userDetail.user;
    final updatedUser = switch (event.kind) {
      UserFollowListKind.followers =>
        user.withFollowCountDeltas(followerDelta: -1),
      UserFollowListKind.following =>
        user.withFollowCountDeltas(followingDelta: -1),
    };

    emit(
      current.copyWith(
        userDetail: current.userDetail.copyWith(user: updatedUser),
      ),
    );
  }

  void _onClearFeedback(
    ClearUserDetailActionFeedbackEvent event,
    Emitter<UserDetailState> emit,
  ) {
    final current = state;
    if (current is! UserDetailLoaded) return;
    emit(current.copyWith(clearActionFeedback: true));
  }

  Future<UserDetailEntity> _fetchUserDetail(String userId) async {
    final fullUser = await _getUserById(userId);
    var user = fullUser.user;

    if (user.postCount == 0) {
      try {
        final postsPage = await _getUserPosts(userId, page: 1, limit: 1);
        final total = postsPage.meta['total'];
        if (total is int && total > 0) {
          user = UserModel(
            id: user.id,
            firebaseUid: user.firebaseUid,
            username: user.username,
            fullName: user.fullName,
            email: user.email,
            phoneNumber: user.phoneNumber,
            bio: user.bio,
            avatarUrl: user.avatarUrl,
            gender: user.gender,
            dateOfBirth: user.dateOfBirth,
            isVerified: user.isVerified,
            instagramUrl: user.instagramUrl,
            youtubeUrl: user.youtubeUrl,
            isPrivate: user.isPrivate,
            isProfileLocked: user.isProfileLocked,
            allowComments: user.allowComments,
            allowDirectMsgs: user.allowDirectMsgs,
            messagePermission: user.messagePermission,
            canPost: user.canPost,
            language: user.language,
            theme: user.theme,
            country: user.country,
            region: user.region,
            city: user.city,
            followerCount: user.followerCount,
            followingCount: user.followingCount,
            postCount: total,
            totalLikes: user.totalLikes,
            isBanned: user.isBanned,
            banReason: user.banReason,
            bannedUntil: user.bannedUntil,
            fcmToken: user.fcmToken,
            createdAt: user.createdAt,
            updatedAt: user.updatedAt,
            roles: user.roles,
          );
        }
      } catch (_) {
        // Keep profile post count from user detail response.
      }
    }

    return UserDetailEntity(
      user: user,
      posts: const [],
      wallet: fullUser.wallet,
      devices: fullUser.devices,
      counts: fullUser.counts,
    );
  }

  Future<void> _executeAction(UserAdminActionType action, String userId) {
    return switch (action) {
      UserAdminActionType.ban => _banUser(
          userId: userId,
          reason: 'Banned by admin',
        ),
      UserAdminActionType.unban => _unbanUser(userId),
      UserAdminActionType.promote => _promoteUser(userId),
      UserAdminActionType.demote => _demoteUser(userId),
      UserAdminActionType.delete => _deleteUser(userId),
    };
  }

  String _messageFromError(Object error) => ApiErrorMessages.from(error);
}
