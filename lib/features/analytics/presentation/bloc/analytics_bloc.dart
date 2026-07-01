import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/analytics_entities.dart';
import '../../domain/usecases/analytics_usecases.dart';

part 'analytics_event.dart';
part 'analytics_state.dart';

class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc({
    required GetAdminOverview getAdminOverview,
    required GetAdminUsersAnalytics getAdminUsersAnalytics,
    required GetAdminPostsAnalytics getAdminPostsAnalytics,
    required GetAdminEngagementAnalytics getAdminEngagementAnalytics,
    required GetAdminMonetizationAnalytics getAdminMonetizationAnalytics,
    required GetAdminAuctionsAnalytics getAdminAuctionsAnalytics,
    required GetAdminReportsAnalytics getAdminReportsAnalytics,
    required GetAdminCategoriesAnalytics getAdminCategoriesAnalytics,
    required GetAdminGrowthAnalytics getAdminGrowthAnalytics,
  })  : _getAdminOverview = getAdminOverview,
        _getAdminUsersAnalytics = getAdminUsersAnalytics,
        _getAdminPostsAnalytics = getAdminPostsAnalytics,
        _getAdminEngagementAnalytics = getAdminEngagementAnalytics,
        _getAdminMonetizationAnalytics = getAdminMonetizationAnalytics,
        _getAdminAuctionsAnalytics = getAdminAuctionsAnalytics,
        _getAdminReportsAnalytics = getAdminReportsAnalytics,
        _getAdminCategoriesAnalytics = getAdminCategoriesAnalytics,
        _getAdminGrowthAnalytics = getAdminGrowthAnalytics,
        super(const AnalyticsInitial()) {
    on<LoadAnalyticsDashboardEvent>(_onLoadDashboard);
    on<LoadOverviewEvent>(_onLoadOverview);
    on<LoadUsersAnalyticsEvent>(_onLoadUsers);
    on<LoadPostsAnalyticsEvent>(_onLoadPosts);
    on<LoadGrowthAnalyticsEvent>(_onLoadGrowth);
    on<LoadEngagementAnalyticsEvent>(_onLoadEngagement);
    on<LoadMonetizationAnalyticsEvent>(_onLoadMonetization);
    on<RefreshAnalyticsEvent>(_onRefresh);
    on<ChangeAnalyticsDateRangeEvent>(_onChangeDateRange);
  }

  final GetAdminOverview _getAdminOverview;
  final GetAdminUsersAnalytics _getAdminUsersAnalytics;
  final GetAdminPostsAnalytics _getAdminPostsAnalytics;
  final GetAdminEngagementAnalytics _getAdminEngagementAnalytics;
  final GetAdminMonetizationAnalytics _getAdminMonetizationAnalytics;
  final GetAdminAuctionsAnalytics _getAdminAuctionsAnalytics;
  final GetAdminReportsAnalytics _getAdminReportsAnalytics;
  final GetAdminCategoriesAnalytics _getAdminCategoriesAnalytics;
  final GetAdminGrowthAnalytics _getAdminGrowthAnalytics;

  AnalyticsQuery _query = const AnalyticsQuery(days: 30);
  AnalyticsDatePreset _preset = AnalyticsDatePreset.last30Days;
  AnalyticsDashboardMode _mode = AnalyticsDashboardMode.admin;
  AnalyticsAccessLevel _accessLevel = AnalyticsAccessLevel.admin;

  AnalyticsLoaded? get _loaded =>
      state is AnalyticsLoaded ? state as AnalyticsLoaded : null;

  AnalyticsQuery _queryFromPreset(ChangeAnalyticsDateRangeEvent event) {
    switch (event.preset) {
      case AnalyticsDatePreset.last7Days:
        return const AnalyticsQuery(days: 7);
      case AnalyticsDatePreset.last30Days:
        return const AnalyticsQuery(days: 30);
      case AnalyticsDatePreset.last90Days:
        return const AnalyticsQuery(days: 90);
      case AnalyticsDatePreset.custom:
        if (event.customFrom != null) {
          return AnalyticsQuery(
            from: event.customFrom,
            to: event.customTo ?? DateTime.now(),
          );
        }
        return _query;
    }
  }

  Future<void> _onChangeDateRange(
    ChangeAnalyticsDateRangeEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    _preset = event.preset;
    _query = _queryFromPreset(event);
    await _loadAll(emit, showFullLoading: true);
  }

  Future<void> _onLoadDashboard(
    LoadAnalyticsDashboardEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    _mode = event.mode;
    _accessLevel = event.accessLevel;
    await _loadAll(emit, showFullLoading: true);
  }

  Future<void> _onRefresh(
    RefreshAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    final current = _loaded;
    if (current != null) {
      emit(current.copyWith(isRefreshing: true));
    }
    await _loadAll(emit, showFullLoading: current == null);
  }

  Future<void> _onLoadOverview(
    LoadOverviewEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadSection(emit, 'overview', () => _getAdminOverview(_query),
        (loaded, data) => loaded.copyWith(overview: data));
  }

  Future<void> _onLoadUsers(
    LoadUsersAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadSection(emit, 'users', () => _getAdminUsersAnalytics(_query),
        (loaded, data) => loaded.copyWith(users: data));
  }

  Future<void> _onLoadPosts(
    LoadPostsAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadSection(emit, 'posts', () => _getAdminPostsAnalytics(_query),
        (loaded, data) => loaded.copyWith(posts: data));
  }

  Future<void> _onLoadGrowth(
    LoadGrowthAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadSection(emit, 'growth', () => _getAdminGrowthAnalytics(_query),
        (loaded, data) => loaded.copyWith(growth: data));
  }

  Future<void> _onLoadEngagement(
    LoadEngagementAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadSection(
      emit,
      'engagement',
      () => _getAdminEngagementAnalytics(_query),
      (loaded, data) => loaded.copyWith(engagement: data),
    );
  }

  Future<void> _onLoadMonetization(
    LoadMonetizationAnalyticsEvent event,
    Emitter<AnalyticsState> emit,
  ) async {
    await _loadSection(
      emit,
      'monetization',
      () => _getAdminMonetizationAnalytics(_query),
      (loaded, data) => loaded.copyWith(monetization: data),
    );
  }

  Future<void> _loadAll(
    Emitter<AnalyticsState> emit, {
    required bool showFullLoading,
  }) async {
    if (showFullLoading) {
      emit(AnalyticsLoading(previous: _loaded));
    }

    final errors = <String, String>{};
    AnalyticsOverviewEntity? overview;
    AnalyticsUsersEntity? users;
    AnalyticsPostsEntity? posts;
    AnalyticsEngagementEntity? engagement;
    AnalyticsMonetizationEntity? monetization;
    AnalyticsAuctionsEntity? auctions;
    AnalyticsReportsEntity? reports;
    AnalyticsCategoriesEntity? categories;
    AnalyticsGrowthEntity? growth;

    Future<void> safe<T>(
      String key,
      Future<T> Function() call,
      void Function(T value) assign,
    ) async {
      try {
        assign(await call());
      } catch (e) {
        errors[key] = e.toString();
      }
    }

    if (_accessLevel == AnalyticsAccessLevel.creator) {
      emit(
        AnalyticsLoaded(
          query: _query,
          preset: _preset,
          mode: _mode,
          accessLevel: _accessLevel,
          isRefreshing: false,
        ),
      );
      return;
    }

    await Future.wait([
      safe('overview', () => _getAdminOverview(_query), (v) => overview = v),
      safe('users', () => _getAdminUsersAnalytics(_query), (v) => users = v),
      safe('posts', () => _getAdminPostsAnalytics(_query), (v) => posts = v),
      safe(
        'engagement',
        () => _getAdminEngagementAnalytics(_query),
        (v) => engagement = v,
      ),
      if (_accessLevel == AnalyticsAccessLevel.admin)
        safe(
          'monetization',
          () => _getAdminMonetizationAnalytics(_query),
          (v) => monetization = v,
        ),
      safe(
        'auctions',
        () => _getAdminAuctionsAnalytics(_query),
        (v) => auctions = v,
      ),
      safe(
        'reports',
        () => _getAdminReportsAnalytics(_query),
        (v) => reports = v,
      ),
      safe(
        'categories',
        () => _getAdminCategoriesAnalytics(_query),
        (v) => categories = v,
      ),
      safe('growth', () => _getAdminGrowthAnalytics(_query), (v) => growth = v),
    ]);

    if (overview == null &&
        users == null &&
        posts == null &&
        engagement == null &&
        monetization == null &&
        auctions == null &&
        reports == null &&
        categories == null &&
        growth == null) {
      emit(AnalyticsError(errors.values.firstOrNull ?? 'Failed to load analytics'));
      return;
    }

    emit(
      AnalyticsLoaded(
        query: _query,
        preset: _preset,
        mode: _mode,
        accessLevel: _accessLevel,
        overview: overview,
        users: users,
        posts: posts,
        engagement: engagement,
        monetization: monetization,
        auctions: auctions,
        reports: reports,
        categories: categories,
        growth: growth,
        sectionErrors: errors,
        isRefreshing: false,
      ),
    );
  }

  Future<void> _loadSection<T>(
    Emitter<AnalyticsState> emit,
    String key,
    Future<T> Function() call,
    AnalyticsLoaded Function(AnalyticsLoaded loaded, T data) merge,
  ) async {
    var loaded = _loaded ??
        AnalyticsLoaded(
          query: _query,
          preset: _preset,
          mode: _mode,
          accessLevel: _accessLevel,
        );
    try {
      final data = await call();
      final errors = Map<String, String>.from(loaded.sectionErrors)..remove(key);
      emit(merge(loaded.copyWith(sectionErrors: errors), data));
    } catch (e) {
      final errors = Map<String, String>.from(loaded.sectionErrors)
        ..[key] = e.toString();
      emit(loaded.copyWith(sectionErrors: errors));
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
