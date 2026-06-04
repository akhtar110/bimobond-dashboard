import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/user_like_entity.dart';
import '../../domain/usecases/get_user_likes.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

// ─── Events ──────────────────────────────────────────────────────────────────

sealed class UserLikesEvent {}

class SetUserLikesUserId extends UserLikesEvent {
  SetUserLikesUserId(this.userId);
  final String userId;
}

/// Switch between `'made'` (likes given by the user) and
/// `'received'` (likes received on the user's posts). Triggers a fresh load.
class SetUserLikesType extends UserLikesEvent {
  SetUserLikesType(this.type);
  final String type; // 'made' | 'received'
}

class LoadUserLikes extends UserLikesEvent {}

class LoadMoreUserLikes extends UserLikesEvent {}

class RefreshUserLikes extends UserLikesEvent {}

// ─── State alias ─────────────────────────────────────────────────────────────

typedef UserLikesState = PaginatedListState<UserLikeEntity>;

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class UserLikesBloc extends Bloc<UserLikesEvent, UserLikesState> {
  UserLikesBloc({
    required GetUserLikes getUserLikes,
    String initialType = 'received',
  })  : _getUserLikes = getUserLikes,
        _type = initialType,
        super(const PaginatedListState()) {
    on<SetUserLikesUserId>(_onSetUserId);
    on<SetUserLikesType>(_onSetType);
    on<LoadUserLikes>(_onLoad);
    on<RefreshUserLikes>(_onLoad);
    on<LoadMoreUserLikes>(_onLoadMore);
  }

  final GetUserLikes _getUserLikes;

  /// Current engagement direction — stored in the BLoC, not in state,
  /// because the UI creating this BLoC already knows the type.
  String _type;

  // ── Handlers ─────────────────────────────────────────────────────────────

  void _onSetUserId(SetUserLikesUserId event, Emitter<UserLikesState> emit) {
    emit(state.copyWith(userId: event.userId));
  }

  /// Change type and immediately reload from page 1.
  Future<void> _onSetType(
    SetUserLikesType event,
    Emitter<UserLikesState> emit,
  ) async {
    _type = event.type;
    emit(await PaginatedListBlocHelper.loadInitial<UserLikeEntity>(
      current: state,
      fetch: _fetch,
      limit: PaginatedListBlocHelper.defaultLimit,
    ));
  }

  Future<void> _onLoad(
    UserLikesEvent event,
    Emitter<UserLikesState> emit,
  ) async {
    emit(await PaginatedListBlocHelper.loadInitial<UserLikeEntity>(
      current: state,
      fetch: _fetch,
      limit: PaginatedListBlocHelper.defaultLimit,
    ));
  }

  Future<void> _onLoadMore(
    LoadMoreUserLikes event,
    Emitter<UserLikesState> emit,
  ) async {
    emit(await PaginatedListBlocHelper.loadMore<UserLikeEntity>(
      current: state,
      fetch: _fetch,
      limit: PaginatedListBlocHelper.defaultLimit,
    ));
  }

  Future<PaginatedPage<UserLikeEntity>> Function(
    String userId,
    int page,
    int limit,
  ) get _fetch => (userId, page, limit) =>
      _getUserLikes(userId, page: page, limit: limit, type: _type);
}
