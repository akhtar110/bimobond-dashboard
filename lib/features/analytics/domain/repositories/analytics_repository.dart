import '../entities/analytics_entities.dart';

abstract class AnalyticsRepository {
  Future<AnalyticsOverviewEntity> getAdminOverview(AnalyticsQuery query);

  Future<AnalyticsUsersEntity> getAdminUsers(AnalyticsQuery query);

  Future<AnalyticsPostsEntity> getAdminPosts(AnalyticsQuery query);

  Future<AnalyticsEngagementEntity> getAdminEngagement(AnalyticsQuery query);

  Future<AnalyticsMonetizationEntity> getAdminMonetization(AnalyticsQuery query);

  Future<AnalyticsAuctionsEntity> getAdminAuctions(AnalyticsQuery query);

  Future<AnalyticsReportsEntity> getAdminReports(AnalyticsQuery query);

  Future<AnalyticsCategoriesEntity> getAdminCategories(AnalyticsQuery query);

  Future<AnalyticsGrowthEntity> getAdminGrowth(AnalyticsQuery query);
}
