import 'package:equatable/equatable.dart';

import '../../../analytics/domain/entities/analytics_entities.dart';
import '../../../auction_reports/domain/entities/auction_report_entities.dart';
import '../../../gift_reports/domain/entities/gift_report_entities.dart';
import '../../../promotions/domain/entities/promotion_overview_entity.dart';
import '../../../user_reports/domain/entities/user_report_entities.dart';
import '../../../wallets/domain/entities/wallet_entities.dart';

class MoneyDashboardEntity extends Equatable {
  const MoneyDashboardEntity({
    required this.economy,
    this.monetization,
    required this.giftReports,
    required this.promotions,
    required this.auctionReports,
    required this.userReports,
    this.commissionPercent,
    this.coinsPerPriceUnit,
  });

  final EconomyEntity economy;
  final AnalyticsMonetizationEntity? monetization;
  final GiftReportOverviewEntity giftReports;
  final PromotionOverviewEntity promotions;
  final AuctionReportOverviewEntity auctionReports;
  final UserReportsOverviewEntity userReports;
  final String? commissionPercent;
  final String? coinsPerPriceUnit;

  double get commissionEarningsCoins =>
      giftReports.periodCommissionCoins;

  @override
  List<Object?> get props => [
        economy,
        monetization,
        giftReports,
        promotions,
        auctionReports,
        userReports,
        commissionPercent,
        coinsPerPriceUnit,
      ];
}
