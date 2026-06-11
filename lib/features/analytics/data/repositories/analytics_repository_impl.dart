import '../../domain/entities/analytics_entities.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl(this._remote);
  final AnalyticsRemoteDataSource _remote;

  @override
  Future<AnalyticsOverviewEntity> getAdminOverview(AnalyticsQuery query) =>
      _remote.getAdminOverview(query);

  @override
  Future<AnalyticsUsersEntity> getAdminUsers(AnalyticsQuery query) =>
      _remote.getAdminUsers(query);

  @override
  Future<AnalyticsPostsEntity> getAdminPosts(AnalyticsQuery query) =>
      _remote.getAdminPosts(query);

  @override
  Future<AnalyticsEngagementEntity> getAdminEngagement(AnalyticsQuery query) =>
      _remote.getAdminEngagement(query);

  @override
  Future<AnalyticsMonetizationEntity> getAdminMonetization(
    AnalyticsQuery query,
  ) =>
      _remote.getAdminMonetization(query);

  @override
  Future<AnalyticsAuctionsEntity> getAdminAuctions(AnalyticsQuery query) =>
      _remote.getAdminAuctions(query);

  @override
  Future<AnalyticsReportsEntity> getAdminReports(AnalyticsQuery query) =>
      _remote.getAdminReports(query);

  @override
  Future<AnalyticsCategoriesEntity> getAdminCategories(AnalyticsQuery query) =>
      _remote.getAdminCategories(query);

  @override
  Future<AnalyticsGrowthEntity> getAdminGrowth(AnalyticsQuery query) =>
      _remote.getAdminGrowth(query);
}
