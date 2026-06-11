import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/user_activity_item_entity.dart';
import '../../domain/usecases/get_user_activity_feed.dart';
import 'paginated_list_bloc_helper.dart';
import 'paginated_list_state.dart';

sealed class UserUnifiedActivityEvent {}

class SetUserUnifiedActivityUserId extends UserUnifiedActivityEvent {
  SetUserUnifiedActivityUserId(this.userId);
  final String userId;
}

class LoadUserUnifiedActivity extends UserUnifiedActivityEvent {}

class LoadMoreUserUnifiedActivity extends UserUnifiedActivityEvent {}

class RefreshUserUnifiedActivity extends UserUnifiedActivityEvent {}

class RemoveRepostActivityItem extends UserUnifiedActivityEvent {
  RemoveRepostActivityItem(this.repostId);
  final String repostId;
}

typedef UserUnifiedActivityState = PaginatedListState<UserActivityItemEntity>;

class UserUnifiedActivityBloc
    extends Bloc<UserUnifiedActivityEvent, UserUnifiedActivityState> {
  UserUnifiedActivityBloc({required GetUserActivityFeed getUserActivityFeed})
      : _getUserActivityFeed = getUserActivityFeed,
        super(const PaginatedListState()) {
    on<SetUserUnifiedActivityUserId>(_onSetUserId);
    on<LoadUserUnifiedActivity>(_onLoad);
    on<RefreshUserUnifiedActivity>(_onLoad);
    on<LoadMoreUserUnifiedActivity>(_onLoadMore);
    on<RemoveRepostActivityItem>(_onRemoveRepost);
  }

  final GetUserActivityFeed _getUserActivityFeed;

  void _onSetUserId(
    SetUserUnifiedActivityUserId event,
    Emitter<UserUnifiedActivityState> emit,
  ) {
    emit(state.copyWith(userId: event.userId));
  }

  Future<void> _onLoad(
    UserUnifiedActivityEvent event,
    Emitter<UserUnifiedActivityState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadInitial<UserActivityItemEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserActivityFeed(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  Future<void> _onLoadMore(
    LoadMoreUserUnifiedActivity event,
    Emitter<UserUnifiedActivityState> emit,
  ) async {
    emit(
      await PaginatedListBlocHelper.loadMore<UserActivityItemEntity>(
        current: state,
        fetch: (userId, page, limit) =>
            _getUserActivityFeed(userId, page: page, limit: limit),
        limit: PaginatedListBlocHelper.defaultLimit,
      ),
    );
  }

  void _onRemoveRepost(
    RemoveRepostActivityItem event,
    Emitter<UserUnifiedActivityState> emit,
  ) {
    final repostId = event.repostId.trim();
    if (repostId.isEmpty) return;

    final updated = state.items
        .where(
          (item) =>
              !(item.type.toUpperCase() == 'REPOST' && item.id == repostId),
        )
        .toList(growable: false);

    if (updated.length == state.items.length) return;

    final meta = state.meta;
    emit(
      state.copyWith(
        items: updated,
        meta: meta == null
            ? null
            : PaginationMeta(
                total: meta.total > 0 ? meta.total - 1 : 0,
                page: meta.page,
                lastPage: meta.lastPage,
              ),
      ),
    );
  }
}
