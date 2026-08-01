import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/api_error_messages.dart';
import '../../domain/entities/user_follow_entity.dart';
import '../../domain/usecases/get_user_follow_list.dart';
import '../../domain/usecases/force_remove_follower.dart';

sealed class UserFollowListState {}

class UserFollowListInitial extends UserFollowListState {}

class UserFollowListLoading extends UserFollowListState {}

class UserFollowListLoaded extends UserFollowListState {
  UserFollowListLoaded({
    required this.users,
    required this.total,
    required this.page,
    required this.lastPage,
    this.isLoadingMore = false,
    this.removingFollowerId,
    this.error,
  });

  final List<UserFollowSummaryEntity> users;
  final int total;
  final int page;
  final int lastPage;
  final bool isLoadingMore;
  final String? removingFollowerId;
  final String? error;

  bool get hasMore => page < lastPage;

  UserFollowListLoaded copyWith({
    List<UserFollowSummaryEntity>? users,
    int? total,
    int? page,
    int? lastPage,
    bool? isLoadingMore,
    String? removingFollowerId,
    String? error,
    bool clearError = false,
    bool clearRemovingFollowerId = false,
  }) {
    return UserFollowListLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      removingFollowerId: clearRemovingFollowerId
          ? null
          : (removingFollowerId ?? this.removingFollowerId),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserFollowListError extends UserFollowListState {
  UserFollowListError(this.message, {this.isPrivateAccount = false});

  final String message;
  final bool isPrivateAccount;
}

class UserFollowListCubit extends Cubit<UserFollowListState> {
  UserFollowListCubit({
    required this.getUserFollowList,
    this.forceRemoveFollower,
    required this.userId,
    required this.kind,
  }) : super(UserFollowListInitial());

  final GetUserFollowList getUserFollowList;
  final ForceRemoveFollower? forceRemoveFollower;
  final String userId;
  final UserFollowListKind kind;

  static const _limit = 20;
  bool _busy = false;

  Future<void> load() async {
    if (_busy) return;
    _busy = true;
    emit(UserFollowListLoading());
    try {
      final page = await getUserFollowList(
        userId: userId,
        kind: kind,
        page: 1,
        limit: _limit,
      );
      emit(
        UserFollowListLoaded(
          users: page.users,
          total: page.total,
          page: page.page,
          lastPage: page.lastPage,
        ),
      );
    } catch (e) {
      emit(_toError(e));
    } finally {
      _busy = false;
    }
  }

  UserFollowListError _toError(Object e) {
    if (ApiErrorMessages.isForbidden(e)) {
      return UserFollowListError(
        ApiErrorMessages.from(e),
        isPrivateAccount: true,
      );
    }
    return UserFollowListError(ApiErrorMessages.from(e));
  }

  Future<void> loadMore() async {
    final current = state;
    if (current is! UserFollowListLoaded ||
        !current.hasMore ||
        current.isLoadingMore ||
        _busy) {
      return;
    }

    _busy = true;
    emit(current.copyWith(isLoadingMore: true, clearError: true));
    try {
      final page = await getUserFollowList(
        userId: userId,
        kind: kind,
        page: current.page + 1,
        limit: _limit,
      );
      emit(
        current.copyWith(
          users: [...current.users, ...page.users],
          total: page.total,
          page: page.page,
          lastPage: page.lastPage,
          isLoadingMore: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(
        isLoadingMore: false,
        error: ApiErrorMessages.from(e),
      ));
    } finally {
      _busy = false;
    }
  }

  Future<bool> removeFollowEdge(String otherUserId) async {
    final remove = forceRemoveFollower;
    if (remove == null) return false;

    final current = state;
    if (current is! UserFollowListLoaded ||
        current.removingFollowerId != null ||
        _busy) {
      return false;
    }

    final params = kind == UserFollowListKind.followers
        ? ForceRemoveFollowerParams(
            userId: userId,
            followerId: otherUserId,
          )
        : ForceRemoveFollowerParams(
            userId: otherUserId,
            followerId: userId,
          );

    _busy = true;
    emit(current.copyWith(removingFollowerId: otherUserId, clearError: true));
    try {
      final result = await remove(params);
      if (!result.removed) {
        emit(
          current.copyWith(
            clearRemovingFollowerId: true,
            error: 'Follow relationship not found',
          ),
        );
        return false;
      }

      final updatedUsers =
          current.users.where((user) => user.id != otherUserId).toList();
      emit(
        current.copyWith(
          users: updatedUsers,
          total: current.total > 0 ? current.total - 1 : 0,
          clearRemovingFollowerId: true,
          clearError: true,
        ),
      );
      return true;
    } catch (e) {
      emit(
        current.copyWith(
          clearRemovingFollowerId: true,
          error: ApiErrorMessages.from(e),
        ),
      );
      return false;
    } finally {
      _busy = false;
    }
  }
}
