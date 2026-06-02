import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_mention_entity.dart';
import '../../domain/usecases/get_user_mentions.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

sealed class UserMentionsEvent {}

class SetUserMentionsUserId extends UserMentionsEvent {
  SetUserMentionsUserId(this.userId);
  final String userId;
}

class LoadUserMentions extends UserMentionsEvent {}

class LoadMoreUserMentions extends UserMentionsEvent {}

class RefreshUserMentions extends UserMentionsEvent {}

typedef UserMentionsState = PaginatedListState<UserMentionEntity>;

class UserMentionsBloc extends Bloc<UserMentionsEvent, UserMentionsState> {
  UserMentionsBloc({required GetUserMentions getUserMentions})
      : _getUserMentions = getUserMentions,
        super(const PaginatedListState()) {
    on<SetUserMentionsUserId>(_onSetUserId);
    on<LoadUserMentions>(_onLoad);
    on<RefreshUserMentions>(_onLoad);
    on<LoadMoreUserMentions>(_onLoadMore);
  }

  final GetUserMentions _getUserMentions;

  void _onSetUserId(
    SetUserMentionsUserId event,
    Emitter<UserMentionsState> emit,
  ) {
    emit(state.copyWith(userId: event.userId));
  }

  Future<void> _onLoad(
    UserMentionsEvent event,
    Emitter<UserMentionsState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadInitial<UserMentionEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserMentions(userId, page: page, limit: limit),
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
        fetch: (userId, page, limit) =>
            _getUserMentions(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }
}
