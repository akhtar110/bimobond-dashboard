import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../bloc/economy_bloc.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_overview_widgets.dart';

class EconomyHomePage extends StatelessWidget {
  const EconomyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EconomyBloc, EconomyState>(
      builder: (context, state) {
        if (state is EconomyLoading) {
          return const WalletsDashboardShell(child: LoadingView());
        }
        if (state is EconomyError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: 'Retry',
              onRetry: () => context.read<EconomyBloc>().add(LoadEconomyEvent()),
            ),
          );
        }
        if (state is! EconomyLoaded) return const SizedBox.shrink();

        final economy = state.economy;
        final overview = economy.overview;
        final metrics = walletsMetricsOf(context);

        return WalletsDashboardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletOverviewHeader(
                metrics: metrics,
                title: 'Economy Home',
                subtitle:
                    'Snapshot of wallets, catalogs, and coin economy activity.',
              ),
              SizedBox(height: metrics.sectionGap + 4),
              WalletOverviewKpiSection(
                overview: overview,
                showPackageStat: true,
              ),
              SizedBox(height: metrics.sectionGap * 2),
              WalletLedgerByTypeSection(
                items: overview.ledgerByType,
                metrics: metrics,
                title: 'Ledger activity (24h)',
              ),
              SizedBox(height: metrics.sectionGap * 2),
              WalletEconomySection(
                title: 'Active coin packages',
                subtitle: 'Bundles currently available for fiat purchase.',
                child: WalletCoinPackagesCatalog(packages: economy.coinPackages),
              ),
              SizedBox(height: metrics.sectionGap * 2),
              WalletEconomySection(
                title: 'Gift catalog',
                subtitle: 'Gift items priced in coins.',
                child: WalletGiftCatalogTable(items: economy.giftCatalog),
              ),
              SizedBox(height: metrics.sectionGap * 2),
              WalletEconomySection(
                title: 'Promotion packages',
                subtitle: 'Ad promotion budgets and impression tiers.',
                child: WalletPromoPackagesCatalog(
                  items: economy.promotionPackages,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
