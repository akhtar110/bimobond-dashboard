import '../../domain/entities/platform_profit_entities.dart';

class AccountingTypeModel extends AccountingTypeEntity {
  const AccountingTypeModel({
    required super.type,
    required super.count,
    required super.amountCoins,
  });

  factory AccountingTypeModel.fromJson(Map<String, dynamic> json) {
    return AccountingTypeModel(
      type: json['type']?.toString() ?? '',
      count: _toInt(json['count']),
      amountCoins: _toInt(json['amountCoins'] ?? json['amount']),
    );
  }
}

class MonetizationAnalyticsModel extends MonetizationAnalyticsEntity {
  const MonetizationAnalyticsModel({
    required super.from,
    required super.to,
    required super.giftTransactions,
    required super.grossCoins,
    required super.contributionCoins,
    required super.fiatPurchaseCount,
    required super.completedPurchaseVolume,
    required super.withdrawalRequests,
    required super.pendingWithdrawals,
    required super.totalBalanceCoins,
    required super.accountingByType,
  });

  factory MonetizationAnalyticsModel.fromJson(Map<String, dynamic> json) {
    final period = _section(json, 'period');
    final gifts = _section(json, 'gifts');
    final fiat = _section(json, 'fiatPurchases');
    final withdrawals = _section(json, 'withdrawals');
    final wallets = _section(json, 'wallets');

    final rawLedger = json['accountingByType'];
    final ledger = <AccountingTypeEntity>[
      if (rawLedger is List)
        for (final item in rawLedger)
          if (item is Map<String, dynamic>) AccountingTypeModel.fromJson(item),
    ];

    return MonetizationAnalyticsModel(
      from: _parseDate(period['from'] ?? json['from']),
      to: _parseDate(period['to'] ?? json['to']),
      giftTransactions: _toInt(gifts['transactions'] ?? gifts['count']),
      grossCoins: _toInt(gifts['grossCoins'] ?? gifts['gross']),
      contributionCoins:
          _toInt(gifts['contributionCoins'] ?? gifts['contribution']),
      fiatPurchaseCount: _toInt(fiat['count']),
      completedPurchaseVolume: _toDouble(
        fiat['completedPurchaseVolume'] ?? fiat['completedVolume'],
      ),
      withdrawalRequests:
          _toInt(withdrawals['requestsInPeriod'] ?? withdrawals['count']),
      pendingWithdrawals: _toInt(withdrawals['pending']),
      totalBalanceCoins:
          _toInt(wallets['totalBalanceCoins'] ?? wallets['totalBalance']),
      accountingByType: ledger,
    );
  }
}

class GiftRevenueOverviewModel extends GiftRevenueOverviewEntity {
  const GiftRevenueOverviewModel({
    required super.allTimeSpendCoins,
    required super.allTimeContributionCoins,
    required super.allTimeCommissionCoins,
    required super.transactions,
    required super.spendCoins,
    required super.contributionCoins,
    required super.commissionCoins,
    required super.toPost,
    required super.toLive,
    required super.toAuction,
  });

  factory GiftRevenueOverviewModel.fromJson(Map<String, dynamic> json) {
    // Some backend versions nest all-time totals in `catalog`, others in
    // `totals`.
    final catalog = _section(json, 'catalog').isNotEmpty
        ? _section(json, 'catalog')
        : _section(json, 'totals');
    final engagement = _section(json, 'periodEngagement');

    final allTimeSpend = _toInt(catalog['allTimeSpendCoins']);
    final allTimeContribution = _toInt(catalog['allTimeContributionCoins']);

    return GiftRevenueOverviewModel(
      allTimeSpendCoins: allTimeSpend,
      allTimeContributionCoins: allTimeContribution,
      allTimeCommissionCoins: _toInt(
        catalog['allTimeCommissionCoins'],
        fallback: allTimeSpend - allTimeContribution,
      ),
      transactions: _toInt(engagement['transactions']),
      spendCoins: _toInt(engagement['spendCoins']),
      contributionCoins: _toInt(engagement['contributionCoins']),
      commissionCoins: _toInt(
        engagement['commissionCoins'],
        fallback: _toInt(engagement['spendCoins']) -
            _toInt(engagement['contributionCoins']),
      ),
      toPost: _toInt(engagement['toPost']),
      toLive: _toInt(engagement['toLive']),
      toAuction: _toInt(engagement['toAuction']),
    );
  }
}

class PromotionRevenueModel extends PromotionRevenueEntity {
  const PromotionRevenueModel({
    required super.totalCampaigns,
    required super.activeCampaigns,
    required super.totalPackages,
    required super.activePackages,
    required super.totalImpressions,
    required super.last24HoursImpressions,
    required super.totalSpentCoins,
    required super.activeBudgetCoins,
    required super.activeSpentCoins,
  });

  factory PromotionRevenueModel.fromJson(Map<String, dynamic> json) {
    final campaigns = _section(json, 'campaigns');
    final packages = _section(json, 'packages');
    final impressions = _section(json, 'impressions');
    final revenue = _section(json, 'revenue');

    return PromotionRevenueModel(
      totalCampaigns: _toInt(campaigns['total']),
      activeCampaigns: _toInt(campaigns['active']),
      totalPackages: _toInt(packages['total']),
      activePackages: _toInt(packages['active']),
      totalImpressions: _toInt(impressions['total']),
      last24HoursImpressions: _toInt(impressions['last24Hours']),
      totalSpentCoins: _toInt(revenue['totalSpentCoins']),
      activeBudgetCoins: _toInt(revenue['activeBudgetCoins']),
      activeSpentCoins: _toInt(revenue['activeSpentCoins']),
    );
  }
}

Map<String, dynamic> _section(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map<String, dynamic>) return value;
  return const {};
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is double) return value.round();
  return int.tryParse(value?.toString() ?? '') ??
      double.tryParse(value?.toString() ?? '')?.round() ??
      fallback;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? fallback;
}

DateTime _parseDate(dynamic value) {
  if (value is DateTime) return value.toUtc();
  return DateTime.tryParse(value?.toString() ?? '')?.toUtc() ??
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
