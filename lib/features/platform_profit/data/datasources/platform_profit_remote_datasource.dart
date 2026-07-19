import 'package:dio/dio.dart';

import '../../domain/entities/platform_profit_entities.dart';
import '../models/platform_profit_models.dart';

abstract class PlatformProfitRemoteDataSource {
  Future<MonetizationAnalyticsEntity> getMonetizationAnalytics(
    PlatformProfitQuery query,
  );

  Future<GiftRevenueOverviewEntity> getGiftRevenueOverview(
    PlatformProfitQuery query,
  );

  Future<PromotionRevenueEntity> getPromotionRevenueOverview();
}

class PlatformProfitRemoteDataSourceImpl
    implements PlatformProfitRemoteDataSource {
  const PlatformProfitRemoteDataSourceImpl(this._dio);
  final Dio _dio;

  @override
  Future<MonetizationAnalyticsEntity> getMonetizationAnalytics(
    PlatformProfitQuery query,
  ) async {
    final response = await _dio.get(
      '/analytics/admin/monetization',
      queryParameters: query.toQueryParameters(),
    );
    return MonetizationAnalyticsModel.fromJson(_map(response.data));
  }

  @override
  Future<GiftRevenueOverviewEntity> getGiftRevenueOverview(
    PlatformProfitQuery query,
  ) async {
    final response = await _dio.get(
      '/gift-reports/admin/overview',
      queryParameters: query.toQueryParameters(),
    );
    return GiftRevenueOverviewModel.fromJson(_map(response.data));
  }

  @override
  Future<PromotionRevenueEntity> getPromotionRevenueOverview() async {
    final response = await _dio.get('/promotions/admin/overview');
    return PromotionRevenueModel.fromJson(_map(response.data));
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map<String, dynamic>) {
      if (data['data'] is Map<String, dynamic>) {
        return data['data'] as Map<String, dynamic>;
      }
      return data;
    }
    throw Exception('Invalid platform profit API response');
  }
}
