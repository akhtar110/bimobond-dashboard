import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/usecases/get_users.dart';
import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promotion_entities.dart';
import '../utils/location_coordinate_utils.dart';
import '../../domain/usecases/promotion_usecases.dart';

class UserLocationSummary {
  const UserLocationSummary({
    required this.user,
    this.latestPoint,
    this.mapPoints = const [],
  });

  final UserEntity user;
  final LocationPointEntity? latestPoint;

  /// Distinct plottable locations for this user on the overview map.
  final List<LocationPointEntity> mapPoints;
}

abstract class LocationIntelligenceEvent {}

class LoadLocationOverviewEvent extends LocationIntelligenceEvent {
  LoadLocationOverviewEvent({
    this.page = 1,
    this.search,
    this.fullUserLocations = false,
  });

  final int page;
  final String? search;

  /// When true, loads every distinct country/region location per user for the map.
  final bool fullUserLocations;
}

class SelectLocationUserEvent extends LocationIntelligenceEvent {
  SelectLocationUserEvent(this.user);
  final UserEntity user;
}

class ClearLocationUserEvent extends LocationIntelligenceEvent {}

class LoadLocationHistoryEvent extends LocationIntelligenceEvent {
  LoadLocationHistoryEvent({this.page = 1});
  final int page;
}

class LoadMoreLocationOverviewEvent extends LocationIntelligenceEvent {}

class LoadMoreLocationHistoryEvent extends LocationIntelligenceEvent {}

class UpdateLocationFiltersEvent extends LocationIntelligenceEvent {
  UpdateLocationFiltersEvent({
    this.dateRange,
    this.source,
    this.limit,
    this.clearDateRange = false,
    this.clearSource = false,
  });

  final DateTimeRange? dateRange;
  final String? source;
  final int? limit;
  final bool clearDateRange;
  final bool clearSource;
}

class UpdateDateRangeFilterEvent extends LocationIntelligenceEvent {
  UpdateDateRangeFilterEvent({this.from, this.to});

  final DateTime? from;
  final DateTime? to;
}

class ClearLocationFiltersEvent extends LocationIntelligenceEvent {
  ClearLocationFiltersEvent({this.clearSelectedUser = false});

  final bool clearSelectedUser;
}

abstract class LocationIntelligenceState {}

class LocationIntelligenceInitial extends LocationIntelligenceState {}

class LocationIntelligenceLoading extends LocationIntelligenceState {}

class LocationIntelligenceLoaded extends LocationIntelligenceState {
  LocationIntelligenceLoaded({
    this.selectedUser,
    this.overviewEntries = const [],
    this.overviewMeta,
    this.history = const [],
    this.historyMeta,
    this.movement,
    required this.source,
    required this.limit,
    this.dateRange,
    this.overviewSearch,
    this.fullUserLocations = false,
    this.isLoadingMoreOverview = false,
    this.isLoadingMoreHistory = false,
  });

  final UserEntity? selectedUser;
  final List<UserLocationSummary> overviewEntries;
  final PaginationMeta? overviewMeta;
  final List<LocationPointEntity> history;
  final PaginationMeta? historyMeta;
  final MovementPathEntity? movement;
  final String? source;
  final int limit;
  final DateTimeRange? dateRange;
  final String? overviewSearch;
  final bool fullUserLocations;
  final bool isLoadingMoreOverview;
  final bool isLoadingMoreHistory;

  bool get isUserDetail => selectedUser != null;

  bool get hasReachedMaxOverview => overviewMeta?.hasReachedMax ?? true;

  bool get hasReachedMaxHistory => historyMeta?.hasReachedMax ?? true;

  bool get hasActiveFilters =>
      source != null || dateRange != null || limit != 50;

