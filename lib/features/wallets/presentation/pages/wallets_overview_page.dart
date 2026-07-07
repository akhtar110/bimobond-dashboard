import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/wallet_overview_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_overview_widgets.dart';

class WalletsOverviewPage extends StatelessWidget {
  const WalletsOverviewPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);

    return BlocBuilder<WalletOverviewBloc, WalletOverviewState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state is WalletOverviewLoading) {
          return const WalletsDashboardShell(child: LoadingView());
        }
        if (state is WalletOverviewError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: walletL10nOr(context, 'retry', 'Retry'),
              onRetry: () => context
                  .read<WalletOverviewBloc>()
                  .add(LoadWalletOverviewEvent()),
            ),
          );
        }
        if (state is! WalletOverviewLoaded) return const SizedBox.shrink();

        final overview = state.overview;
        final metrics = walletsMetricsOf(context);

        return WalletsDashboardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletOverviewHeader(
                metrics: metrics,
                title: walletL10nOr(context, 'walletTitleWalletKpis', 'Wallet KPIs'),
                subtitle: walletL10nOr(context,
                  'walletSubtitleWalletKpis',
                  'Platform-wide wallet health, purchases, and recent ledger activity.',
                ),
              ),
              SizedBox(height: metrics.sectionGap + 4),
              WalletOverviewKpiSection(overview: overview),
              SizedBox(height: metrics.sectionGap * 2),
              WalletLedgerByTypeSection(
                items: overview.ledgerByType,
                metrics: metrics,
              ),
            ],
          ),
        );
      },
    );
  }
}
