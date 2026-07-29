import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/responsive_stats_grid.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/wallet_entities.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_page_widgets.dart';

List<Widget> walletOverviewKpiCards(
  BuildContext context,
  WalletOverviewEntity overview, {
  bool showPackageStat = false,
}) {
  final metrics = walletsMetricsOf(context);

  if (showPackageStat) {
    return [
      WalletKpiCard(
        metrics: metrics,
        label: walletL10nOr(context, 'walletKpiCoinPackages', 'Coin packages'),
        value: walletL10nArgs(
          context,
          'walletKpiPackagesActive',
          {'active': '${overview.packagesActive}'},
          '${overview.packagesActive} active',
        ),
        icon: Icons.inventory_2_outlined,
      ),
    ];
  }

  return [
    WalletKpiCard(
      metrics: metrics,
      label: walletL10nOr(context, 'walletKpiTotalWallets', 'Total wallets'),
      value: '${overview.walletsTotal}',
      icon: Icons.account_balance_wallet_outlined,
    ),
    WalletKpiCard(
      metrics: metrics,
      label: walletL10nOr(context, 'walletKpiTotalBalance', 'Total balance'),
      value: CoinFormat.coins(overview.totalBalanceCoins),
      icon: Icons.monetization_on_outlined,
      highlight: true,
    ),
    WalletKpiCard(
      metrics: metrics,
      label: walletL10nOr(context, 'walletKpiFiatPurchases', 'Fiat purchases'),
      value: '${overview.fiatPurchasesTotal}',
      icon: Icons.shopping_cart_outlined,
    ),
    WalletKpiCard(
      metrics: metrics,
      label: walletL10nOr(context, 'walletKpiPurchaseVolume', 'Purchase volume'),
      value: CoinFormat.purchaseVolume(overview.completedPurchaseVolume),
      icon: Icons.payments_outlined,
    ),
    WalletKpiCard(
      metrics: metrics,
      label: walletL10nOr(
        context,
        'walletKpiPendingWithdrawals',
        'Pending withdrawals',
      ),
      value: '${overview.withdrawalsPending}',
      icon: Icons.hourglass_top_outlined,
    ),
    WalletKpiCard(
      metrics: metrics,
      label: walletL10nOr(
        context,
        'walletKpiLedgerEntries24h',
        'Ledger entries (24h)',
      ),
      value: '${overview.ledgerEntriesLast24Hours}',
      icon: Icons.receipt_long_outlined,
    ),
  ];
}

/// Dense KPI tile sized from [WalletsLayoutMetrics] (wallet module only).
class WalletKpiCard extends StatelessWidget {
  const WalletKpiCard({
    super.key,
    required this.metrics,
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
  });

  final WalletsLayoutMetrics metrics;
  final String label;
  final String value;
  final IconData icon;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = highlight ? scheme.primaryContainer : scheme.surface;
    final fg = highlight ? scheme.onPrimaryContainer : scheme.onSurface;

    return Material(
      color: bg,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.compactCardRadius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Padding(
        padding: EdgeInsets.all(metrics.analyticsCardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: metrics.analyticsIconBoxSize,
              height: metrics.analyticsIconBoxSize,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: highlight
                    ? scheme.primary.withValues(alpha: 0.14)
                    : scheme.primaryContainer.withValues(alpha: 0.65),
                borderRadius:
                    BorderRadius.circular(metrics.compactCardRadius - 2),
              ),
              child: Icon(
                icon,
                size: metrics.analyticsIconSize,
                color: scheme.primary,
              ),
            ),
            SizedBox(width: metrics.statsGridSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontSize: metrics.analyticsLabelFontSize,
                          height: 1.2,
                        ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: fg,
                            fontSize: metrics.analyticsValueFontSize,
                            height: 1.1,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WalletOverviewHeader extends StatelessWidget {
  const WalletOverviewHeader({
    super.key,
    required this.title,
    this.subtitle,
    required this.metrics,
  });

  final String title;
  final String? subtitle;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return WalletsPageHeader(
      metrics: metrics,
      title: title,
    );
  }
}

class WalletOverviewKpiSection extends StatelessWidget {
  const WalletOverviewKpiSection({
    super.key,
    required this.overview,
    this.showPackageStat = false,
    this.minTileWidth,
  });

  final WalletOverviewEntity overview;
  final bool showPackageStat;
  final double? minTileWidth;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final metrics = walletsMetricsOf(context);

    return ResponsiveStatsGrid(
      minTileWidth: minTileWidth ?? metrics.statsMinTileWidth,
      spacing: metrics.statsGridSpacing,
      runSpacing: metrics.statsGridSpacing,
      children: walletOverviewKpiCards(
        context,
        overview,
        showPackageStat: showPackageStat,
      ),
    );
  }
}

class WalletLedgerByTypeSection extends StatelessWidget {
  const WalletLedgerByTypeSection({
    super.key,
    required this.items,
    required this.metrics,
    this.title = 'Ledger by type (24h)',
  });

