import 'package:equatable/equatable.dart';

class PromotionOverviewEntity extends Equatable {
  const PromotionOverviewEntity({
    required this.totalCampaigns,
    required this.activeCampaigns,
    required this.pendingPaymentCampaigns,
    required this.pausedCampaigns,
    required this.completedCampaigns,
    required this.rejectedCampaigns,
    required this.totalPackages,
    required this.activePackages,
    required this.totalImpressions,
    required this.impressionsLast24Hours,
    required this.totalSpentCoins,
    required this.activeBudgetCoins,
    required this.activeSpentCoins,
  });

  final int totalCampaigns;
  final int activeCampaigns;
  final int pendingPaymentCampaigns;
  final int pausedCampaigns;
  final int completedCampaigns;
  final int rejectedCampaigns;
  final int totalPackages;
  final int activePackages;
  final int totalImpressions;
  final int impressionsLast24Hours;
  final double totalSpentCoins;
  final double activeBudgetCoins;
  final double activeSpentCoins;

  double get activeSpendRemainingCoins {
    final rem = activeBudgetCoins - activeSpentCoins;
    return rem > 0 ? rem : 0.0;
  }

  @override
  List<Object?> get props => [
        totalCampaigns,
        activeCampaigns,
        pendingPaymentCampaigns,
        pausedCampaigns,
        completedCampaigns,
        rejectedCampaigns,
        totalPackages,
        activePackages,
        totalImpressions,
        impressionsLast24Hours,
        totalSpentCoins,
        activeBudgetCoins,
        activeSpentCoins,
      ];
}
