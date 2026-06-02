import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auctions/domain/entities/auction_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/user_device_entity.dart';
import '../../domain/entities/user_gift_transaction_entity.dart';
import '../../domain/usecases/get_user_activity_auctions.dart';
import '../../domain/usecases/get_user_activity_devices.dart';
import '../../domain/usecases/get_user_activity_gifts.dart';
import '../../domain/usecases/get_user_activity_posts.dart';

// ─── Events ───────────────────────────────────────────────────────────────────

sealed class UserActivityEvent {}

class SetUserActivityUserId extends UserActivityEvent {
  SetUserActivityUserId(this.userId);
  final String userId;
}

class LoadPosts extends UserActivityEvent {}

class LoadAuctions extends UserActivityEvent {}

class LoadGifts extends UserActivityEvent {}

class LoadDevices extends UserActivityEvent {}

class LoadMorePosts extends UserActivityEvent {}

class LoadMoreAuctions extends UserActivityEvent {}

class LoadMoreGifts extends UserActivityEvent {}

class LoadMoreDevices extends UserActivityEvent {}

class ChangeAuctionFilter extends UserActivityEvent {
  ChangeAuctionFilter(this.filter);
  final String filter;
}

class ChangeGiftFilter extends UserActivityEvent {
  ChangeGiftFilter(this.filter);
  final String filter;
}

// ─── State ────────────────────────────────────────────────────────────────────

class UserActivityState {
  const UserActivityState({
    this.userId = '',
    this.posts = const [],
    this.postsPage = 0,
    this.postsTotal = 0,
    this.postsLoading = false,
    this.postsLoadingMore = false,
    this.postsHasReachedMax = false,
    this.postsError,
    this.auctions = const [],
    this.auctionFilter = 'all',
    this.auctionsPage = 0,
    this.auctionsTotal = 0,
    this.auctionsLoading = false,
    this.auctionsLoadingMore = false,
    this.auctionsHasReachedMax = false,
    this.auctionsError,
    this.auctionsLoaded = false,
    this.gifts = const [],
    this.giftFilter = 'all',
    this.giftsPage = 0,
    this.giftsTotal = 0,
    this.giftsLoading = false,
    this.giftsLoadingMore = false,
    this.giftsHasReachedMax = false,
    this.giftsError,
    this.giftsLoaded = false,
    this.devices = const [],
    this.devicesPage = 0,
    this.devicesTotal = 0,
    this.devicesLoading = false,
    this.devicesLoadingMore = false,
    this.devicesHasReachedMax = false,
    this.devicesError,
    this.devicesLoaded = false,
  });

  final String userId;

  final List<UserPostEntity> posts;
  final int postsPage;
  final int postsTotal;
  final bool postsLoading;
  final bool postsLoadingMore;
  final bool postsHasReachedMax;
  final String? postsError;

  final List<AuctionEntity> auctions;
  final String auctionFilter;
  final int auctionsPage;
  final int auctionsTotal;
  final bool auctionsLoading;
  final bool auctionsLoadingMore;
  final bool auctionsHasReachedMax;
  final String? auctionsError;
  final bool auctionsLoaded;

  final List<UserGiftTransactionEntity> gifts;
  final String giftFilter;
  final int giftsPage;
  final int giftsTotal;
  final bool giftsLoading;
  final bool giftsLoadingMore;
  final bool giftsHasReachedMax;
  final String? giftsError;
  final bool giftsLoaded;

  final List<UserDeviceEntity> devices;
  final int devicesPage;
  final int devicesTotal;
  final bool devicesLoading;
  final bool devicesLoadingMore;
  final bool devicesHasReachedMax;
  final String? devicesError;
  final bool devicesLoaded;

  static const int _limit = 10;

