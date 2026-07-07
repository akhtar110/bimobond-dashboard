import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../analytics/domain/entities/analytics_entities.dart';
import '../../../analytics/domain/usecases/analytics_usecases.dart';
import '../../../auction_reports/domain/entities/auction_report_entities.dart'
    as auction_reports;
import '../../../auction_reports/domain/usecases/get_auction_reports_overview.dart';
import '../../../category_reports/domain/entities/category_report_entities.dart';
import '../../../category_reports/domain/usecases/get_category_reports_overview_usecase.dart';
import '../../../gift_reports/domain/entities/gift_report_entities.dart';
import '../../../gift_reports/domain/usecases/get_gift_reports_overview_usecase.dart';
import '../../../post_reports/domain/entities/post_report_entities.dart';
import '../../../post_reports/domain/usecases/get_post_reports_overview.dart';
import '../../../user_reports/domain/usecases/get_user_reports_overview.dart';

class ReportsOverviewMetric extends Equatable {
  const ReportsOverviewMetric({
    required this.label,
    required this.total,
    required this.icon,
    this.periodLabel,
  });

  final String label;
  final int total;
  final IconData icon;
  final String? periodLabel;

  @override
  List<Object?> get props => [label, total, icon, periodLabel];
}

class ReportsCenterOverviewState extends Equatable {
  const ReportsCenterOverviewState({
    this.loading = false,
    this.metrics = const [],
    this.error,
  });

  final bool loading;
  final List<ReportsOverviewMetric> metrics;
  final String? error;

  ReportsCenterOverviewState copyWith({
    bool? loading,
    List<ReportsOverviewMetric>? metrics,
    String? error,
  }) {
    return ReportsCenterOverviewState(
      loading: loading ?? this.loading,
      metrics: metrics ?? this.metrics,
      error: error,
    );
  }

  @override
  List<Object?> get props => [loading, metrics, error];
}

class ReportsCenterOverviewCubit extends Cubit<ReportsCenterOverviewState> {
  ReportsCenterOverviewCubit({
    required GetUserReportsOverview getUserReportsOverview,
    required GetPostReportsOverview getPostReportsOverview,
    required GetAuctionReportsOverview getAuctionReportsOverview,
    required GetGiftReportsOverview getGiftReportsOverview,
    required GetCategoryReportsOverview getCategoryReportsOverview,
    required GetAdminReportsAnalytics getAdminReportsAnalytics,
  })  : _getUserReportsOverview = getUserReportsOverview,
        _getPostReportsOverview = getPostReportsOverview,
        _getAuctionReportsOverview = getAuctionReportsOverview,
        _getGiftReportsOverview = getGiftReportsOverview,
        _getCategoryReportsOverview = getCategoryReportsOverview,
        _getAdminReportsAnalytics = getAdminReportsAnalytics,
        super(const ReportsCenterOverviewState(loading: true));

  final GetUserReportsOverview _getUserReportsOverview;
  final GetPostReportsOverview _getPostReportsOverview;
  final GetAuctionReportsOverview _getAuctionReportsOverview;
  final GetGiftReportsOverview _getGiftReportsOverview;
  final GetCategoryReportsOverview _getCategoryReportsOverview;
  final GetAdminReportsAnalytics _getAdminReportsAnalytics;

  Future<void> load({int days = 30}) async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final users = await _safe(
        () => _getUserReportsOverview(days: days),
      );
      final posts = await _safe(
        () => _getPostReportsOverview(ReportPeriodQuery(days: days)),
      );
      final auctions = await _safe(
        () => _getAuctionReportsOverview(
          auction_reports.ReportPeriodQuery(days: days),
        ),
      );
      final gifts = await _safe(
        () => _getGiftReportsOverview(GiftReportPeriodQuery(days: days)),
      );
      final categories = await _safe(
        () => _getCategoryReportsOverview(CategoryReportPeriodQuery(days: days)),
      );
      final moderation = await _safe(
        () => _getAdminReportsAnalytics(AnalyticsQuery(days: days)),
      );

      final metrics = <ReportsOverviewMetric>[
        if (users != null)
          ReportsOverviewMetric(
            label: 'Users',
            total: users.totals.totalUsers,
            icon: Icons.people_outline_rounded,
            periodLabel: _pct(
              users.totals.newUsersInPeriod,
              users.totals.totalUsers,
            ),
          ),
        if (posts != null)
          ReportsOverviewMetric(
            label: 'Posts',
            total: posts.totalPosts,
            icon: Icons.grid_view_rounded,
            periodLabel: _pct(posts.postsInPeriod, posts.totalPosts),
          ),
        if (auctions != null)
          ReportsOverviewMetric(
            label: 'Auctions',
            total: auctions.totalAuctions,
            icon: Icons.gavel_outlined,
            periodLabel: _pct(
              auctions.auctionsInPeriod,
              auctions.totalAuctions,
            ),
          ),
        if (gifts != null)
          ReportsOverviewMetric(
            label: 'Gifts',
            total: gifts.totalGifts,
            icon: Icons.card_giftcard_outlined,
            periodLabel: _pct(
              gifts.transactionsInPeriod,
              gifts.totalTransactions,
            ),
          ),
        if (categories != null)
          ReportsOverviewMetric(
            label: 'Categories',
            total: categories.totalCategories,
            icon: Icons.category_outlined,
            periodLabel: _pct(categories.postsCreated, categories.totalPosts),
          ),
        if (moderation != null)
          ReportsOverviewMetric(
            label: 'Flags',
            total: moderation.total,
            icon: Icons.flag_outlined,
            periodLabel: _pct(moderation.inPeriod, moderation.total),
          ),
      ];

      emit(ReportsCenterOverviewState(loading: false, metrics: metrics));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      ));
    }
  }

  Future<T?> _safe<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (_) {
      return null;
    }
  }

  String? _pct(int part, int whole) {
    if (whole <= 0 || part <= 0) return null;
    final pct = (part / whole) * 100;
    return '+${pct.toStringAsFixed(1)}%';
  }
}
