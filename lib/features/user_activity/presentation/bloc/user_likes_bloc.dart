import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_like_entity.dart';
import '../../domain/usecases/get_user_likes.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

sealed class UserLikesEvent {}

class SetUserLikesUserId extends UserLikesEvent {
  SetUserLikesUserId(this.userId);
  final String userId;
}

class LoadUserLikes extends UserLikesEvent {}

class LoadMoreUserLikes extends UserLikesEvent {}

class RefreshUserLikes extends UserLikesEvent {}

typedef UserLikesState = PaginatedListState<UserLikeEntity>;

class UserLikesBloc extends Bloc<UserLikesEvent, UserLikesState> {
  UserLikesBloc({required GetUserLikes getUserLikes})
      : _getUserLikes = getUserLikes,
        super(const PaginatedListState()) {
    on<SetUserLikesUserId>(_onSetUserId);
    on<LoadUserLikes>(_onLoad);
    on<RefreshUserLikes>(_onLoad);
    on<LoadMoreUserLikes>(_onLoadMore);
  }

  final GetUserLikes _getUserLikes;

  void _onSetUserId(SetUserLikesUserId event, Emitter<UserLikesState> emit) {
    emit(state.copyWith(userId: event.userId));
  }

  Future<void> _onLoad(UserLikesEvent event, Emitter<UserLikesState> emit) async {
    emit(
      await PaginatedListBlocHelper.loadInitial<UserLikeEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserLikes(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreUserLikes event,
    Emitter<UserLikesState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadMore<UserLikeEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserLikes(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }
}
