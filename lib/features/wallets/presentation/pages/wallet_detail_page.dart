import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/wallet_detail_bloc.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/adjust_balance_dialog.dart';
import '../widgets/wallet_detail_page_widgets.dart';

class WalletDetailPage extends StatelessWidget {
  const WalletDetailPage({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    return PersistentBlocProvider<WalletDetailBloc>(
      debugLabel: 'WalletDetailRoute',
      create: () => di.sl<WalletDetailBloc>()..add(LoadWalletDetailEvent(userId)),
      child: WalletDetailView(userId: userId),
    );
  }
}

class WalletDetailView extends StatefulWidget {
  const WalletDetailView({super.key, required this.userId});

  final String userId;

  @override
  State<WalletDetailView> createState() => _WalletDetailViewState();
}

class _WalletDetailViewState extends State<WalletDetailView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openAdjustDialog() async {
    final data = await showAdjustBalanceDialog(context);
    if (data == null || !mounted) return;
    context.read<WalletDetailBloc>().add(AdjustWalletBalanceEvent(data));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final metrics = walletsMetricsOf(context);

    return BlocConsumer<WalletDetailBloc, WalletDetailState>(
      listener: (context, state) {
        if (state is WalletDetailLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: state.isError ? scheme.error : null,
            ),
          );
        }
      },
      builder: (context, state) {
        final canAdjust = context.select<AuthBloc, bool>((b) {
          final auth = b.state;
          if (auth is Authenticated) return canAdjustWallets(auth.user.roles);
          return false;
        });

        return Scaffold(
          backgroundColor: scheme.surfaceContainerLowest,
          appBar: AppBar(
            elevation: 0,
            scrolledUnderElevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            foregroundColor: scheme.onSurface,
            iconTheme: IconThemeData(color: scheme.onSurface),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: scheme.onSurface,
                size: 20,
              ),
              onPressed: () => Navigator.maybePop(context),
            ),
            title: Text(
              'Wallet detail',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
            ),
            centerTitle: false,
            actions: [
              if (state is WalletDetailLoaded && canAdjust)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: FilledButton.tonalIcon(
                    onPressed: state.isAdjusting ? null : _openAdjustDialog,
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Adjust balance'),
                  ),
                ),
            ],
          ),
          body: switch (state) {
            WalletDetailLoading() => const LoadingView(),
            WalletDetailError(:final message) => ErrorView(
                message: message,
                retryLabel: 'Retry',
                onRetry: () => context
                    .read<WalletDetailBloc>()
                    .add(LoadWalletDetailEvent(widget.userId)),
              ),
            WalletDetailLoaded(:final detail, :final isAdjusting) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isAdjusting)
                    const LinearProgressIndicator(minHeight: 2),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      metrics.pageHorizontalPadding,
                      metrics.pageTopPadding,
                      metrics.pageHorizontalPadding,
                      metrics.sectionGap,
                    ),
                    child: WalletDetailSummaryCard(detail: detail),
                  ),
                  WalletDetailTabBar(
                    controller: _tabController,
                    ledgerCount: detail.accountings.length,
                    purchasesCount: detail.fiatPurchases.length,
                    withdrawalsCount: detail.withdrawals.length,
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        WalletDetailLedgerTab(
                          entries: detail.accountings,
                          dateFmt: dateFmt,
                          metrics: metrics,
                        ),
                        WalletDetailPurchasesTab(
                          purchases: detail.fiatPurchases,
                          dateFmt: dateFmt,
                          metrics: metrics,
                        ),
                        WalletDetailWithdrawalsTab(
                          withdrawals: detail.withdrawals,
                          dateFmt: dateFmt,
                          metrics: metrics,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            _ => const SizedBox.shrink(),
          },
        );
      },
    );
  }
}