  UserActivityState copyWith({
    String? userId,
    List<UserPostEntity>? posts,
    int? postsPage,
    int? postsTotal,
    bool? postsLoading,
    bool? postsLoadingMore,
    bool? postsHasReachedMax,
    String? postsError,
    bool clearPostsError = false,
    List<AuctionEntity>? auctions,
    String? auctionFilter,
    int? auctionsPage,
    int? auctionsTotal,
    bool? auctionsLoading,
    bool? auctionsLoadingMore,
    bool? auctionsHasReachedMax,
    String? auctionsError,
    bool clearAuctionsError = false,
    bool? auctionsLoaded,
    List<UserGiftTransactionEntity>? gifts,
    String? giftFilter,
    int? giftsPage,
    int? giftsTotal,
    bool? giftsLoading,
    bool? giftsLoadingMore,
    bool? giftsHasReachedMax,
    String? giftsError,
    bool clearGiftsError = false,
    bool? giftsLoaded,
    List<UserDeviceEntity>? devices,
    int? devicesPage,
    int? devicesTotal,
    bool? devicesLoading,
    bool? devicesLoadingMore,
    bool? devicesHasReachedMax,
    String? devicesError,
    bool clearDevicesError = false,
    bool? devicesLoaded,
  }) {
    return UserActivityState(
      userId: userId ?? this.userId,
      posts: posts ?? this.posts,
      postsPage: postsPage ?? this.postsPage,
      postsTotal: postsTotal ?? this.postsTotal,
      postsLoading: postsLoading ?? this.postsLoading,
      postsLoadingMore: postsLoadingMore ?? this.postsLoadingMore,
      postsHasReachedMax: postsHasReachedMax ?? this.postsHasReachedMax,
      postsError: clearPostsError ? null : (postsError ?? this.postsError),
      auctions: auctions ?? this.auctions,
      auctionFilter: auctionFilter ?? this.auctionFilter,
      auctionsPage: auctionsPage ?? this.auctionsPage,
      auctionsTotal: auctionsTotal ?? this.auctionsTotal,
      auctionsLoading: auctionsLoading ?? this.auctionsLoading,
      auctionsLoadingMore:
          auctionsLoadingMore ?? this.auctionsLoadingMore,
      auctionsHasReachedMax:
          auctionsHasReachedMax ?? this.auctionsHasReachedMax,
      auctionsError:
          clearAuctionsError ? null : (auctionsError ?? this.auctionsError),
      auctionsLoaded: auctionsLoaded ?? this.auctionsLoaded,
      gifts: gifts ?? this.gifts,
      giftFilter: giftFilter ?? this.giftFilter,
      giftsPage: giftsPage ?? this.giftsPage,
      giftsTotal: giftsTotal ?? this.giftsTotal,
      giftsLoading: giftsLoading ?? this.giftsLoading,
      giftsLoadingMore: giftsLoadingMore ?? this.giftsLoadingMore,
      giftsHasReachedMax: giftsHasReachedMax ?? this.giftsHasReachedMax,
      giftsError: clearGiftsError ? null : (giftsError ?? this.giftsError),
      giftsLoaded: giftsLoaded ?? this.giftsLoaded,
      devices: devices ?? this.devices,
      devicesPage: devicesPage ?? this.devicesPage,
      devicesTotal: devicesTotal ?? this.devicesTotal,
      devicesLoading: devicesLoading ?? this.devicesLoading,
      devicesLoadingMore: devicesLoadingMore ?? this.devicesLoadingMore,
      devicesHasReachedMax:
          devicesHasReachedMax ?? this.devicesHasReachedMax,
      devicesError:
          clearDevicesError ? null : (devicesError ?? this.devicesError),
      devicesLoaded: devicesLoaded ?? this.devicesLoaded,
    );
  }
}

// ─── BLoC ─────────────────────────────────────────────────────────────────────

