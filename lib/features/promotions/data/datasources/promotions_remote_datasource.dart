import 'package:dio/dio.dart';

import '../../domain/entities/pagination_meta.dart';
import '../../domain/entities/promoted_post_entities.dart';
import '../../domain/entities/promotion_entities.dart';
import '../../domain/entities/promotion_overview_entity.dart';
import '../models/promoted_post_models.dart';
import '../models/promotion_models.dart';

abstract class PromotionsRemoteDataSource {
  Future<PromotionOverviewEntity> getOverview();
  Future<PaginatedResult<CampaignEntity>> getCampaigns(AdminCampaignsQuery query);
  Future<CampaignEntity> getCampaignDetail(String campaignId);
  Future<CampaignStatsEntity> getCampaignStats(String campaignId);
  Future<PaginatedResult<CampaignImpressionEntity>> getCampaignImpressions({
    required String campaignId,
    int page = 1,
    int limit = 50,
    String? viewerId,
  });
  Future<CampaignEntity> updateCampaign(
    String campaignId,
    UpdateCampaignData data,
  );
  Future<CampaignEntity> updateCampaignStatus(
    String campaignId,
    String status,
  );
  Future<void> deleteCampaign(String campaignId);
  Future<BulkActionResultEntity> bulkAction(BulkCampaignActionRequest request);
  Future<List<PromotionPackageEntity>> getPackages({PackagesQuery query = const PackagesQuery()});
  Future<PromotionPackageEntity> createPackage(CreatePackageData data);
  Future<PromotionPackageEntity> updatePackage(
    String packageId,
    UpdatePackageData data,
  );
  Future<PromotionPackageEntity> activatePackage(String packageId);
  Future<PromotionPackageEntity> deactivatePackage(String packageId);
  Future<void> deletePackage(String packageId);
  Future<PromotedPostsPageEntity> getPromotedPosts(PromotedPostsQuery query);
  Future<PromotedPostDetailEntity> getPromotedPostDetail(String postId);
  Future<PostPromotionStatsEntity> getPromotedPostStats(
    String postId, {
    String? campaignId,
  });
  Future<PostPromotionStatsEntity> getAdminPromotedPostStats(
    String postId, {
    String? campaignId,
  });
}

abstract class LocationIntelligenceRemoteDataSource {
  Future<PaginatedResult<LocationPointEntity>> getLocationHistory({
    required String userId,
    required LocationHistoryQuery query,
  });
  Future<MovementPathEntity> getMovementPath({
    required String userId,
    required MovementPathQuery query,
  });
}

