import 'package:equatable/equatable.dart';

/// Date-range presets for the Platform Profit & Revenue filters.
enum PlatformProfitRangePreset {
  today,
  last7Days,
  last30Days,
  last90Days,
  custom;

  int get days => switch (this) {
        PlatformProfitRangePreset.today => 1,
        PlatformProfitRangePreset.last7Days => 7,
        PlatformProfitRangePreset.last30Days => 30,
        PlatformProfitRangePreset.last90Days => 90,
        PlatformProfitRangePreset.custom => 30,
      };
}

/// Period query: `from`/`to` win when provided, otherwise `days` (default 30).
class PlatformProfitQuery extends Equatable {
  const PlatformProfitQuery({
    this.from,
    this.to,
    this.days = 30,
  });

  final DateTime? from;
  final DateTime? to;
  final int days;

  Map<String, dynamic> toQueryParameters() {
    if (from != null) {
      return {
        'from': from!.toUtc().toIso8601String(),
        if (to != null) 'to': to!.toUtc().toIso8601String(),
      };
    }
    return {'days': days};
  }

  @override
  List<Object?> get props => [from, to, days];
}

/// One row of the monetization ledger grouped by transaction type.
class AccountingTypeEntity extends Equatable {
  const AccountingTypeEntity({
    required this.type,
    required this.count,
    required this.amountCoins,
  });

  final String type;
  final int count;
  final int amountCoins;

  @override
  List<Object?> get props => [type, count, amountCoins];
}

/// `GET /analytics/admin/monetization` (ADMIN only).
class MonetizationAnalyticsEntity extends Equatable {
  const MonetizationAnalyticsEntity({
    required this.from,
    required this.to,
    required this.giftTransactions,
    required this.grossCoins,
    required this.contributionCoins,
    required this.fiatPurchaseCount,
    required this.completedPurchaseVolume,
    required this.withdrawalRequests,
    required this.pendingWithdrawals,
    required this.totalBalanceCoins,
    required this.accountingByType,
  });

  final DateTime from;
  final DateTime to;

  final int giftTransactions;
  final int grossCoins;
  final int contributionCoins;

  final int fiatPurchaseCount;
  final double completedPurchaseVolume;

  final int withdrawalRequests;
  final int pendingWithdrawals;

  final int totalBalanceCoins;

  final List<AccountingTypeEntity> accountingByType;

  /// Platform's cut of gift sends: gross minus creator contribution.
  int get giftProfitCoins => grossCoins - contributionCoins;

  @override
  List<Object?> get props => [
        from,
        to,
        giftTransactions,
        grossCoins,
        contributionCoins,
        fiatPurchaseCount,
        completedPurchaseVolume,
        withdrawalRequests,
        pendingWithdrawals,
        totalBalanceCoins,
        accountingByType,
      ];
}

/// `GET /gift-reports/admin/overview` (ADMIN, MODERATOR).
class GiftRevenueOverviewEntity extends Equatable {
  const GiftRevenueOverviewEntity({
    required this.allTimeSpendCoins,
    required this.allTimeContributionCoins,
    required this.allTimeCommissionCoins,
    required this.transactions,
    required this.spendCoins,
    required this.contributionCoins,
    required this.commissionCoins,
    required this.toPost,
    required this.toLive,
    required this.toAuction,
  });

  final int allTimeSpendCoins;
  final int allTimeContributionCoins;
  final int allTimeCommissionCoins;

  final int transactions;
  final int spendCoins;
  final int contributionCoins;
  final int commissionCoins;

  final int toPost;
  final int toLive;
  final int toAuction;

  @override
  List<Object?> get props => [
        allTimeSpendCoins,
        allTimeContributionCoins,
        allTimeCommissionCoins,
        transactions,
        spendCoins,
        contributionCoins,
        commissionCoins,
        toPost,
        toLive,
        toAuction,
      ];
}

/// `GET /promotions/admin/overview` (ADMIN, MODERATOR). All-time totals.
class PromotionRevenueEntity extends Equatable {
  const PromotionRevenueEntity({
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.totalPackages,
    required this.activePackages,
    required this.totalImpressions,
    required this.last24HoursImpressions,
    required this.totalSpentCoins,
    required this.activeBudgetCoins,
    required this.activeSpentCoins,
  });

  final int totalCampaigns;
  final int activeCampaigns;

  final int totalPackages;
  final int activePackages;

  final int totalImpressions;
  final int last24HoursImpressions;

  final int totalSpentCoins;
  final int activeBudgetCoins;
  final int activeSpentCoins;

  @override
  List<Object?> get props => [
        totalCampaigns,
        activeCampaigns,
        totalPackages,
        activePackages,
        totalImpressions,
        last24HoursImpressions,
        totalSpentCoins,
        activeBudgetCoins,
        activeSpentCoins,
      ];
}

/// Aggregate of the three revenue streams plus the fiat conversion rate.
///
/// Any part may be null when the current user's role cannot access the
/// corresponding endpoint (monetization is ADMIN-only).
class PlatformProfitEntity extends Equatable {
  const PlatformProfitEntity({
    this.monetization,
    this.giftRevenue,
    this.promotionRevenue,
    this.coinsPerPriceUnit,
  });

  final MonetizationAnalyticsEntity? monetization;
  final GiftRevenueOverviewEntity? giftRevenue;
  final PromotionRevenueEntity? promotionRevenue;
  final double? coinsPerPriceUnit;

  /// All-time gift commission (platform profit from gifts).
  int get giftCommissionCoins => giftRevenue?.allTimeCommissionCoins ?? 0;

  /// All-time promotion revenue (100% platform income).
  int get promotionRevenueCoins => promotionRevenue?.totalSpentCoins ?? 0;

  /// totalPlatformRevenueCoins = giftCommissionCoins + promotionRevenueCoins
  int get totalPlatformRevenueCoins =>
      giftCommissionCoins + promotionRevenueCoins;

  bool get isEmpty =>
      monetization == null && giftRevenue == null && promotionRevenue == null;

  PlatformProfitEntity copyWith({
    MonetizationAnalyticsEntity? monetization,
    GiftRevenueOverviewEntity? giftRevenue,
    PromotionRevenueEntity? promotionRevenue,
    double? coinsPerPriceUnit,
  }) {
    return PlatformProfitEntity(
      monetization: monetization ?? this.monetization,
      giftRevenue: giftRevenue ?? this.giftRevenue,
      promotionRevenue: promotionRevenue ?? this.promotionRevenue,
      coinsPerPriceUnit: coinsPerPriceUnit ?? this.coinsPerPriceUnit,
    );
  }

  @override
  List<Object?> get props =>
      [monetization, giftRevenue, promotionRevenue, coinsPerPriceUnit];
}