  List<LocationPointEntity> get mapPoints {
    if (isUserDetail) {
      final byId = <String, LocationPointEntity>{};
      for (final point in history) {
        byId[point.id] = point;
      }
      for (final point in movement?.points ?? const []) {
        byId[point.id] = point;
      }
      final points = byId.values.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return points
          .where(
            (p) => LocationCoordinateHelper.isPlottable(
              p,
              countryHint: selectedUser?.country,
            ),
          )
          .toList();
    }
    if (fullUserLocations) {
      return overviewEntries
          .expand((e) {
            final points = e.mapPoints.isNotEmpty
                ? e.mapPoints
                : [if (e.latestPoint != null) e.latestPoint!];
            return points.where(
              (p) => LocationCoordinateHelper.isPlottable(
                p,
                countryHint: e.user.country,
              ),
            );
          })
          .toList();
    }
    return [
      for (final e in overviewEntries)
        if (e.latestPoint != null &&
            LocationCoordinateHelper.isPlottable(
              e.latestPoint!,
              countryHint: e.user.country,
            ))
          e.latestPoint!,
    ];
  }

  /// Chronological points for drawing the movement polyline.
  List<LocationPointEntity> get movementPolylinePoints {
    if (!isUserDetail) return const [];

    final trail = movement?.points ?? const [];
    if (trail.isNotEmpty) {
      return trail
          .where(
            (p) => LocationCoordinateHelper.isPlottable(
              p,
              countryHint: selectedUser?.country,
            ),
          )
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }

    return mapPoints.reversed.toList();
  }

  LocationIntelligenceLoaded copyWith({
    UserEntity? selectedUser,
    List<UserLocationSummary>? overviewEntries,
    PaginationMeta? overviewMeta,
    List<LocationPointEntity>? history,
    PaginationMeta? historyMeta,
    MovementPathEntity? movement,
    String? source,
    int? limit,
    DateTimeRange? dateRange,
    String? overviewSearch,
    bool? fullUserLocations,
    bool? isLoadingMoreOverview,
    bool? isLoadingMoreHistory,
    bool clearSelectedUser = false,
    bool clearDateRange = false,
    bool clearOverviewSearch = false,
  }) {
    return LocationIntelligenceLoaded(
      selectedUser:
          clearSelectedUser ? null : (selectedUser ?? this.selectedUser),
      overviewEntries: overviewEntries ?? this.overviewEntries,
      overviewMeta: overviewMeta ?? this.overviewMeta,
      history: history ?? this.history,
      historyMeta: historyMeta ?? this.historyMeta,
      movement: movement ?? this.movement,
      source: source ?? this.source,
      limit: limit ?? this.limit,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      overviewSearch:
          clearOverviewSearch ? null : (overviewSearch ?? this.overviewSearch),
      fullUserLocations: fullUserLocations ?? this.fullUserLocations,
      isLoadingMoreOverview:
          isLoadingMoreOverview ?? this.isLoadingMoreOverview,
      isLoadingMoreHistory: isLoadingMoreHistory ?? this.isLoadingMoreHistory,
    );
  }
}

class LocationIntelligenceError extends LocationIntelligenceState {
  LocationIntelligenceError(this.message);
  final String message;
}

