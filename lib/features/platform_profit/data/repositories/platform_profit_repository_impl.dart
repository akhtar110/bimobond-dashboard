import '../../domain/entities/platform_profit_entities.dart';
import '../../domain/repositories/platform_profit_repository.dart';
import '../datasources/platform_profit_remote_datasource.dart';

class PlatformProfitRepositoryImpl implements PlatformProfitRepository {
  const PlatformProfitRepositoryImpl(this._remote);
  final PlatformProfitRemoteDataSource _remote;

  @override
  Future<MonetizationAnalyticsEntity> getMonetizationAnalytics(
    PlatformProfitQuery query,
  ) =>
      _remote.getMonetizationAnalytics(query);

  @override
  Future<GiftRevenueOverviewEntity> getGiftRevenueOverview(
    PlatformProfitQuery query,
  ) =>
      _remote.getGiftRevenueOverview(query);

  @override
  Future<PromotionRevenueEntity> getPromotionRevenueOverview() =>
      _remote.getPromotionRevenueOverview();
}
