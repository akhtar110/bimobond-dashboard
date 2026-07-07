import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/paginated_page.dart';
import '../../domain/entities/user_mention_entity.dart';
import '../../domain/usecases/get_user_mentions.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

sealed class UserMentionsEvent {}

class SetUserMentionsUserId extends UserMentionsEvent {
  SetUserMentionsUserId(this.userId);
  final String userId;
}

/// Switch between `'made'`, `'received'`, and `'all'`. Triggers a fresh load.
class SetUserMentionsType extends UserMentionsEvent {
  SetUserMentionsType(this.type);
  final String type;
}

class LoadUserMentions extends UserMentionsEvent {}

class LoadMoreUserMentions extends UserMentionsEvent {}

class RefreshUserMentions extends UserMentionsEvent {}

typedef UserMentionsState = PaginatedListState<UserMentionEntity>;

class UserMentionsBloc extends Bloc<UserMentionsEvent, UserMentionsState> {
  UserMentionsBloc({
    required GetUserMentions getUserMentions,
    String initialType = 'received',
  })  : _getUserMentions = getUserMentions,
        _type = initialType,
        super(const PaginatedListState()) {
    on<SetUserMentionsUserId>(_onSetUserId);
    on<SetUserMentionsType>(_onSetType);
    on<LoadUserMentions>(_onLoad);
    on<RefreshUserMentions>(_onLoad);
    on<LoadMoreUserMentions>(_onLoadMore);
  }

  final GetUserMentions _getUserMentions;
  String _type;

  void _onSetUserId(
    SetUserMentionsUserId event,
    Emitter<UserMentionsState> emit,
  ) {
    emit(state.copyWith(userId: event.userId));
  }

  Future<void> _onSetType(
    SetUserMentionsType event,
    Emitter<UserMentionsState> emit,
  ) async {
    _type = event.type;
    emit(
      await PaginatedListBlocHelper.loadInitial<UserMentionEntity>(
        current: state,
        fetch: _fetch,
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  Future<void> _onLoad(
    UserMentionsEvent event,
    Emitter<UserMentionsState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadInitial<UserMentionEntity>(
        current: state,
        fetch: _fetch,
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreUserMentions event,
    Emitter<UserMentionsState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadMore<UserMentionEntity>(
        current: state,
        fetch: _fetch,
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  Future<PaginatedPage<UserMentionEntity>> Function(
    String userId,
    int page,
    int limit,
  ) get _fetch => (userId, page, limit) =>
      _getUserMentions(userId, page: page, limit: limit, type: _type);
}