  final List<LedgerByTypeEntity> items;
  final WalletsLayoutMetrics metrics;
  final String title;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);

    final maxAmount = items.isEmpty
        ? 0.0
        : items.map((e) => e.amountCoins).reduce((a, b) => a > b ? a : b);

    return WalletsDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              metrics.cardPadding + 2,
              metrics.cardPadding,
              metrics.cardPadding + 2,
              4,
            ),
            child: Text(
              walletL10nOr(context, 'walletSectionLedgerByType24h', title),
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    fontSize: metrics.sectionTitleFontSize,
                  ),
            ),
          ),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: EmptyStateCard(
                title: walletL10nOr(context,
                  'walletEmptyLedgerActivity',
                  'No ledger activity',
                ),
                message: walletL10nOr(context,
                  'walletEmptyMsgLedgerActivity',
                  'Ledger breakdown will appear when entries are recorded.',
                ),
                icon: Icons.receipt_long_outlined,
              ),
            )
          else if (metrics.useCompactTable)
            Padding(
              padding: EdgeInsets.fromLTRB(
                metrics.cardPadding,
                0,
                metrics.cardPadding,
                metrics.cardPadding,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) SizedBox(height: metrics.statsGridSpacing),
                    _LedgerTypeCompactCard(
                      item: items[i],
                      maxAmount: maxAmount,
                      metrics: metrics,
                    ),
                  ],
                ],
              ),
            )
          else
            _LedgerTypeDesktopList(
              items: items,
              maxAmount: maxAmount,
            ),
        ],
      ),
    );
  }
}

class _LedgerTypeCompactCard extends StatelessWidget {
  const _LedgerTypeCompactCard({
    required this.item,
    required this.maxAmount,
    required this.metrics,
  });

  final LedgerByTypeEntity item;
  final double maxAmount;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final fraction =
        maxAmount > 0 ? (item.amountCoins / maxAmount).clamp(0.0, 1.0) : 0.0;
    final count = '${item.count}';

    return WalletsCompactCard(
      metrics: metrics,
      title: ledgerTypeLabel(context, item.type),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CoinFormat.coins(item.amountCoins),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                  fontSize: metrics.compactCardValueFontSize,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            walletL10nArgs(context,
              'walletLedgerTypeEntries',
              {'count': count},
              '$count entries',
            ),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontSize: metrics.analyticsLabelFontSize,
                ),
          ),
        ],
      ),
      footer: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: LinearProgressIndicator(
          value: fraction,
          minHeight: 4,
          backgroundColor: scheme.surfaceContainerHighest,
          color: scheme.primary,
        ),
      ),
    );
  }
}

class _LedgerTypeDesktopList extends StatelessWidget {
  const _LedgerTypeDesktopList({
    required this.items,
    required this.maxAmount,
  });

