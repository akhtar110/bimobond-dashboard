import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/state_widgets.dart';
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/wallet_entities.dart';
import '../bloc/coin_packages_bloc.dart';
import '../utils/wallets_responsive.dart';
import '../widgets/coin_package_dialog.dart';
import '../widgets/coin_packages_page_widgets.dart';
import '../widgets/wallets_dashboard_widgets.dart';
import '../widgets/wallets_page_widgets.dart';

class CoinPackagesPage extends StatelessWidget {
  const CoinPackagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final metrics = walletsMetricsOf(context);
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<CoinPackagesBloc, CoinPackagesState>(
      listener: (context, state) {
        if (state is CoinPackagesLoaded && state.message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message!),
              backgroundColor: state.isError ? scheme.error : null,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is CoinPackagesLoading) {
          return const WalletsDashboardShell(
            scrollable: false,
            child: LoadingView(),
          );
        }
        if (state is CoinPackagesError) {
          return WalletsDashboardShell(
            child: ErrorView(
              message: state.message,
              retryLabel: 'Retry',
              onRetry: () =>
                  context.read<CoinPackagesBloc>().add(LoadCoinPackagesEvent()),
            ),
          );
        }
        if (state is! CoinPackagesLoaded) return const SizedBox.shrink();

        final canManage = context.select<AuthBloc, bool>((b) {
          final auth = b.state;
          if (auth is Authenticated) return canManageCoinPackages(auth.user.roles);
          return false;
        });

        return WalletsDashboardShell(
          scrollable: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              WalletsPageHeader(
                metrics: metrics,
                title: 'Coin packages',
                subtitle: 'Manage coin bundles available for fiat purchase.',
                trailing: canManage
                    ? FilledButton.icon(
                        onPressed: state.isSaving
                            ? null
                            : () => _openDialog(context, null),
                        icon: const Icon(Icons.add),
                        label: const Text('Create'),
                      )
                    : null,
              ),
              if (state.isSaving || state.isRefreshing) ...[
                SizedBox(height: metrics.sectionGap),
                const LinearProgressIndicator(minHeight: 2),
              ],
              SizedBox(height: metrics.sectionGap),
              Expanded(
                child: CoinPackagesTableCard(
                  packages: state.packages,
                  metrics: metrics,
                  canManage: canManage,
                  isSaving: state.isSaving,
                  onEdit: (pkg) => _openDialog(context, pkg),
                  onDelete: (pkg) => _confirmDelete(context, pkg),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openDialog(
    BuildContext context,
    CoinPackageEntity? existing,
  ) async {
    final result = await showCoinPackageDialog(context, existing: existing);
    if (result == null || !context.mounted) return;

    final bloc = context.read<CoinPackagesBloc>();
    if (result is CreateCoinPackageData) {
      bloc.add(CreateCoinPackageEvent(result));
    } else if (result is UpdateCoinPackageData && existing != null) {
      bloc.add(UpdateCoinPackageEvent(existing.id, result));
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    CoinPackageEntity pkg,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete package?'),
        content: Text(
          'Delete "${pkg.name}"? Packages with purchase history should be deactivated instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<CoinPackagesBloc>().add(DeleteCoinPackageEvent(pkg.id));
    }
  }
}
