import '../entities/analytics_entities.dart';
import '../repositories/analytics_repository.dart';

class GetAdminOverview {
  const GetAdminOverview(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsOverviewEntity> call(AnalyticsQuery query) =>
      _repository.getAdminOverview(query);
}

class GetAdminUsersAnalytics {
  const GetAdminUsersAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsUsersEntity> call(AnalyticsQuery query) =>
      _repository.getAdminUsers(query);
}

class GetAdminPostsAnalytics {
  const GetAdminPostsAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsPostsEntity> call(AnalyticsQuery query) =>
      _repository.getAdminPosts(query);
}

class GetAdminEngagementAnalytics {
  const GetAdminEngagementAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsEngagementEntity> call(AnalyticsQuery query) =>
      _repository.getAdminEngagement(query);
}

class GetAdminMonetizationAnalytics {
  const GetAdminMonetizationAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsMonetizationEntity> call(AnalyticsQuery query) =>
      _repository.getAdminMonetization(query);
}

class GetAdminAuctionsAnalytics {
  const GetAdminAuctionsAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsAuctionsEntity> call(AnalyticsQuery query) =>
      _repository.getAdminAuctions(query);
}

class GetAdminReportsAnalytics {
  const GetAdminReportsAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsReportsEntity> call(AnalyticsQuery query) =>
      _repository.getAdminReports(query);
}

class GetAdminCategoriesAnalytics {
  const GetAdminCategoriesAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsCategoriesEntity> call(AnalyticsQuery query) =>
      _repository.getAdminCategories(query);
}

class GetAdminGrowthAnalytics {
  const GetAdminGrowthAnalytics(this._repository);
  final AnalyticsRepository _repository;

  Future<AnalyticsGrowthEntity> call(AnalyticsQuery query) =>
      _repository.getAdminGrowth(query);
}
