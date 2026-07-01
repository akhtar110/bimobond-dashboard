import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_follow_entity.dart';
import '../../domain/usecases/get_user_follow_list.dart';

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
    this.error,
  });

  final List<UserFollowSummaryEntity> users;
  final int total;
  final int page;
  final int lastPage;
  final bool isLoadingMore;
  final String? error;

  bool get hasMore => page < lastPage;

  UserFollowListLoaded copyWith({
    List<UserFollowSummaryEntity>? users,
    int? total,
    int? page,
    int? lastPage,
    bool? isLoadingMore,
    String? error,
    bool clearError = false,
  }) {
    return UserFollowListLoaded(
      users: users ?? this.users,
      total: total ?? this.total,
      page: page ?? this.page,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class UserFollowListError extends UserFollowListState {
  UserFollowListError(this.message);
  final String message;
}

class UserFollowListCubit extends Cubit<UserFollowListState> {
  UserFollowListCubit({
    required this.getUserFollowList,
    required this.userId,
    required this.kind,
  }) : super(UserFollowListInitial());

  final GetUserFollowList getUserFollowList;
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
      emit(UserFollowListError(e.toString()));
    } finally {
      _busy = false;
    }
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
      emit(current.copyWith(isLoadingMore: false, error: e.toString()));
    } finally {
      _busy = false;
    }
  }
}
