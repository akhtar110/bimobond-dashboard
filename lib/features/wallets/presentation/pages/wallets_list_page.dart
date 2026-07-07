import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/wallets_list_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_list_widgets.dart';

class WalletsListPage extends StatefulWidget {
  const WalletsListPage({super.key});

  @override
  State<WalletsListPage> createState() => _WalletsListPageState();
}

class _WalletsListPageState extends State<WalletsListPage> {
  final _searchController = TextEditingController();
  final _minBalanceController = TextEditingController();
  final _maxBalanceController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    _minBalanceController.dispose();
    _maxBalanceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final dateFmt = DateFormat.yMMMd().add_jm();
    final metrics = walletsMetricsOf(context);

    return BlocBuilder<WalletsListBloc, WalletsListState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state is WalletsListLoading) {
          return const WalletsDashboardShell(
            scrollable: false,
            child: LoadingView(),
          );
        }
        if (state is WalletsListError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: walletL10nOr(context, 'retry', 'Retry'),
              onRetry: () =>
                  context.read<WalletsListBloc>().add(LoadWalletsListEvent()),
            ),
          );
        }
        if (state is! WalletsListLoaded) return const SizedBox.shrink();

        return WalletsDashboardShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletsListHeader(metrics: metrics),
              SizedBox(height: metrics.sectionGap),
              WalletsListToolbar(
                state: state,
                metrics: metrics,
                searchController: _searchController,
                minBalanceController: _minBalanceController,
                maxBalanceController: _maxBalanceController,
              ),
              if (state.isRefreshing) ...[
                SizedBox(height: metrics.sectionGap),
                const LinearProgressIndicator(minHeight: 2),
              ],
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: WalletsListTableCard(
                  state: state,
                  metrics: metrics,
                  dateFmt: dateFmt,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
