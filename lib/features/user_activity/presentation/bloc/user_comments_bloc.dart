import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/user_comment_entity.dart';
import '../../domain/usecases/get_user_comments.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

sealed class UserCommentsEvent {}

class SetUserCommentsUserId extends UserCommentsEvent {
  SetUserCommentsUserId(this.userId);
  final String userId;
}

/// Switch between `'made'` (comments by the user) and
/// `'received'` (comments on the user's posts). Triggers a fresh load.
class SetUserCommentsType extends UserCommentsEvent {
  SetUserCommentsType(this.type);
  final String type; // 'made' | 'received'
}

class LoadUserComments extends UserCommentsEvent {}

class LoadMoreUserComments extends UserCommentsEvent {}

class RefreshUserComments extends UserCommentsEvent {}

// ─── State alias ─────────────────────────────────────────────────────────────

typedef UserCommentsState = PaginatedListState<UserCommentEntity>;

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class UserCommentsBloc extends Bloc<UserCommentsEvent, UserCommentsState> {
  UserCommentsBloc({
    required GetUserComments getUserComments,
    String initialType = 'received',
  })  : _getUserComments = getUserComments,
        _type = initialType,
        super(const PaginatedListState()) {
    on<SetUserCommentsUserId>(_onSetUserId);
    on<SetUserCommentsType>(_onSetType);
    on<LoadUserComments>(_onLoad);
    on<RefreshUserComments>(_onLoad);
    on<LoadMoreUserComments>(_onLoadMore);
  }

  final GetUserComments _getUserComments;

  /// Current engagement direction — stored in the BLoC, not in state,
  /// because the UI creating this BLoC already knows the type.
  String _type;

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _onSetUserId(
    SetUserCommentsUserId event,
    Emitter<UserCommentsState> emit,
  ) {
    emit(state.copyWith(userId: event.userId));
  }

  /// Change type and immediately reload from page 1.
  Future<void> _onSetType(
    SetUserCommentsType event,
    Emitter<UserCommentsState> emit,
  ) async {
    _type = event.type;
    // Reset and reload with the new type.
    emit(await PaginatedListBlocHelper.loadInitial<UserCommentEntity>(
      current: state,
      fetch: _fetch,
      limit: PaginatedListBlocHelper.defaultLimit,
    ));
  }

  Future<void> _onLoad(
    UserCommentsEvent event,
    Emitter<UserCommentsState> emit,
  ) async {
    emit(await PaginatedListBlocHelper.loadInitial<UserCommentEntity>(
      current: state,
      fetch: _fetch,
      limit: PaginatedListBlocHelper.defaultLimit,
    ));
  }

  Future<void> _onLoadMore(
    LoadMoreUserComments event,
    Emitter<UserCommentsState> emit,
  ) async {
    emit(await PaginatedListBlocHelper.loadMore<UserCommentEntity>(
      current: state,
      fetch: _fetch,
      limit: PaginatedListBlocHelper.defaultLimit,
    ));
  }

  Future<PaginatedPage<UserCommentEntity>> Function(
    String userId,
    int page,
    int limit,
  ) get _fetch => (userId, page, limit) =>
      _getUserComments(userId, page: page, limit: limit, type: _type);
}
