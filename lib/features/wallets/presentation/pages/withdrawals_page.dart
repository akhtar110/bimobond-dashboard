import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../bloc/withdrawals_bloc.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_page_widgets.dart';
import '../widgets/withdrawals_page_widgets.dart';

class WithdrawalsPage extends StatelessWidget {
  const WithdrawalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final metrics = walletsMetricsOf(context);

    return BlocBuilder<WithdrawalsBloc, WithdrawalsState>(
      builder: (context, state) {
        if (state is WithdrawalsLoading) {
          return const WalletsDashboardShell(
            scrollable: false,
            child: LoadingView(),
          );
        }
        if (state is WithdrawalsError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: 'Retry',
              onRetry: () =>
                  context.read<WithdrawalsBloc>().add(LoadWithdrawalsEvent()),
            ),
          );
        }
        if (state is! WithdrawalsLoaded) return const SizedBox.shrink();

        final bloc = context.read<WithdrawalsBloc>();

        return WalletsDashboardShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletsPageHeader(
                metrics: metrics,
                title: 'Withdrawals',
                subtitle: 'Read-only — approve/reject API not available yet.',
              ),
              SizedBox(height: metrics.sectionGap),
              WithdrawalsToolbar(
                metrics: metrics,
                status: state.query.status,
                onStatusChanged: (status) => bloc.add(
                  WithdrawalsStatusFilterEvent(status),
                ),
                onClear: () => bloc.add(WithdrawalsStatusFilterEvent(null)),
              ),
              if (state.isRefreshing) ...[
                SizedBox(height: metrics.sectionGap),
                const LinearProgressIndicator(minHeight: 2),
              ],
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: WithdrawalsTableCard(
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
