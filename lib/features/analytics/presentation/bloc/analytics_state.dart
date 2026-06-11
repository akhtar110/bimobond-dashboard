part of 'analytics_bloc.dart';

sealed class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

final class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

final class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading({this.previous});
  final AnalyticsLoaded? previous;

  @override
  List<Object?> get props => [previous];
}

final class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded({
    required this.query,
    required this.preset,
    this.overview,
    this.users,
    this.posts,
    this.engagement,
    this.monetization,
    this.auctions,
    this.reports,
    this.categories,
    this.growth,
    this.sectionErrors = const {},
    this.isRefreshing = false,
  });

  final AnalyticsQuery query;
  final AnalyticsDatePreset preset;
  final AnalyticsOverviewEntity? overview;
  final AnalyticsUsersEntity? users;
  final AnalyticsPostsEntity? posts;
  final AnalyticsEngagementEntity? engagement;
  final AnalyticsMonetizationEntity? monetization;
  final AnalyticsAuctionsEntity? auctions;
  final AnalyticsReportsEntity? reports;
  final AnalyticsCategoriesEntity? categories;
  final AnalyticsGrowthEntity? growth;
  final Map<String, String> sectionErrors;
  final bool isRefreshing;

  bool get hasAnyData =>
      overview != null ||
      users != null ||
      posts != null ||
      engagement != null ||
      monetization != null ||
      auctions != null ||
      reports != null ||
      categories != null ||
      growth != null;

  String? errorFor(String section) => sectionErrors[section];

  AnalyticsLoaded copyWith({
    AnalyticsQuery? query,
    AnalyticsDatePreset? preset,
    AnalyticsOverviewEntity? overview,
    AnalyticsUsersEntity? users,
    AnalyticsPostsEntity? posts,
    AnalyticsEngagementEntity? engagement,
    AnalyticsMonetizationEntity? monetization,
    AnalyticsAuctionsEntity? auctions,
    AnalyticsReportsEntity? reports,
    AnalyticsCategoriesEntity? categories,
    AnalyticsGrowthEntity? growth,
    Map<String, String>? sectionErrors,
    bool? isRefreshing,
    bool clearOverview = false,
    bool clearUsers = false,
    bool clearPosts = false,
    bool clearEngagement = false,
    bool clearMonetization = false,
    bool clearAuctions = false,
    bool clearReports = false,
    bool clearCategories = false,
    bool clearGrowth = false,
  }) {
    return AnalyticsLoaded(
      query: query ?? this.query,
      preset: preset ?? this.preset,
      overview: clearOverview ? null : (overview ?? this.overview),
      users: clearUsers ? null : (users ?? this.users),
      posts: clearPosts ? null : (posts ?? this.posts),
      engagement: clearEngagement ? null : (engagement ?? this.engagement),
      monetization:
          clearMonetization ? null : (monetization ?? this.monetization),
      auctions: clearAuctions ? null : (auctions ?? this.auctions),
      reports: clearReports ? null : (reports ?? this.reports),
      categories: clearCategories ? null : (categories ?? this.categories),
      growth: clearGrowth ? null : (growth ?? this.growth),
      sectionErrors: sectionErrors ?? this.sectionErrors,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }

  @override
  List<Object?> get props => [
        query,
        preset,
        overview,
        users,
        posts,
        engagement,
        monetization,
        auctions,
        reports,
        categories,
        growth,
        sectionErrors,
        isRefreshing,
      ];
}

final class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}