class UserActivityBloc extends Bloc<UserActivityEvent, UserActivityState> {
  UserActivityBloc({
    required GetUserActivityPosts getPosts,
    required GetUserActivityAuctions getAuctions,
    required GetUserActivityGifts getGifts,
    required GetUserActivityDevices getDevices,
  })  : _getPosts = getPosts,
        _getAuctions = getAuctions,
        _getGifts = getGifts,
        _getDevices = getDevices,
        super(const UserActivityState()) {
    on<SetUserActivityUserId>(_onSetUserId);
    on<LoadPosts>(_onLoadPosts);
    on<LoadMorePosts>(_onLoadMorePosts);
    on<LoadAuctions>(_onLoadAuctions);
    on<LoadMoreAuctions>(_onLoadMoreAuctions);
    on<ChangeAuctionFilter>(_onChangeAuctionFilter);
    on<LoadGifts>(_onLoadGifts);
    on<LoadMoreGifts>(_onLoadMoreGifts);
    on<ChangeGiftFilter>(_onChangeGiftFilter);
    on<LoadDevices>(_onLoadDevices);
    on<LoadMoreDevices>(_onLoadMoreDevices);
  }

  final GetUserActivityPosts _getPosts;
  final GetUserActivityAuctions _getAuctions;
  final GetUserActivityGifts _getGifts;
  final GetUserActivityDevices _getDevices;

  static const int _postsLimit = 20;
  static const int _limit = UserActivityState._limit;

  void _onSetUserId(
    SetUserActivityUserId event,
    Emitter<UserActivityState> emit,
  ) {
    emit(state.copyWith(userId: event.userId));
  }

  Future<void> _onLoadPosts(
    LoadPosts event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty) return;
    emit(
      state.copyWith(
        postsLoading: true,
        posts: [],
        postsPage: 0,
        postsHasReachedMax: false,
        clearPostsError: true,
      ),
    );
    try {
      final page = await _getPosts(
        state.userId,
        page: 1,
        limit: _postsLimit,
      );
      emit(
        state.copyWith(
          posts: page.items,
          postsPage: page.page,
          postsTotal: page.total,
          postsHasReachedMax: page.hasReachedMax,
          postsLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(postsLoading: false, postsError: e.toString()));
    }
  }

  Future<void> _onLoadMorePosts(
    LoadMorePosts event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty ||
        state.postsHasReachedMax ||
        state.postsLoadingMore) {
      return;
    }
    emit(state.copyWith(postsLoadingMore: true));
    try {
      final nextPage = state.postsPage + 1;
      final page = await _getPosts(
        state.userId,
        page: nextPage,
        limit: _postsLimit,
      );
      emit(
        state.copyWith(
          posts: [...state.posts, ...page.items],
          postsPage: page.page,
          postsTotal: page.total,
          postsHasReachedMax: page.hasReachedMax,
          postsLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(postsLoadingMore: false));
    }
  }

  Future<void> _onLoadAuctions(
    LoadAuctions event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty) return;
    emit(
      state.copyWith(
        auctionsLoading: true,
        auctions: [],
        auctionsPage: 0,
        auctionsHasReachedMax: false,
        auctionsLoaded: true,
        clearAuctionsError: true,
      ),
    );
    try {
      final page = await _getAuctions(
        state.userId,
        page: 1,
        limit: _limit,
        type: state.auctionFilter,
      );
      emit(
        state.copyWith(
          auctions: page.items,
          auctionsPage: page.page,
          auctionsTotal: page.total,
          auctionsHasReachedMax: page.hasReachedMax,
          auctionsLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(auctionsLoading: false, auctionsError: e.toString()),
      );
    }
  }

  Future<void> _onLoadMoreAuctions(
    LoadMoreAuctions event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty ||
        state.auctionsHasReachedMax ||
        state.auctionsLoadingMore) {
      return;
    }
    emit(state.copyWith(auctionsLoadingMore: true));
    try {
      final nextPage = state.auctionsPage + 1;
      final page = await _getAuctions(
        state.userId,
        page: nextPage,
        limit: _limit,
        type: state.auctionFilter,
      );
      emit(
        state.copyWith(
          auctions: [...state.auctions, ...page.items],
          auctionsPage: page.page,
          auctionsTotal: page.total,
          auctionsHasReachedMax: page.hasReachedMax,
          auctionsLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(auctionsLoadingMore: false));
    }
  }