  final List<LedgerByTypeEntity> items;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: kWalletsTableHeaderHeight,
            color: scheme.surfaceContainerLow,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: WalletsTableHeaderLabel(
                    walletL10nOr(context, 'walletColType', 'Type'),
                  ),
                ),
                Expanded(
                  child: WalletsTableHeaderLabel(
                    walletL10nOr(context, 'walletColEntries', 'Entries'),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: WalletsTableHeaderLabel(
                    walletL10nOr(context, 'walletColVolume', 'Volume'),
                  ),
                ),
                const Expanded(flex: 3, child: SizedBox()),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: items.length,
            separatorBuilder: (_, index) {
              if (index >= items.length - 1) {
                return const SizedBox.shrink();
              }
              return Divider(
                height: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              );
            },
            itemBuilder: (context, index) {
              return _LedgerTypeRow(
                item: items[index],
                maxAmount: maxAmount,
                striped: index.isOdd,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LedgerTypeRow extends StatelessWidget {
  const _LedgerTypeRow({
    required this.item,
    required this.maxAmount,
    required this.striped,
  });

  final LedgerByTypeEntity item;
  final double maxAmount;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final cellStyle = walletsTableCellStyle(context);
    final fraction =
        maxAmount > 0 ? (item.amountCoins / maxAmount).clamp(0.0, 1.0) : 0.0;

    return WalletsHoverTableRow(
      striped: striped,
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text(
              ledgerTypeLabel(context, item.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              '${item.count}',
              style: cellStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CoinFormat.coins(item.amountCoins),
              style: cellStyle?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 6,
                  backgroundColor: scheme.surfaceContainerHighest,
                  color: scheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WalletEconomySection extends StatelessWidget {
  const WalletEconomySection({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final metrics = walletsMetricsOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                fontSize: metrics.sectionTitleFontSize,
              ),
        ),
        SizedBox(height: metrics.sectionGap),
        WalletsDashboardCard(padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}

class WalletCoinPackagesCatalog extends StatelessWidget {
  const WalletCoinPackagesCatalog({super.key, required this.packages});

  final List<CoinPackageEntity> packages;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final activeLabel = walletL10nOr(context, 'active', 'Active');
    final inactiveLabel = walletL10nOr(context, 'inactive', 'Inactive');

    if (packages.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyStateCard(
          title: walletL10nOr(context, 'walletEmptyCoinPackages', 'No coin packages'),
          message: walletL10nOr(context,
            'walletEmptyMsgCoinPackages',
            'Active packages offered for fiat purchase will appear here.',
          ),
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(walletsMetricsOf(context).cardPadding),
      child: ResponsiveDataTable(
        columns: [
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColName', 'Name')),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColCoins', 'Coins')),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColPrice', 'Price')),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColStatus', 'Status')),
          ),
        ],
        rows: [
          for (final pkg in packages)
            DataRow(
              cells: [
                DataCell(Text(pkg.name)),
                DataCell(Text(CoinFormat.coins(pkg.coinAmount))),
                DataCell(Text(MoneyFormat.format(pkg.price, pkg.currencyCode))),
                DataCell(WalletsStatusChip(
                  label: pkg.isActive ? activeLabel : inactiveLabel,
                  tone: pkg.isActive
                      ? WalletsChipTone.success
                      : WalletsChipTone.neutral,
                )),
              ],
            ),
        ],
        mobileCards: [
          for (final pkg in packages)
            _CatalogMobileCard(
              title: pkg.name,
              primary: CoinFormat.coins(pkg.coinAmount),
              secondary: MoneyFormat.format(pkg.price, pkg.currencyCode),
              chip: WalletsStatusChip(
                label: pkg.isActive ? activeLabel : inactiveLabel,
                tone: pkg.isActive
                    ? WalletsChipTone.success
                    : WalletsChipTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}

class WalletGiftCatalogTable extends StatelessWidget {
  const WalletGiftCatalogTable({super.key, required this.items});

  final List<EconomyGiftCatalogItem> items;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final activeLabel = walletL10nOr(context, 'active', 'Active');
    final inactiveLabel = walletL10nOr(context, 'inactive', 'Inactive');

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyStateCard(
          title: walletL10nOr(context, 'walletEmptyGiftsCatalog', 'No gifts in catalog'),
          message: walletL10nOr(context,
            'walletEmptyMsgGiftsCatalog',
            'Gift items and coin prices will appear here.',
          ),
          icon: Icons.card_giftcard_outlined,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(walletsMetricsOf(context).cardPadding),
      child: ResponsiveDataTable(
        columns: [
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColName', 'Name')),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColPrice', 'Price')),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColStatus', 'Status')),
          ),
        ],
        rows: [
          for (final gift in items)
            DataRow(
              cells: [
                DataCell(Text(gift.name)),
                DataCell(Text(CoinFormat.coins(gift.priceCoins))),
                DataCell(WalletsStatusChip(
                  label: gift.isActive ? activeLabel : inactiveLabel,
                  tone: gift.isActive
                      ? WalletsChipTone.success
                      : WalletsChipTone.neutral,
                )),
              ],
            ),
        ],
        mobileCards: [
          for (final gift in items)
            _CatalogMobileCard(
              title: gift.name,
              primary: CoinFormat.coins(gift.priceCoins),
              chip: WalletsStatusChip(
                label: gift.isActive ? activeLabel : inactiveLabel,
                tone: gift.isActive
                    ? WalletsChipTone.success
                    : WalletsChipTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}

class WalletPromoPackagesCatalog extends StatelessWidget {
  const WalletPromoPackagesCatalog({super.key, required this.items});

  final List<EconomyPromotionPackageItem> items;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final activeLabel = walletL10nOr(context, 'active', 'Active');
    final inactiveLabel = walletL10nOr(context, 'inactive', 'Inactive');

    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyStateCard(
          title: walletL10nOr(context,
            'walletEmptyPromotionPackages',
            'No promotion packages',
          ),
          message: walletL10nOr(context,
            'walletEmptyMsgPromotionPackages',
            'Promotion packages and budgets will appear here.',
          ),
          icon: Icons.campaign_outlined,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.all(walletsMetricsOf(context).cardPadding),
      child: ResponsiveDataTable(
        columns: [
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColName', 'Name')),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColBudget', 'Budget')),
          ),
          DataColumn(
            label: Text(
              walletL10nOr(context, 'walletColImpressions', 'Impressions'),
            ),
          ),
          DataColumn(
            label: Text(walletL10nOr(context, 'walletColStatus', 'Status')),
          ),
        ],
        rows: [
          for (final pkg in items)
            DataRow(
              cells: [
                DataCell(Text(pkg.name)),
                DataCell(Text(CoinFormat.coins(pkg.priceCoins))),
                DataCell(Text('${pkg.impressionCount}')),
                DataCell(WalletsStatusChip(
                  label: pkg.isActive ? activeLabel : inactiveLabel,
                  tone: pkg.isActive
                      ? WalletsChipTone.success
                      : WalletsChipTone.neutral,
                )),
              ],
            ),
        ],
        mobileCards: [
          for (final pkg in items)
            _CatalogMobileCard(
              title: pkg.name,
              primary: CoinFormat.coins(pkg.priceCoins),
              secondary: walletL10nArgs(context,
                'walletPromoImpressions',
                {'count': '${pkg.impressionCount}'},
                '${pkg.impressionCount} impressions',
              ),
              chip: WalletsStatusChip(
                label: pkg.isActive ? activeLabel : inactiveLabel,
                tone: pkg.isActive
                    ? WalletsChipTone.success
                    : WalletsChipTone.neutral,
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogMobileCard extends StatelessWidget {
  const _CatalogMobileCard({
    required this.title,
    required this.primary,
    this.secondary,
    this.chip,
  });

  final String title;
  final String primary;
  final String? secondary;
  final Widget? chip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = walletsMetricsOf(context);

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(metrics.compactCardRadius),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Padding(
        padding: EdgeInsets.all(metrics.compactCardPadding),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: metrics.compactCardTitleFontSize,
                          height: 1.25,
                        ),
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      secondary!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: metrics.sectionSubtitleFontSize,
                          ),
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  primary,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                        fontSize: metrics.compactCardValueFontSize,
                      ),
                ),
                if (chip != null) ...[
                  const SizedBox(height: 4),
                  chip!,
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
