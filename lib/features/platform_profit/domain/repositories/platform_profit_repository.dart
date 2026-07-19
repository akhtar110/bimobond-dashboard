import '../entities/platform_profit_entities.dart';

abstract class PlatformProfitRepository {
  /// `GET /analytics/admin/monetization` — ADMIN only.
  Future<MonetizationAnalyticsEntity> getMonetizationAnalytics(
    PlatformProfitQuery query,
  );

  /// `GET /gift-reports/admin/overview` — ADMIN, MODERATOR.
  Future<GiftRevenueOverviewEntity> getGiftRevenueOverview(
    PlatformProfitQuery query,
  );

  /// `GET /promotions/admin/overview` — ADMIN, MODERATOR. All-time totals.
  Future<PromotionRevenueEntity> getPromotionRevenueOverview();
}
