import 'package:flutter/material.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/dashboard/analytics_card.dart';
import '../../../../core/widgets/dashboard/empty_state_card.dart';
import '../../../../core/widgets/dashboard/responsive_data_table.dart';
import '../../../../core/widgets/dashboard/responsive_stats_grid.dart';
import '../../domain/entities/wallet_entities.dart';
import '../utils/ledger_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_page_widgets.dart';

List<Widget> walletOverviewKpiCards(
  WalletOverviewEntity overview, {
  bool showPackageStat = false,
}) {
  final cards = <Widget>[
    AnalyticsCard(
      label: 'Total wallets',
      value: '${overview.walletsTotal}',
      icon: Icons.account_balance_wallet_outlined,
    ),
    AnalyticsCard(
      label: 'Total balance',
      value: CoinFormat.coins(overview.totalBalanceCoins),
      icon: Icons.monetization_on_outlined,
      highlight: true,
    ),
    AnalyticsCard(
      label: 'Fiat purchases',
      value: '${overview.fiatPurchasesTotal}',
      icon: Icons.shopping_cart_outlined,
    ),
    AnalyticsCard(
      label: 'Purchase volume',
      value: CoinFormat.purchaseVolume(overview.completedPurchaseVolume),
      icon: Icons.payments_outlined,
    ),
    AnalyticsCard(
      label: 'Pending withdrawals',
      value: '${overview.withdrawalsPending}',
      icon: Icons.hourglass_top_outlined,
    ),
    AnalyticsCard(
      label: 'Ledger entries (24h)',
      value: '${overview.ledgerEntriesLast24Hours}',
      icon: Icons.receipt_long_outlined,
    ),
  ];

  if (showPackageStat) {
    cards.add(
      AnalyticsCard(
        label: 'Coin packages',
        value: '${overview.packagesActive} active',
        subtitle: '${overview.packagesTotal} total in catalog',
        icon: Icons.inventory_2_outlined,
      ),
    );
  }

  return cards;
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
      subtitle: subtitle,
    );
  }
}

class WalletOverviewKpiSection extends StatelessWidget {
  const WalletOverviewKpiSection({
    super.key,
    required this.overview,
    this.showPackageStat = false,
    this.minTileWidth = 200,
  });

  final WalletOverviewEntity overview;
  final bool showPackageStat;
  final double minTileWidth;

  @override
  Widget build(BuildContext context) {
    return ResponsiveStatsGrid(
      minTileWidth: minTileWidth,
      children: walletOverviewKpiCards(
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
    final scheme = Theme.of(context).colorScheme;
    final maxAmount = items.isEmpty
        ? 0.0
        : items.map((e) => e.amountCoins).reduce((a, b) => a > b ? a : b);

    return WalletsDashboardCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Entry count and coin volume per ledger type in the last 24 hours.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.35,
                      ),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: EmptyStateCard(
                title: 'No ledger activity',
                message: 'Ledger breakdown will appear when entries are recorded.',
                icon: Icons.receipt_long_outlined,
              ),
            )
          else if (metrics.useCompactTable)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  for (var i = 0; i < items.length; i++) ...[
                    if (i > 0) const SizedBox(height: 8),
                    _LedgerTypeCompactCard(
                      item: items[i],
                      maxAmount: maxAmount,
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
  });

  final LedgerByTypeEntity item;
  final double maxAmount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fraction =
        maxAmount > 0 ? (item.amountCoins / maxAmount).clamp(0.0, 1.0) : 0.0;

    return WalletsCompactCard(
      title: ledgerTypeLabel(item.type),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CoinFormat.coins(item.amountCoins),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${item.count} entries',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
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
                Expanded(flex: 4, child: WalletsTableHeaderLabel('Type')),
                Expanded(child: WalletsTableHeaderLabel('Entries')),
                Expanded(flex: 2, child: WalletsTableHeaderLabel('Volume')),
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
              ledgerTypeLabel(item.type),
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
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
        const SizedBox(height: 10),
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
    if (packages.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyStateCard(
          title: 'No coin packages',
          message: 'Active packages offered for fiat purchase will appear here.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ResponsiveDataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Coins')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          for (final pkg in packages)
            DataRow(
              cells: [
                DataCell(Text(pkg.name)),
                DataCell(Text(CoinFormat.coins(pkg.coinAmount))),
                DataCell(Text(MoneyFormat.format(pkg.price, pkg.currencyCode))),
                DataCell(WalletsStatusChip(
                  label: pkg.isActive ? 'Active' : 'Inactive',
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
                label: pkg.isActive ? 'Active' : 'Inactive',
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
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyStateCard(
          title: 'No gifts in catalog',
          message: 'Gift items and coin prices will appear here.',
          icon: Icons.card_giftcard_outlined,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ResponsiveDataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Price')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          for (final gift in items)
            DataRow(
              cells: [
                DataCell(Text(gift.name)),
                DataCell(Text(CoinFormat.coins(gift.priceCoins))),
                DataCell(WalletsStatusChip(
                  label: gift.isActive ? 'Active' : 'Inactive',
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
                label: gift.isActive ? 'Active' : 'Inactive',
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
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: EmptyStateCard(
          title: 'No promotion packages',
          message: 'Promotion packages and budgets will appear here.',
          icon: Icons.campaign_outlined,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12),
      child: ResponsiveDataTable(
        columns: const [
          DataColumn(label: Text('Name')),
          DataColumn(label: Text('Budget')),
          DataColumn(label: Text('Impressions')),
          DataColumn(label: Text('Status')),
        ],
        rows: [
          for (final pkg in items)
            DataRow(
              cells: [
                DataCell(Text(pkg.name)),
                DataCell(Text(CoinFormat.coins(pkg.priceCoins))),
                DataCell(Text('${pkg.impressionCount}')),
                DataCell(WalletsStatusChip(
                  label: pkg.isActive ? 'Active' : 'Inactive',
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
              secondary: '${pkg.impressionCount} impressions',
              chip: WalletsStatusChip(
                label: pkg.isActive ? 'Active' : 'Inactive',
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

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                        ),
                  ),
                  if (secondary != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      secondary!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
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
                      ),
                ),
                if (chip != null) ...[
                  const SizedBox(height: 6),
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
