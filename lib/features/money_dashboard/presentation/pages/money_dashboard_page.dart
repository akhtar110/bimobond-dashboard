import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/widgets/dashboard/analytics_card.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../wallets/presentation/utils/wallets_responsive.dart';
import '../../../wallets/presentation/widgets/wallets_dashboard_widgets.dart';
import '../../../wallets/presentation/widgets/wallets_overview_widgets.dart';
import '../../domain/entities/money_dashboard_entity.dart';
import '../bloc/money_dashboard_bloc.dart';
import '../widgets/money_dashboard_widgets.dart';

class MoneyDashboardPage extends StatelessWidget {
  const MoneyDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MoneyDashboardBloc, MoneyDashboardState>(
      builder: (context, state) {
        if (state is MoneyDashboardLoading || state is MoneyDashboardInitial) {
          return const WalletsDashboardShell(child: LoadingView());
        }
        if (state is MoneyDashboardError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: 'Retry',
              onRetry: () => context
                  .read<MoneyDashboardBloc>()
                  .add(const LoadMoneyDashboardEvent()),
            ),
          );
        }
        if (state is! MoneyDashboardLoaded) return const SizedBox.shrink();
        return _MoneyDashboardBody(data: state.data);
      },
    );
  }
}

class _MoneyDashboardBody extends StatelessWidget {
  const _MoneyDashboardBody({required this.data});

  final MoneyDashboardEntity data;

  @override
  Widget build(BuildContext context) {
    final overview = data.economy.overview;
    final gifts = data.giftReports;
    final promos = data.promotions;
    final auctions = data.auctionReports;
    final metrics = walletsMetricsOf(context);
    final gap = metrics.sectionGap * 2;

    return WalletsDashboardShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WalletOverviewHeader(
            metrics: metrics,
            title: 'Money Dashboard',
            subtitle:
                'Unified view of wallets, purchases, gifts, promotions, and auctions.',
          ),
          SizedBox(height: gap),
          MoneyDashboardMetricsBlock(
            metrics: metrics,
            title: 'Wallet KPIs',
            subtitle: 'Core wallet health and fiat purchase metrics.',
            cards: [
              AnalyticsCard(
                label: 'Total wallets',
                value: '${overview.walletsTotal}',
                icon: Icons.account_balance_wallet_outlined,
              ),
              AnalyticsCard(
                label: 'Total balance',
                value: CoinFormat.coins(overview.totalBalanceCoins),
                icon: Icons.monetization_on_outlined,
                highlight: true,
              ),
              AnalyticsCard(
                label: 'Purchase volume',
                value: CoinFormat.purchaseVolume(
                  overview.completedPurchaseVolume,
                ),
                icon: Icons.payments_outlined,
              ),
              AnalyticsCard(
                label: 'Pending withdrawals',
                value: '${overview.withdrawalsPending}',
                icon: Icons.hourglass_top_outlined,
              ),
            ],
          ),
          SizedBox(height: gap),
          MoneyDashboardMetricsBlock(
            metrics: metrics,
            title: 'Revenue streams',
            subtitle: 'Gift, commission, promotion, and auction coin flows.',
            cards: [
              AnalyticsCard(
                label: 'Gift gross (period)',
                value: CoinFormat.coins(gifts.periodSpendCoins),
                icon: Icons.card_giftcard_outlined,
              ),
              AnalyticsCard(
                label: 'Gift contribution',
                value: CoinFormat.coins(gifts.periodContributionCoins),
                icon: Icons.volunteer_activism_outlined,
              ),
              AnalyticsCard(
                label: 'Commission earnings',
                value: CoinFormat.coins(data.commissionEarningsCoins),
                subtitle: data.commissionPercent != null
                    ? '${data.commissionPercent}% commission'
                    : null,
                icon: Icons.percent_outlined,
              ),
              AnalyticsCard(
                label: 'Promotion spend',
                value: CoinFormat.coins(promos.totalSpentCoins),
                icon: Icons.campaign_outlined,
              ),
              AnalyticsCard(
                label: 'Auction gift spend',
                value: CoinFormat.coins(auctions.totalGiftSpendCoins),
                icon: Icons.gavel_outlined,
              ),
              AnalyticsCard(
                label: 'Active promo budget',
                value: CoinFormat.coins(promos.activeBudgetCoins),
                icon: Icons.trending_up_outlined,
              ),
            ],
          ),
          if (data.monetization != null) ...[
            SizedBox(height: gap),
            MoneyDashboardMetricsBlock(
              metrics: metrics,
              title: 'Fiat & ledger',
              subtitle: 'Fiat purchase counts and platform-wide balances.',
              cards: [
                AnalyticsCard(
                  label: 'Fiat purchases',
                  value: '${data.monetization!.fiatPurchaseCount}',
                  icon: Icons.shopping_cart_outlined,
                ),
                AnalyticsCard(
                  label: 'Purchase volume',
                  value: CoinFormat.purchaseVolume(
                    data.monetization!.completedPurchaseVolume,
                  ),
                  icon: Icons.attach_money,
                ),
                AnalyticsCard(
                  label: 'Wallet balances (platform)',
                  value: CoinFormat.coins(
                    data.monetization!.totalBalanceCoins,
                  ),
                  icon: Icons.account_balance_outlined,
                ),
              ],
            ),
          ],
          SizedBox(height: gap),
          MoneyDashboardTopGiftsSection(
            gifts: gifts.topGiftsByRevenue,
            metrics: metrics,
          ),
          SizedBox(height: gap),
          MoneyDashboardTopUsersSection(
            users: data.userReports.topUsers.byFollowers,
            metrics: metrics,
          ),
          SizedBox(height: gap),
          MoneyDashboardTopAuctionsSection(
            auctions: auctions.topByTotal,
            metrics: metrics,
          ),
        ],
      ),
    );
  }
}
