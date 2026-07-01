import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../bloc/ledger_bloc.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/ledger_page_widgets.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_page_widgets.dart';

class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final metrics = walletsMetricsOf(context);

    return BlocBuilder<LedgerBloc, LedgerState>(
      builder: (context, state) {
        if (state is LedgerLoading) {
          return const WalletsDashboardShell(
            scrollable: false,
            child: LoadingView(),
          );
        }
        if (state is LedgerError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: 'Retry',
              onRetry: () => context.read<LedgerBloc>().add(LoadLedgerEvent()),
            ),
          );
        }
        if (state is! LedgerLoaded) return const SizedBox.shrink();

        final bloc = context.read<LedgerBloc>();

        return WalletsDashboardShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletsPageHeader(
                metrics: metrics,
                title: 'Global ledger',
                subtitle: 'Filter by entry type and credit/debit action.',
              ),
              SizedBox(height: metrics.sectionGap),
              LedgerToolbar(
                state: state,
                metrics: metrics,
                type: state.query.type,
                action: state.query.action,
                onTypeChanged: (type) => bloc.add(
                  LedgerFilterChangedEvent(
                    state.query.copyWith(
                      type: type,
                      clearType: type == null,
                    ),
                  ),
                ),
                onActionChanged: (action) => bloc.add(
                  LedgerFilterChangedEvent(
                    state.query.copyWith(
                      action: action,
                      clearAction: action == null,
                    ),
                  ),
                ),
                onClear: () => bloc.add(
                  LedgerFilterChangedEvent(
                    state.query.copyWith(clearType: true, clearAction: true),
                  ),
                ),
              ),
              if (state.isRefreshing) ...[
                SizedBox(height: metrics.sectionGap),
                const LinearProgressIndicator(minHeight: 2),
              ],
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: LedgerTableCard(
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