class LocationIntelligenceBloc
    extends Bloc<LocationIntelligenceEvent, LocationIntelligenceState> {
  LocationIntelligenceBloc({
    required GetUsers getUsers,
    required GetLocationHistoryUseCase getHistory,
    required GetMovementPathUseCase getMovement,
  })  : _getUsers = getUsers,
        _getHistory = getHistory,
        _getMovement = getMovement,
        super(LocationIntelligenceInitial()) {
    on<LoadLocationOverviewEvent>(_onLoadOverview);
    on<SelectLocationUserEvent>(_onSelectUser);
    on<ClearLocationUserEvent>(_onClearUser);
    on<LoadLocationHistoryEvent>(_onLoadHistory);
    on<LoadMoreLocationOverviewEvent>(_onLoadMoreOverview);
    on<LoadMoreLocationHistoryEvent>(_onLoadMoreHistory);
    on<UpdateLocationFiltersEvent>(_onUpdateFilters);
    on<UpdateDateRangeFilterEvent>(_onUpdateDateRange);
    on<ClearLocationFiltersEvent>(_onClearFilters);
  }

  static const _defaultLimit = 50;
  static const _overviewLocationBatchSize = 4;
  static const _overviewFullLocationHistoryLimit = 100;

  static bool isValidCoordinate(LocationPointEntity point) {
    return LocationCoordinateHelper.isPlottable(point);
  }

  final GetUsers _getUsers;
  final GetLocationHistoryUseCase _getHistory;
  final GetMovementPathUseCase _getMovement;

  UserEntity? _selectedUser;
  String? _source;
  int _limit = _defaultLimit;
  DateTimeRange? _dateRange;
  String? _overviewSearch;
  bool _fullUserLocations = false;
  bool _overviewLoadMoreBusy = false;
  bool _historyLoadMoreBusy = false;

  Future<void> _onLoadOverview(
    LoadLocationOverviewEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    if (event.search != null) {
      _overviewSearch = event.search!.trim().isEmpty ? null : event.search!.trim();
    }
    if (event.fullUserLocations) {
      _fullUserLocations = true;
    }
    emit(LocationIntelligenceLoading());
    try {
      final usersPage = await _getUsers(
        page: event.page,
        limit: _limit,
        search: _overviewSearch,
      );
      final summaries = await _buildOverviewSummaries(
        usersPage.users,
        fullUserLocations: _fullUserLocations,
      );
      emit(
        LocationIntelligenceLoaded(
          overviewEntries: summaries,
          overviewMeta: PaginationMeta(
            total: usersPage.total,
            page: usersPage.page,
            limit: _limit,
            totalPages: usersPage.lastPage,
          ),
          source: _source,
          limit: _limit,
          dateRange: _dateRange,
          overviewSearch: _overviewSearch,
          fullUserLocations: _fullUserLocations,
        ),
      );
    } catch (e) {
      emit(LocationIntelligenceError(_formatError(e)));
    }
  }

  Future<void> _onSelectUser(
    SelectLocationUserEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    _selectedUser = event.user;
    emit(LocationIntelligenceLoading());
    await _loadUserDetail(emit, page: 1, appendHistory: false);
  }

  Future<void> _onClearUser(
    ClearLocationUserEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    _selectedUser = null;
    _fullUserLocations = false;
    add(_overviewEvent());
  }

  LoadLocationOverviewEvent _overviewEvent({int page = 1, String? search}) {
    return LoadLocationOverviewEvent(
      page: page,
      search: search ?? _overviewSearch,
      fullUserLocations: _fullUserLocations,
    );
  }

  Future<void> _onLoadHistory(
    LoadLocationHistoryEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    if (_selectedUser == null) return;
    final current = state;
    if (event.page > 1 && current is LocationIntelligenceLoaded) {
      await _loadUserDetail(emit, page: event.page, appendHistory: true);
      return;
    }
    emit(LocationIntelligenceLoading());
    await _loadUserDetail(emit, page: event.page, appendHistory: false);
  }

  Future<void> _onLoadMoreOverview(
    LoadMoreLocationOverviewEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    if (_selectedUser != null) return;
    final current = state;
    if (current is! LocationIntelligenceLoaded) return;
    if (current.hasReachedMaxOverview ||
        current.isLoadingMoreOverview ||
        _overviewLoadMoreBusy) {
      return;
    }

    final nextPage = (current.overviewMeta?.page ?? 1) + 1;
    _overviewLoadMoreBusy = true;
    emit(current.copyWith(isLoadingMoreOverview: true));

    try {
      final usersPage = await _getUsers(
        page: nextPage,
        limit: _limit,
        search: _overviewSearch,
      );
      final summaries = await _buildOverviewSummaries(
        usersPage.users,
        fullUserLocations: _fullUserLocations,
      );
      emit(
        current.copyWith(
          overviewEntries: [...current.overviewEntries, ...summaries],
          overviewMeta: PaginationMeta(
            total: usersPage.total,
            page: usersPage.page,
            limit: _limit,
            totalPages: usersPage.lastPage,
          ),
          isLoadingMoreOverview: false,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isLoadingMoreOverview: false));
    } finally {
      _overviewLoadMoreBusy = false;
    }
  }

  Future<void> _onLoadMoreHistory(
    LoadMoreLocationHistoryEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    if (_selectedUser == null) return;
    final current = state;
    if (current is! LocationIntelligenceLoaded) return;
    if (current.hasReachedMaxHistory ||
        current.isLoadingMoreHistory ||
        _historyLoadMoreBusy) {
      return;
    }

    final nextPage = (current.historyMeta?.page ?? 1) + 1;
    await _loadUserDetail(emit, page: nextPage, appendHistory: true);
  }

  Future<void> _onUpdateFilters(
    UpdateLocationFiltersEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    if (event.clearDateRange) {
      _dateRange = null;
    } else if (event.dateRange != null) {
      _dateRange = event.dateRange;
    }
    if (event.clearSource) {
      _source = null;
    } else if (event.source != null) {
      _source = event.source;
    }
    if (event.limit != null) _limit = event.limit!;

    if (_selectedUser != null) {
      emit(LocationIntelligenceLoading());
      await _loadUserDetail(emit, page: 1, appendHistory: false);
    } else {
      add(_overviewEvent());
    }
  }

  Future<void> _onUpdateDateRange(
    UpdateDateRangeFilterEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    if (event.from == null && event.to == null) {
      _dateRange = null;
    } else if (event.from != null && event.to != null) {
      _dateRange = DateTimeRange(start: event.from!, end: event.to!);
    } else {
      return;
    }

    if (_selectedUser != null) {
      emit(LocationIntelligenceLoading());
      await _loadUserDetail(emit, page: 1, appendHistory: false);
    } else {
      add(_overviewEvent());
    }
  }

  Future<void> _onClearFilters(
    ClearLocationFiltersEvent event,
    Emitter<LocationIntelligenceState> emit,
  ) async {
    _source = null;
    _dateRange = null;
    _limit = _defaultLimit;

    if (event.clearSelectedUser) {
      _selectedUser = null;
      add(_overviewEvent());
      return;
    }

    if (_selectedUser != null) {
      emit(LocationIntelligenceLoading());
      await _loadUserDetail(emit, page: 1, appendHistory: false);
    } else {
      add(_overviewEvent());
    }
  }

  Future<LocationPointEntity?> _fetchLatestPoint(String userId) async {
    try {
      final page = await _getHistory(
        userId: userId,
        query: LocationHistoryQuery(
          page: 1,
          limit: 1,
          from: _dateRange?.start,
          to: _dateRange?.end,
          source: _source,
        ),
      );
      return page.data.isNotEmpty ? page.data.first : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<LocationPointEntity>> _fetchOverviewMapPoints(
    UserEntity user,
  ) async {
    try {
      final page = await _getHistory(
        userId: user.id,
        query: LocationHistoryQuery(
          page: 1,
          limit: _overviewFullLocationHistoryLimit,
          from: _dateRange?.start,
          to: _dateRange?.end,
          source: _source,
        ),
      );
      return _distinctOverviewMapPoints(
        page.data,
        countryHint: user.country,
      );
    } catch (_) {
      return const [];
    }
  }

  List<LocationPointEntity> _distinctOverviewMapPoints(
    List<LocationPointEntity> points, {
    String? countryHint,
  }) {
    final byCluster = <String, LocationPointEntity>{};
    for (final point in points) {
      if (!LocationCoordinateHelper.isPlottable(
        point,
        countryHint: countryHint,
      )) {
        continue;
      }
      final key = _overviewLocationClusterKey(point);
      final existing = byCluster[key];
      if (existing == null || point.createdAt.isAfter(existing.createdAt)) {
        byCluster[key] = point;
      }
    }
    return byCluster.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  String _overviewLocationClusterKey(LocationPointEntity point) {
    final country = point.country?.trim().toLowerCase();
    if (country != null && country.isNotEmpty) {
      final city = point.city?.trim().toLowerCase() ?? '';
      return '$country|$city';
    }
    return '${point.latitude.toStringAsFixed(2)}|'
        '${point.longitude.toStringAsFixed(2)}';
  }

  Future<void> _loadUserDetail(
    Emitter<LocationIntelligenceState> emit, {
    required int page,
    required bool appendHistory,
  }) async {
    final user = _selectedUser;
    if (user == null) return;

    final previous = state is LocationIntelligenceLoaded
        ? state as LocationIntelligenceLoaded
        : null;

    if (appendHistory) {
      if (_historyLoadMoreBusy) return;
      _historyLoadMoreBusy = true;
      if (previous != null) {
        emit(previous.copyWith(isLoadingMoreHistory: true));
      }
    }

    try {
      final history = await _getHistory(
        userId: user.id,
        query: LocationHistoryQuery(
          page: page,
          limit: _limit,
          from: _dateRange?.start,
          to: _dateRange?.end,
          source: _source,
        ),
      );

      MovementPathEntity? movement;
      try {
        movement = await _getMovement(
          userId: user.id,
          query: MovementPathQuery(
            from: _dateRange?.start,
            to: _dateRange?.end,
            limit: math.max(_limit, 100),
            source: _source,
          ),
        );
      } catch (_) {
        movement = previous?.movement;
      }

      final mergedHistory = appendHistory && previous != null
          ? [...previous.history, ...history.data]
          : history.data;

      emit(
        LocationIntelligenceLoaded(
          selectedUser: user,
          history: mergedHistory,
          historyMeta: history.meta,
          movement: movement,
          source: _source,
          limit: _limit,
          dateRange: _dateRange,
          overviewSearch: _overviewSearch,
          fullUserLocations: _fullUserLocations,
          isLoadingMoreHistory: false,
        ),
      );
    } catch (e) {
      if (appendHistory && previous != null) {
        emit(previous.copyWith(isLoadingMoreHistory: false));
      } else {
        emit(LocationIntelligenceError(_formatError(e)));
      }
    } finally {
      if (appendHistory) {
        _historyLoadMoreBusy = false;
      }
    }
  }

  Future<List<UserLocationSummary>> _buildOverviewSummaries(
    List<UserEntity> users, {
    required bool fullUserLocations,
  }) async {
    final summaries = <UserLocationSummary>[];
    for (var i = 0; i < users.length; i += _overviewLocationBatchSize) {
      final batch = users.skip(i).take(_overviewLocationBatchSize);
      final batchResults = await Future.wait(
        batch.map((user) async {
          if (fullUserLocations) {
            final mapPoints = await _fetchOverviewMapPoints(user);
            return UserLocationSummary(
              user: user,
              latestPoint: mapPoints.isNotEmpty ? mapPoints.first : null,
              mapPoints: mapPoints,
            );
          }
          final latest = await _fetchLatestPoint(user.id);
          return UserLocationSummary(
            user: user,
            latestPoint: latest,
            mapPoints: latest == null ? const [] : [latest],
          );
        }),
      );
      summaries.addAll(batchResults);
    }
    return summaries;
  }

  String _formatError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return 'Could not reach the API. On Firebase Hosting, build with '
              '--dart-define=API_BASE_URL=https://your-api-host and ensure '
              'the API allows HTTPS/CORS from your dashboard domain.';
        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status != null) {
            return 'Location API request failed (HTTP $status).';
          }
          break;
        default:
          break;
      }
      return error.message ?? 'Location API request failed.';
    }

    if (kDebugMode) return error.toString();
    return 'Failed to load location data. Please try again.';
  }
}
