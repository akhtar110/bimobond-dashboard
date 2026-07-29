import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../injection_container.dart' as di;
import '../../../auth/domain/utils/dashboard_permissions.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../money_dashboard/presentation/bloc/money_dashboard_bloc.dart';
import '../../../money_dashboard/presentation/pages/money_dashboard_page.dart';
import '../../../platform_profit/presentation/bloc/platform_profit_bloc.dart';
import '../../../platform_profit/presentation/pages/platform_profit_page.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../bloc/coin_packages_bloc.dart';
import '../bloc/economy_bloc.dart';
import '../bloc/fiat_purchases_bloc.dart';
import '../bloc/ledger_bloc.dart';
import '../bloc/wallet_overview_bloc.dart';
import '../bloc/wallets_list_bloc.dart';
import '../bloc/withdrawals_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import 'coin_packages_page.dart';
import 'economy_home_page.dart';
import 'fiat_purchases_page.dart';
import 'ledger_page.dart';
import 'wallets_list_page.dart';
import 'wallets_overview_page.dart';
import 'withdrawals_page.dart';

enum WalletsSection {
  moneyDashboard,
  economyHome,
  overview,
  walletsList,
  ledger,
  fiatPurchases,
  withdrawals,
  coinPackages,
  platformProfit,
}

class WalletsShellPage extends StatefulWidget {
  const WalletsShellPage({super.key});

  @override
  State<WalletsShellPage> createState() => _WalletsShellPageState();
}

class _WalletsShellPageState extends State<WalletsShellPage> {
  WalletsSection _section = WalletsSection.moneyDashboard;

