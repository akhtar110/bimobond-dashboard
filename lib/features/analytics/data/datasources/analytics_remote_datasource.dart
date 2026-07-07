import 'package:dio/dio.dart';

import '../../domain/entities/analytics_entities.dart';
import '../models/analytics_models.dart';

abstract class AnalyticsRemoteDataSource {
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

class AnalyticsRemoteDataSourceImpl implements AnalyticsRemoteDataSource {
  const AnalyticsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  Future<Response<dynamic>> _get(String path, AnalyticsQuery query) =>
      _dio.get(path, queryParameters: query.toQueryParameters());

  @override
  Future<AnalyticsOverviewEntity> getAdminOverview(AnalyticsQuery query) async {
    final response = await _get('/analytics/admin/overview', query);
    return AnalyticsModels.overviewFromJson(response.data);
  }

  @override
  Future<AnalyticsUsersEntity> getAdminUsers(AnalyticsQuery query) async {
    final response = await _get('/analytics/admin/users', query);
    return AnalyticsModels.usersFromJson(response.data);
  }

  @override
  Future<AnalyticsPostsEntity> getAdminPosts(AnalyticsQuery query) async {
    final response = await _get('/analytics/admin/posts', query);
    return AnalyticsModels.postsFromJson(response.data);
  }

  @override
  Future<AnalyticsEngagementEntity> getAdminEngagement(
    AnalyticsQuery query,
  ) async {
    final response = await _get('/analytics/admin/engagement', query);
    return AnalyticsModels.engagementFromJson(response.data);
  }

  @override
  Future<AnalyticsMonetizationEntity> getAdminMonetization(
    AnalyticsQuery query,
  ) async {
    final response = await _get('/analytics/admin/monetization', query);
    return AnalyticsModels.monetizationFromJson(response.data);
  }

  @override
  Future<AnalyticsAuctionsEntity> getAdminAuctions(AnalyticsQuery query) async {
    final response = await _get('/analytics/admin/auctions', query);
    return AnalyticsModels.auctionsFromJson(response.data);
  }

  @override
  Future<AnalyticsReportsEntity> getAdminReports(AnalyticsQuery query) async {
    final response = await _get('/analytics/admin/reports', query);
    return AnalyticsModels.reportsFromJson(response.data);
  }

  @override
  Future<AnalyticsCategoriesEntity> getAdminCategories(
    AnalyticsQuery query,
  ) async {
    final response = await _get('/analytics/admin/categories', query);
    return AnalyticsModels.categoriesFromJson(response.data);
  }

  @override
  Future<AnalyticsGrowthEntity> getAdminGrowth(AnalyticsQuery query) async {
    final response = await _get('/analytics/admin/growth', query);
    return AnalyticsModels.growthFromJson(response.data);
  }
}