class PromotionsRemoteDataSourceImpl implements PromotionsRemoteDataSource {
  const PromotionsRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<PromotionOverviewEntity> getOverview() async {
    final response = await _dio.get('/promotions/admin/overview');
    return PromotionOverviewModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedResult<CampaignEntity>> getCampaigns(
    AdminCampaignsQuery query,
  ) async {
    final response = await _dio.get(
      '/promotions/admin/campaigns',
      queryParameters: query.toQueryParameters(),
    );
    return CampaignPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<CampaignEntity> getCampaignDetail(String campaignId) async {
    final response = await _dio.get('/promotions/admin/campaigns/$campaignId');
    return CampaignModel.fromJson(_map(response.data));
  }

  @override
  Future<CampaignStatsEntity> getCampaignStats(String campaignId) async {
    final response =
        await _dio.get('/promotions/admin/campaigns/$campaignId/stats');
    return CampaignStatsModel.fromJson(_map(response.data));
  }

  @override
  Future<PaginatedResult<CampaignImpressionEntity>> getCampaignImpressions({
    required String campaignId,
    int page = 1,
    int limit = 50,
    String? viewerId,
  }) async {
    final params = <String, dynamic>{'page': page, 'limit': limit};
    if (viewerId != null && viewerId.isNotEmpty) {
      params['viewerId'] = viewerId;
    }
    final response = await _dio.get(
      '/promotions/admin/campaigns/$campaignId/impressions',
      queryParameters: params,
    );
    return CampaignImpressionPageModel.fromJson(_unwrapPaginated(response.data));
  }

  @override
  Future<CampaignEntity> updateCampaign(
    String campaignId,
    UpdateCampaignData data,
  ) async {
    final response = await _dio.patch(
      '/promotions/admin/campaigns/$campaignId',
      data: data.toJson(),
    );
    return CampaignModel.fromJson(_map(response.data));
  }

  @override
  Future<CampaignEntity> updateCampaignStatus(
    String campaignId,
    String status,
  ) async {
    final response = await _dio.patch(
      '/promotions/admin/campaigns/$campaignId',
      data: {'status': status},
    );
    return CampaignModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deleteCampaign(String campaignId) async {
    await _dio.delete('/promotions/admin/campaigns/$campaignId');
  }

  @override
  Future<BulkActionResultEntity> bulkAction(
    BulkCampaignActionRequest request,
  ) async {
    final response = await _dio.post(
      '/promotions/admin/bulk',
      data: request.toJson(),
    );
    return BulkActionResultModel.fromJson(_map(response.data));
  }

  @override
  Future<List<PromotionPackageEntity>> getPackages({
    PackagesQuery query = const PackagesQuery(),
  }) async {
    final params = query.toQueryParameters();
    final response = await _dio.get(
      '/promotions/admin/packages',
      queryParameters: params.isEmpty ? null : params,
    );
    final data = response.data;
    final list = data is List
        ? data
        : data is Map<String, dynamic>
            ? (data['data'] ?? data['packages'] ?? [])
            : [];
    return (list as List)
        .map((e) => PromotionPackageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PromotionPackageEntity> createPackage(CreatePackageData data) async {
    final response = await _dio.post(
      '/promotions/admin/packages',
      data: data.toJson(),
    );
    return PromotionPackageModel.fromJson(_map(response.data));
  }

  @override
  Future<PromotionPackageEntity> updatePackage(
    String packageId,
    UpdatePackageData data,
  ) async {
    final response = await _dio.patch(
      '/promotions/admin/packages/$packageId',
      data: data.toJson(),
    );
    return PromotionPackageModel.fromJson(_map(response.data));
  }

  @override
  Future<PromotionPackageEntity> activatePackage(String packageId) async {
    final response =
        await _dio.patch('/promotions/admin/packages/$packageId/activate');
    return PromotionPackageModel.fromJson(_map(response.data));
  }

  @override
  Future<PromotionPackageEntity> deactivatePackage(String packageId) async {
    final response =
        await _dio.patch('/promotions/admin/packages/$packageId/deactivate');
    return PromotionPackageModel.fromJson(_map(response.data));
  }

  @override
  Future<void> deletePackage(String packageId) async {
    await _dio.delete('/promotions/admin/packages/$packageId');
  }

  @override
  Future<PromotedPostsPageEntity> getPromotedPosts(
    PromotedPostsQuery query,
  ) async {
    final response = await _dio.get(
      '/promotions/admin/posts',
      queryParameters: query.toQueryParameters(),
    );
    return PromotedPostsPageModel.fromJson(
      _unwrapPromotedPostsPage(response.data),
    );
  }

  @override
  Future<PromotedPostDetailEntity> getPromotedPostDetail(String postId) async {
    final response = await _dio.get('/promotions/admin/posts/$postId');
    return PromotedPostDetailModel.fromJson(_map(response.data));
  }

  @override
  Future<PostPromotionStatsEntity> getPromotedPostStats(
    String postId, {
    String? campaignId,
  }) async {
    final params = <String, dynamic>{};
    if (campaignId != null && campaignId.isNotEmpty) {
      params['campaignId'] = campaignId;
    }
    final response = await _dio.get(
      '/promotions/posts/$postId/stats',
      queryParameters: params.isEmpty ? null : params,
    );
    return PostPromotionStatsModel.fromJson(_map(response.data));
  }

  @override
  Future<PostPromotionStatsEntity> getAdminPromotedPostStats(
    String postId, {
    String? campaignId,
  }) async {
    final params = <String, dynamic>{};
    if (campaignId != null && campaignId.isNotEmpty) {
      params['campaignId'] = campaignId;
    }
    final response = await _dio.get(
      '/promotions/admin/posts/$postId/stats',
      queryParameters: params.isEmpty ? null : params,
    );
    return PostPromotionStatsModel.fromJson(_map(response.data));
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    throw Exception('Invalid promotions API response');
  }

  Map<String, dynamic> _unwrapPaginated(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid paginated promotions response');
    }

    // { data: { data: [...], meta: {} } }
    final nested = data['data'];
    if (nested is Map<String, dynamic> &&
        (nested['data'] is List || nested['posts'] is List)) {
      return nested;
    }

    // { data: [...], meta: {} } or { posts: [...], meta: {} }
    if (data['data'] is List || data['posts'] is List) {
      return data;
    }

    return data;
  }

  Map<String, dynamic> _unwrapPromotedPostsPage(dynamic data) {
    final page = _unwrapPaginated(data);
    if (page['data'] is List) return page;

    final posts = page['posts'];
    if (posts is List) {
      return {
        'data': posts,
        'meta': page['meta'] ?? const {},
      };
    }

    return page;
  }
}

class LocationIntelligenceRemoteDataSourceImpl
    implements LocationIntelligenceRemoteDataSource {
  const LocationIntelligenceRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<PaginatedResult<LocationPointEntity>> getLocationHistory({
    required String userId,
    required LocationHistoryQuery query,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/locations/history',
      queryParameters: query.toQueryParameters(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid location history response');
    }
    return LocationHistoryPageModel.fromJson(data);
  }

  @override
  Future<MovementPathEntity> getMovementPath({
    required String userId,
    required MovementPathQuery query,
  }) async {
    final response = await _dio.get(
      '/users/admin/$userId/locations/movements',
      queryParameters: query.toQueryParameters(),
    );
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid movement path response');
    }
    return MovementPathModel.fromJson(data);
  }
}
