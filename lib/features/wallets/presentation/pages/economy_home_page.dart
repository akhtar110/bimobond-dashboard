import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/economy_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_overview_widgets.dart';

class EconomyHomePage extends StatelessWidget {
  const EconomyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);

    return BlocBuilder<EconomyBloc, EconomyState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state is EconomyLoading) {
          return const WalletsDashboardShell(child: LoadingView());
        }
        if (state is EconomyError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: walletL10nOr(context, 'retry', 'Retry'),
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
                title: walletL10nOr(
                  context,
                  'walletTitleEconomyHome',
                  'Economy Home',
                ),
              ),
              SizedBox(height: metrics.sectionGap),
              WalletOverviewKpiSection(
                overview: overview,
                showPackageStat: true,
              ),
              SizedBox(height: metrics.sectionGap),
              WalletLedgerByTypeSection(
                items: overview.ledgerByType,
                metrics: metrics,
                title: walletL10nOr(
                  context,
                  'walletSectionLedgerActivity24h',
                  'Ledger activity (24h)',
                ),
              ),
              SizedBox(height: metrics.sectionGap),
              WalletEconomySection(
                title: walletL10nOr(
                  context,
                  'walletSectionActiveCoinPackages',
                  'Active coin packages',
                ),
                child: WalletCoinPackagesCatalog(packages: economy.coinPackages),
              ),
              SizedBox(height: metrics.sectionGap),
              WalletEconomySection(
                title: walletL10nOr(
                  context,
                  'walletSectionGiftCatalog',
                  'Gift catalog',
                ),
                child: WalletGiftCatalogTable(items: economy.giftCatalog),
              ),
              SizedBox(height: metrics.sectionGap),
              WalletEconomySection(
                title: walletL10nOr(
                  context,
                  'walletSectionPromotionPackages',
                  'Promotion packages',
                ),
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
