import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_comment_entity.dart';
import '../../domain/usecases/get_user_comments.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

sealed class UserCommentsEvent {}

class SetUserCommentsUserId extends UserCommentsEvent {
  SetUserCommentsUserId(this.userId);
  final String userId;
}

class LoadUserComments extends UserCommentsEvent {}

class LoadMoreUserComments extends UserCommentsEvent {}

class RefreshUserComments extends UserCommentsEvent {}

typedef UserCommentsState = PaginatedListState<UserCommentEntity>;

class UserCommentsBloc extends Bloc<UserCommentsEvent, UserCommentsState> {
  UserCommentsBloc({required GetUserComments getUserComments})
      : _getUserComments = getUserComments,
        super(const PaginatedListState()) {
    on<SetUserCommentsUserId>(_onSetUserId);
    on<LoadUserComments>(_onLoad);
    on<RefreshUserComments>(_onLoad);
    on<LoadMoreUserComments>(_onLoadMore);
  }

  final GetUserComments _getUserComments;

  void _onSetUserId(
    SetUserCommentsUserId event,
    Emitter<UserCommentsState> emit,
  ) {
    emit(state.copyWith(userId: event.userId));
  }

  Future<void> _onLoad(
    UserCommentsEvent event,
    Emitter<UserCommentsState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadInitial<UserCommentEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserComments(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreUserComments event,
    Emitter<UserCommentsState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadMore<UserCommentEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserComments(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }
}
