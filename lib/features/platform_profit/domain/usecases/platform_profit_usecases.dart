import '../../../settings/domain/entities/economy_setting_entity.dart';
import '../../../settings/domain/usecases/economy_setting_usecases.dart';
import '../entities/platform_profit_entities.dart';
import '../repositories/platform_profit_repository.dart';

class GetMonetizationAnalyticsUseCase {
  const GetMonetizationAnalyticsUseCase(this._repository);
  final PlatformProfitRepository _repository;

  Future<MonetizationAnalyticsEntity> call(PlatformProfitQuery query) =>
      _repository.getMonetizationAnalytics(query);
}

class GetGiftRevenueOverviewUseCase {
  const GetGiftRevenueOverviewUseCase(this._repository);
  final PlatformProfitRepository _repository;

  Future<GiftRevenueOverviewEntity> call(PlatformProfitQuery query) =>
      _repository.getGiftRevenueOverview(query);
}

class GetPromotionRevenueUseCase {
  const GetPromotionRevenueUseCase(this._repository);
  final PlatformProfitRepository _repository;

  Future<PromotionRevenueEntity> call() =>
      _repository.getPromotionRevenueOverview();
}

/// Loads the three revenue streams in parallel, skipping the ones the
/// current role cannot access, plus the COINS_PER_PRICE_UNIT setting for
/// fiat conversion.
class LoadPlatformProfitUseCase {
  const LoadPlatformProfitUseCase({
    required GetMonetizationAnalyticsUseCase getMonetization,
    required GetGiftRevenueOverviewUseCase getGiftRevenue,
    required GetPromotionRevenueUseCase getPromotionRevenue,
    required GetEconomySettingUseCase getEconomySetting,
  })  : _getMonetization = getMonetization,
        _getGiftRevenue = getGiftRevenue,
        _getPromotionRevenue = getPromotionRevenue,
        _getEconomySetting = getEconomySetting;

  final GetMonetizationAnalyticsUseCase _getMonetization;
  final GetGiftRevenueOverviewUseCase _getGiftRevenue;
  final GetPromotionRevenueUseCase _getPromotionRevenue;
  final GetEconomySettingUseCase _getEconomySetting;

  Future<PlatformProfitEntity> call({
    required PlatformProfitQuery query,
    bool includeMonetization = false,
    bool includeGiftRevenue = false,
    bool includePromotionRevenue = false,
    bool includeCoinsSetting = false,
  }) async {
    final monetization = includeMonetization
        ? _getMonetization(query)
        : Future<MonetizationAnalyticsEntity?>.value(null);
    final giftRevenue = includeGiftRevenue
        ? _getGiftRevenue(query)
        : Future<GiftRevenueOverviewEntity?>.value(null);
    final promotionRevenue = includePromotionRevenue
        ? _getPromotionRevenue()
        : Future<PromotionRevenueEntity?>.value(null);
    final coinsSetting = includeCoinsSetting
        ? _coinsPerPriceUnit()
        : Future<double?>.value(null);

    final results = await Future.wait([
      monetization,
      giftRevenue,
      promotionRevenue,
      coinsSetting,
    ]);

    return PlatformProfitEntity(
      monetization: results[0] as MonetizationAnalyticsEntity?,
      giftRevenue: results[1] as GiftRevenueOverviewEntity?,
      promotionRevenue: results[2] as PromotionRevenueEntity?,
      coinsPerPriceUnit: results[3] as double?,
    );
  }

  /// Non-critical: a failed settings fetch must not break the page.
  Future<double?> _coinsPerPriceUnit() async {
    try {
      final setting =
          await _getEconomySetting(EconomySettingKeys.coinsPerPriceUnit);
      return setting.asDouble;
    } catch (_) {
      return null;
    }
  }
}