  Future<void> _onChangeAuctionFilter(
    ChangeAuctionFilter event,
    Emitter<UserActivityState> emit,
  ) async {
    if (event.filter == state.auctionFilter) return;
    emit(state.copyWith(auctionFilter: event.filter));
    add(LoadAuctions());
  }

  Future<void> _onLoadGifts(
    LoadGifts event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty) return;
    emit(
      state.copyWith(
        giftsLoading: true,
        gifts: [],
        giftsPage: 0,
        giftsHasReachedMax: false,
        giftsLoaded: true,
        clearGiftsError: true,
      ),
    );
    try {
      final page = await _getGifts(
        state.userId,
        page: 1,
        limit: _limit,
        direction: state.giftFilter,
      );
      emit(
        state.copyWith(
          gifts: page.items,
          giftsPage: page.page,
          giftsTotal: page.total,
          giftsHasReachedMax: page.hasReachedMax,
          giftsLoading: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(giftsLoading: false, giftsError: e.toString()));
    }
  }

  Future<void> _onLoadMoreGifts(
    LoadMoreGifts event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty ||
        state.giftsHasReachedMax ||
        state.giftsLoadingMore) {
      return;
    }
    emit(state.copyWith(giftsLoadingMore: true));
    try {
      final nextPage = state.giftsPage + 1;
      final page = await _getGifts(
        state.userId,
        page: nextPage,
        limit: _limit,
        direction: state.giftFilter,
      );
      emit(
        state.copyWith(
          gifts: [...state.gifts, ...page.items],
          giftsPage: page.page,
          giftsTotal: page.total,
          giftsHasReachedMax: page.hasReachedMax,
          giftsLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(giftsLoadingMore: false));
    }
  }

  Future<void> _onChangeGiftFilter(
    ChangeGiftFilter event,
    Emitter<UserActivityState> emit,
  ) async {
    if (event.filter == state.giftFilter) return;
    emit(state.copyWith(giftFilter: event.filter));
    add(LoadGifts());
  }

  Future<void> _onLoadDevices(
    LoadDevices event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty) return;
    emit(
      state.copyWith(
        devicesLoading: true,
        devices: [],
        devicesPage: 0,
        devicesHasReachedMax: false,
        devicesLoaded: true,
        clearDevicesError: true,
      ),
    );
    try {
      final page = await _getDevices(
        state.userId,
        page: 1,
        limit: _limit,
      );
      emit(
        state.copyWith(
          devices: page.items,
          devicesPage: page.page,
          devicesTotal: page.total,
          devicesHasReachedMax: page.hasReachedMax,
          devicesLoading: false,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(devicesLoading: false, devicesError: e.toString()),
      );
    }
  }

  Future<void> _onLoadMoreDevices(
    LoadMoreDevices event,
    Emitter<UserActivityState> emit,
  ) async {
    if (state.userId.isEmpty ||
        state.devicesHasReachedMax ||
        state.devicesLoadingMore) {
      return;
    }
    emit(state.copyWith(devicesLoadingMore: true));
    try {
      final nextPage = state.devicesPage + 1;
      final page = await _getDevices(
        state.userId,
        page: nextPage,
        limit: _limit,
      );
      emit(
        state.copyWith(
          devices: [...state.devices, ...page.items],
          devicesPage: page.page,
          devicesTotal: page.total,
          devicesHasReachedMax: page.hasReachedMax,
          devicesLoadingMore: false,
        ),
      );
    } catch (e) {
      emit(state.copyWith(devicesLoadingMore: false));
    }
  }
}
