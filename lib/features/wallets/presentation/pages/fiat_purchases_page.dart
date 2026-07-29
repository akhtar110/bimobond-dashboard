import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/wallet_entities.dart';
import '../bloc/fiat_purchases_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/fiat_purchases_page_widgets.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_page_widgets.dart';

class FiatPurchasesPage extends StatefulWidget {
  const FiatPurchasesPage({super.key});

  @override
  State<FiatPurchasesPage> createState() => _FiatPurchasesPageState();
}

class _FiatPurchasesPageState extends State<FiatPurchasesPage> {
  UserEntity? _selectedUser;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final dateFmt = DateFormat.yMMMd().add_Hm();
    final metrics = walletsMetricsOf(context);

    return BlocBuilder<FiatPurchasesBloc, FiatPurchasesState>(
      builder: (context, state) {
        final l10n = context.l10n;
        if (state is FiatPurchasesLoading) {
          return const WalletsDashboardShell(
            scrollable: false,
            child: LoadingView(),
          );
        }
        if (state is FiatPurchasesError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: walletL10nOr(context, 'retry', 'Retry'),
              onRetry: () =>
                  context.read<FiatPurchasesBloc>().add(LoadFiatPurchasesEvent()),
            ),
          );
        }
        if (state is! FiatPurchasesLoaded) return const SizedBox.shrink();

        final bloc = context.read<FiatPurchasesBloc>();

        return WalletsDashboardShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletsPageHeader(
                metrics: metrics,
                title: walletL10nOr(context, 'walletTitleFiatPurchases', 'Fiat purchases'),
              ),
              SizedBox(height: metrics.sectionGap),
              FiatPurchasesToolbar(
                state: state,
                metrics: metrics,
                selectedUser: _selectedUser,
                status: state.query.status,
                provider: state.query.provider,
                onUserSelected: (user) {
                  setState(() => _selectedUser = user);
                  bloc.add(
                    FiatPurchasesFilterChangedEvent(
                      state.query.copyWith(
                        userId: user?.id,
                        clearUserId: user == null,
                      ),
                    ),
                  );
                },
                onStatusChanged: (status) => bloc.add(
                  FiatPurchasesFilterChangedEvent(
                    state.query.copyWith(
                      status: status,
                      clearStatus: status == null,
                    ),
                  ),
                ),
                onProviderChanged: (provider) => bloc.add(
                  FiatPurchasesFilterChangedEvent(
                    state.query.copyWith(
                      provider: provider,
                      clearProvider: provider == null,
                    ),
                  ),
                ),
                onClear: () {
                  setState(() => _selectedUser = null);
                  bloc.add(
                    FiatPurchasesFilterChangedEvent(const FiatPurchasesQuery()),
                  );
                },
              ),
              if (state.isRefreshing) ...[
                SizedBox(height: metrics.sectionGap),
                const LinearProgressIndicator(minHeight: 2),
              ],
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: FiatPurchasesTableCard(
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