  List<(WalletsSection, IconData, String)> _navItemsFor(
    List<UserRole> roles,
    BuildContext context,
  ) {
    final all = _walletsNavItems(context);
    if (canManageWallets(roles)) return all;
    return all
        .where((e) =>
            e.$1 == WalletsSection.moneyDashboard ||
            e.$1 == WalletsSection.overview ||
            e.$1 == WalletsSection.ledger ||
            e.$1 == WalletsSection.fiatPurchases ||
            e.$1 == WalletsSection.withdrawals ||
            (e.$1 == WalletsSection.platformProfit &&
                roles.contains(UserRole.moderator)))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final scheme = Theme.of(context).colorScheme;
    final roles = context.select<AuthBloc, List<UserRole>>((b) {
      final state = b.state;
      if (state is Authenticated) return state.user.roles;
      return const <UserRole>[];
    });
    final navItems = _navItemsFor(roles, context);

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<MoneyDashboardBloc>(param1: roles)
            ..add(const LoadMoneyDashboardEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<EconomyBloc>()..add(LoadEconomyEvent()),
        ),
        BlocProvider(
          create: (_) =>
              di.sl<WalletOverviewBloc>()..add(LoadWalletOverviewEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<WalletsListBloc>()..add(LoadWalletsListEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<LedgerBloc>()..add(LoadLedgerEvent()),
        ),
        BlocProvider(
          create: (_) =>
              di.sl<FiatPurchasesBloc>()..add(LoadFiatPurchasesEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<WithdrawalsBloc>()..add(LoadWithdrawalsEvent()),
        ),
        BlocProvider(
          create: (_) =>
              di.sl<CoinPackagesBloc>()..add(LoadCoinPackagesEvent()),
        ),
        BlocProvider(
          create: (_) => di.sl<PlatformProfitBloc>(param1: roles)
            ..add(const LoadPlatformProfit()),
        ),
      ],
      child: ColoredBox(
        color: scheme.surfaceContainerLowest,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final useTopNav = walletsUseTopNav(constraints.maxWidth);

            if (useTopNav) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _WalletsTopNav(
                    section: _section,
                    items: navItems,
                    onChanged: (s) => setState(() => _section = s),
                  ),
                  Expanded(
                    child: ClipRect(
                      child: _WalletsSectionView(
                        section: _section,
                        roles: roles,
                      ),
                    ),
                  ),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _WalletsSideNav(
                  section: _section,
                  items: navItems,
                  onChanged: (s) => setState(() => _section = s),
                ),
                Expanded(
                  child: ClipRect(
                    child: _WalletsSectionView(
                      section: _section,
                      roles: roles,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _WalletsSectionView extends StatelessWidget {
  const _WalletsSectionView({
    required this.section,
    required this.roles,
  });

  final WalletsSection section;
  final List<UserRole> roles;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final localeCode =
        context.read<SettingsCubit>().state.locale.languageCode;
    return switch (section) {
      WalletsSection.moneyDashboard => MoneyDashboardPage(
          key: ValueKey('wallets_section_money_dashboard_$localeCode'),
        ),
      WalletsSection.economyHome => EconomyHomePage(
          key: ValueKey('wallets_section_economy_$localeCode'),
        ),
      WalletsSection.overview => WalletsOverviewPage(
          key: ValueKey('wallets_section_overview_$localeCode'),
        ),
      WalletsSection.walletsList => WalletsListPage(
          key: ValueKey('wallets_section_list_$localeCode'),
        ),
      WalletsSection.ledger => LedgerPage(
          key: ValueKey('wallets_section_ledger_$localeCode'),
        ),
      WalletsSection.fiatPurchases => FiatPurchasesPage(
          key: ValueKey('wallets_section_fiat_$localeCode'),
        ),
      WalletsSection.withdrawals => WithdrawalsPage(
          key: ValueKey('wallets_section_withdrawals_$localeCode'),
        ),
      WalletsSection.coinPackages => CoinPackagesPage(
          key: ValueKey('wallets_section_packages_$localeCode'),
        ),
      WalletsSection.platformProfit => PlatformProfitPage(
          key: ValueKey('wallets_section_platform_profit_$localeCode'),
        ),
    };
  }
}

List<(WalletsSection, IconData, String)> _walletsNavItems(
  BuildContext context,
) {
  return [
    (
      WalletsSection.moneyDashboard,
      Icons.dashboard_outlined,
      walletL10nOr(context, 'walletNavMoneyDashboard', 'Money Dashboard'),
    ),
    (
      WalletsSection.economyHome,
      Icons.home_work_outlined,
      walletL10nOr(context, 'walletNavEconomyHome', 'Economy Home'),
    ),
    (
      WalletsSection.overview,
      Icons.dashboard_outlined,
      walletL10nOr(context, 'walletNavOverview', 'Overview'),
    ),
    (
      WalletsSection.walletsList,
      Icons.account_balance_wallet_outlined,
      walletL10nOr(context, 'walletNavWallets', 'Wallets'),
    ),
    (
      WalletsSection.ledger,
      Icons.receipt_long_outlined,
      walletL10nOr(context, 'walletNavLedger', 'Ledger'),
    ),
    (
      WalletsSection.fiatPurchases,
      Icons.payments_outlined,
      walletL10nOr(context, 'walletNavFiatPurchases', 'Fiat Purchases'),
    ),
    (
      WalletsSection.withdrawals,
      Icons.savings_outlined,
      walletL10nOr(context, 'walletNavWithdrawals', 'Withdrawals'),
    ),
    (
      WalletsSection.coinPackages,
      Icons.inventory_2_outlined,
      walletL10nOr(context, 'walletNavCoinPackages', 'Coin Packages'),
    ),
    (
      WalletsSection.platformProfit,
      Icons.workspace_premium_outlined,
      walletL10nOr(context,
        'walletNavPlatformProfit',
        'Platform Profit & Revenue',
      ),
    ),
  ];
}

class _WalletsSideNav extends StatelessWidget {
  const _WalletsSideNav({
    required this.section,
    required this.items,
    required this.onChanged,
  });

  final WalletsSection section;
  final List<(WalletsSection, IconData, String)> items;
  final ValueChanged<WalletsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 2,
      shadowColor: scheme.shadow.withValues(alpha: 0.12),
      color: scheme.surfaceContainerLow,
      child: SizedBox(
        width: 240,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                walletL10nOr(context, 'walletNavWallets', 'Wallets'),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                walletL10nOr(context,
                  'walletShellSubtitle',
                  'Coins economy & wallet admin',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 24),
              for (final item in items)
                _NavTile(
                  selected: section == item.$1,
                  icon: item.$2,
                  label: item.$3,
                  onTap: () => onChanged(item.$1),
                ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletsTopNav extends StatelessWidget {
  const _WalletsTopNav({
    required this.section,
    required this.items,
    required this.onChanged,
  });

  final WalletsSection section;
  final List<(WalletsSection, IconData, String)> items;
  final ValueChanged<WalletsSection> onChanged;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final scheme = Theme.of(context).colorScheme;
    final metrics = walletsMetricsOf(context);

    return Material(
      elevation: 1,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          metrics.pageHorizontalPadding,
          metrics.isMobile ? 6 : 8,
          metrics.pageHorizontalPadding,
          metrics.isMobile ? 6 : 8,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              walletL10nOr(context, 'walletNavWallets', 'Wallets'),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                    fontSize: metrics.isMobile ? 15 : 16,
                    height: 1.15,
                  ),
            ),
            SizedBox(height: metrics.isMobile ? 6 : 8),
            SizedBox(
              height: metrics.isMobile ? 34 : 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: items.length,
                separatorBuilder: (_, _) =>
                    SizedBox(width: metrics.toolbarFilterGap),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _TopNavChip(
                    selected: section == item.$1,
                    icon: item.$2,
                    label: item.$3,
                    compact: metrics.isMobile,
                    onTap: () => onChanged(item.$1),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopNavChip extends StatelessWidget {
  const _TopNavChip({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
    this.compact = false,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected ? scheme.primaryContainer : scheme.surface,
      borderRadius: BorderRadius.circular(compact ? 10 : 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 12,
            vertical: compact ? 6 : 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 10 : 12),
            border: Border.all(
              color: selected
                  ? scheme.primary
                  : scheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: compact ? 16 : 18,
                color: selected
                    ? scheme.onPrimaryContainer
                    : scheme.onSurfaceVariant,
              ),
              SizedBox(width: compact ? 6 : 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 12 : 13,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? scheme.primaryContainer : scheme.surface.withValues(alpha: 0),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
