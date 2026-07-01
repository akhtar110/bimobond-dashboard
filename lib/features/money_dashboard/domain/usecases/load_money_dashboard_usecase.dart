import '../../../analytics/domain/entities/analytics_entities.dart';
import '../../../analytics/domain/usecases/analytics_usecases.dart';
import '../../../auction_reports/domain/entities/auction_report_entities.dart';
import '../../../auction_reports/domain/usecases/get_auction_reports_overview.dart';
import '../../../gift_reports/domain/entities/gift_report_entities.dart';
import '../../../gift_reports/domain/usecases/get_gift_reports_overview_usecase.dart';
import '../../../promotions/domain/entities/promotion_overview_entity.dart';
import '../../../promotions/domain/usecases/promotion_usecases.dart';
import '../../../settings/domain/entities/economy_setting_entity.dart';
import '../../../settings/domain/usecases/economy_setting_usecases.dart';
import '../../../user_reports/domain/entities/user_report_entities.dart';
import '../../../user_reports/domain/usecases/get_user_reports_overview.dart';
import '../../../wallets/domain/entities/wallet_entities.dart';
import '../../../wallets/domain/usecases/wallet_usecases.dart';
import '../entities/money_dashboard_entity.dart';

class LoadMoneyDashboardUseCase {
  const LoadMoneyDashboardUseCase({
    required GetEconomyUseCase getEconomy,
    required GetAdminMonetizationAnalytics getMonetization,
    required GetGiftReportsOverview getGiftReportsOverview,
    required GetPromotionsOverviewUseCase getPromotionsOverview,
    required GetAuctionReportsOverview getAuctionReportsOverview,
    required GetUserReportsOverview getUserReportsOverview,
    required GetEconomySettingUseCase getEconomySetting,
  })  : _getEconomy = getEconomy,
        _getMonetization = getMonetization,
        _getGiftReportsOverview = getGiftReportsOverview,
        _getPromotionsOverview = getPromotionsOverview,
        _getAuctionReportsOverview = getAuctionReportsOverview,
        _getUserReportsOverview = getUserReportsOverview,
        _getEconomySetting = getEconomySetting;

  final GetEconomyUseCase _getEconomy;
  final GetAdminMonetizationAnalytics _getMonetization;
  final GetGiftReportsOverview _getGiftReportsOverview;
  final GetPromotionsOverviewUseCase _getPromotionsOverview;
  final GetAuctionReportsOverview _getAuctionReportsOverview;
  final GetUserReportsOverview _getUserReportsOverview;
  final GetEconomySettingUseCase _getEconomySetting;

  Future<MoneyDashboardEntity> call({
    int days = 30,
    bool includeMonetization = false,
    bool includeCommissionSettings = false,
  }) async {
    final periodQuery = GiftReportPeriodQuery(days: days);
    final auctionQuery = ReportPeriodQuery(days: days);
    final analyticsQuery = AnalyticsQuery(days: days);

    final economy = _getEconomy();
    final gifts = _getGiftReportsOverview(periodQuery);
    final promotions = _getPromotionsOverview();
    final auctionReports = _getAuctionReportsOverview(auctionQuery);
    final userReports = _getUserReportsOverview(days: days);
    final monetization = includeMonetization
        ? _getMonetization(analyticsQuery)
        : Future<AnalyticsMonetizationEntity?>.value(null);
    final commission = includeCommissionSettings
        ? _getEconomySetting(EconomySettingKeys.auctionCommissionPercent)
        : Future<EconomySettingEntity?>.value(null);
    final coinsPerUnit = includeCommissionSettings
        ? _getEconomySetting(EconomySettingKeys.coinsPerPriceUnit)
        : Future<EconomySettingEntity?>.value(null);

    final results = await Future.wait([
      economy,
      monetization,
      gifts,
      promotions,
      auctionReports,
      userReports,
      commission,
      coinsPerUnit,
    ]);

    return MoneyDashboardEntity(
      economy: results[0] as EconomyEntity,
      monetization: results[1] as AnalyticsMonetizationEntity?,
      giftReports: results[2] as GiftReportOverviewEntity,
      promotions: results[3] as PromotionOverviewEntity,
      auctionReports: results[4] as AuctionReportOverviewEntity,
      userReports: results[5] as UserReportsOverviewEntity,
      commissionPercent: (results[6] as EconomySettingEntity?)?.value,
      coinsPerPriceUnit: (results[7] as EconomySettingEntity?)?.value,
    );
  }
}
