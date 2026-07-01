import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../domain/entities/wallet_entities.dart';
import '../utils/ledger_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_page_widgets.dart';

class WalletDetailSummaryCard extends StatelessWidget {
  const WalletDetailSummaryCard({super.key, required this.detail});

  final WalletDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = detail.user;
    final metrics = walletsMetricsOf(context);

    return WalletsDashboardCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              WalletUserAvatar(user: user, size: metrics.isMobile ? 44 : 52),
              SizedBox(width: metrics.isMobile ? 10 : 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? detail.userId,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    if (user != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                    if (user?.email != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user!.email!,
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
                    'Balance',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CoinFormat.coins(detail.balanceCoins),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: metrics.sectionGap + 4),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SummaryChip(
                icon: Icons.receipt_long_outlined,
                label: '${detail.accountings.length} ledger',
              ),
              _SummaryChip(
                icon: Icons.shopping_cart_outlined,
                label: '${detail.fiatPurchases.length} purchases',
              ),
              _SummaryChip(
                icon: Icons.account_balance_outlined,
                label: '${detail.withdrawals.length} withdrawals',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class WalletDetailTabBar extends StatelessWidget {
  const WalletDetailTabBar({
    super.key,
    required this.controller,
    required this.ledgerCount,
    required this.purchasesCount,
    required this.withdrawalsCount,
  });

  final TabController controller;
  final int ledgerCount;
  final int purchasesCount;
  final int withdrawalsCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = walletsMetricsOf(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        metrics.pageHorizontalPadding,
        0,
        metrics.pageHorizontalPadding,
        metrics.sectionGap,
      ),
      child: DecoratedBox(
        decoration: ToolbarFilterStyle.boxDecoration(scheme),
        child: TabBar(
          controller: controller,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          labelColor: scheme.onPrimaryContainer,
          unselectedLabelColor: scheme.onSurfaceVariant,
          labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
          unselectedLabelStyle: Theme.of(context).textTheme.labelLarge,
          tabs: [
            Tab(text: 'Ledger ($ledgerCount)'),
            Tab(text: 'Purchases ($purchasesCount)'),
            Tab(text: 'Withdrawals ($withdrawalsCount)'),
          ],
        ),
      ),
    );
  }
}

class WalletDetailLedgerTab extends StatelessWidget {
  const WalletDetailLedgerTab({
    super.key,
    required this.entries,
    required this.dateFmt,
    required this.metrics,
  });

  final List<LedgerEntryEntity> entries;
  final DateFormat dateFmt;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.pageHorizontalPadding),
      child: WalletsDataListCard(
        total: entries.length,
        totalLabel: 'entries',
        isEmpty: entries.isEmpty,
        emptyIcon: Icons.receipt_long_outlined,
        emptyTitle: 'No ledger entries',
        emptySubtitle: 'This wallet has no recorded ledger activity yet.',
        child: metrics.useCompactTable
            ? _DetailLedgerCompactList(entries: entries, dateFmt: dateFmt)
            : _DetailLedgerDesktopTable(entries: entries, dateFmt: dateFmt),
      ),
    );
  }
}

class WalletDetailPurchasesTab extends StatelessWidget {
  const WalletDetailPurchasesTab({
    super.key,
    required this.purchases,
    required this.dateFmt,
    required this.metrics,
  });

  final List<FiatPurchaseEntity> purchases;
  final DateFormat dateFmt;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.pageHorizontalPadding),
      child: WalletsDataListCard(
        total: purchases.length,
        totalLabel: 'purchases',
        isEmpty: purchases.isEmpty,
        emptyIcon: Icons.shopping_cart_outlined,
        emptyTitle: 'No fiat purchases',
        emptySubtitle: 'This user has not completed any fiat coin purchases.',
        child: metrics.useCompactTable
            ? _DetailPurchasesCompactList(
                purchases: purchases,
                dateFmt: dateFmt,
              )
            : _DetailPurchasesDesktopTable(
                purchases: purchases,
                dateFmt: dateFmt,
              ),
      ),
    );
  }
}

class WalletDetailWithdrawalsTab extends StatelessWidget {
  const WalletDetailWithdrawalsTab({
    super.key,
    required this.withdrawals,
    required this.dateFmt,
    required this.metrics,
  });

  final List<WithdrawalEntity> withdrawals;
  final DateFormat dateFmt;
  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: metrics.pageHorizontalPadding),
      child: WalletsDataListCard(
        total: withdrawals.length,
        totalLabel: 'withdrawals',
        isEmpty: withdrawals.isEmpty,
        emptyIcon: Icons.account_balance_outlined,
        emptyTitle: 'No withdrawals',
        emptySubtitle: 'This user has not requested any withdrawals.',
        child: metrics.useCompactTable
            ? _DetailWithdrawalsCompactList(
                withdrawals: withdrawals,
                dateFmt: dateFmt,
              )
            : _DetailWithdrawalsDesktopTable(
                withdrawals: withdrawals,
                dateFmt: dateFmt,
              ),
      ),
    );
  }
}

class _DetailLedgerCompactList extends StatelessWidget {
  const _DetailLedgerCompactList({
    required this.entries,
    required this.dateFmt,
  });

  final List<LedgerEntryEntity> entries;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WalletsCompactListFrame(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final prefix = entry.action == 'DEBIT' ? '−' : '+';

        return WalletsCompactCard(
          title: ledgerTypeLabel(entry.type),
          subtitle: ledgerActionLabel(entry.action),
          footer: Text(
            dateFmt.format(entry.createdAt.toLocal()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$prefix${CoinFormat.coinsAmount(entry.amountCoins)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: entry.action == 'DEBIT'
                          ? scheme.error
                          : scheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'After ${CoinFormat.coins(entry.balanceAfterCoins)}',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailLedgerDesktopTable extends StatelessWidget {
  const _DetailLedgerDesktopTable({
    required this.entries,
    required this.dateFmt,
  });

  final List<LedgerEntryEntity> entries;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsDesktopTableFrame(
      header: Row(
        children: [
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Date')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Type')),
          Expanded(child: WalletsTableHeaderLabel('Action')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Amount')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Balance after')),
          Expanded(flex: 3, child: WalletsTableHeaderLabel('Reason')),
        ],
      ),
      rows: [
        for (var i = 0; i < entries.length; i++)
          _DetailLedgerRow(entry: entries[i], dateFmt: dateFmt, striped: i.isOdd),
      ],
    );
  }
}

class _DetailLedgerRow extends StatelessWidget {
  const _DetailLedgerRow({
    required this.entry,
    required this.dateFmt,
    required this.striped,
  });

  final LedgerEntryEntity entry;
  final DateFormat dateFmt;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final prefix = entry.action == 'DEBIT' ? '−' : '+';
    final cellStyle = walletsTableCellStyle(context);

    return WalletsHoverTableRow(
      striped: striped,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(entry.createdAt.toLocal()),
              style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ledgerTypeLabel(entry.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(ledgerActionLabel(entry.action), style: cellStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$prefix${CoinFormat.coinsAmount(entry.amountCoins)}',
              style: cellStyle?.copyWith(
                fontWeight: FontWeight.w800,
                color: entry.action == 'DEBIT' ? scheme.error : scheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CoinFormat.coins(entry.balanceAfterCoins),
              style: cellStyle,
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              entry.reason ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailPurchasesCompactList extends StatelessWidget {
  const _DetailPurchasesCompactList({
    required this.purchases,
    required this.dateFmt,
  });

  final List<FiatPurchaseEntity> purchases;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WalletsCompactListFrame(
      itemCount: purchases.length,
      itemBuilder: (context, index) {
        final purchase = purchases[index];
        return WalletsCompactCard(
          title: purchase.package?.name ?? purchase.providerTxId,
          subtitle: purchase.provider,
          footer: Text(
            dateFmt.format(purchase.createdAt.toLocal()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormat.format(purchase.paidPrice, purchase.currencyCode),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              if (purchase.package != null)
                Text(
                  CoinFormat.coins(purchase.package!.coinAmount),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              const SizedBox(height: 4),
              WalletsStatusChip(
                label: purchase.status,
                tone: statusChipTone(purchase.status),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailPurchasesDesktopTable extends StatelessWidget {
  const _DetailPurchasesDesktopTable({
    required this.purchases,
    required this.dateFmt,
  });

  final List<FiatPurchaseEntity> purchases;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsDesktopTableFrame(
      header: Row(
        children: [
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Date')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Package')),
          Expanded(child: WalletsTableHeaderLabel('Coins')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Fiat')),
          Expanded(child: WalletsTableHeaderLabel('Provider')),
          Expanded(child: WalletsTableHeaderLabel('Status')),
        ],
      ),
      rows: [
        for (var i = 0; i < purchases.length; i++)
          _DetailPurchaseRow(
            purchase: purchases[i],
            dateFmt: dateFmt,
            striped: i.isOdd,
          ),
      ],
    );
  }
}

class _DetailPurchaseRow extends StatelessWidget {
  const _DetailPurchaseRow({
    required this.purchase,
    required this.dateFmt,
    required this.striped,
  });

  final FiatPurchaseEntity purchase;
  final DateFormat dateFmt;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final cellStyle = walletsTableCellStyle(context);
    final scheme = Theme.of(context).colorScheme;

    return WalletsHoverTableRow(
      striped: striped,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(purchase.createdAt.toLocal()),
              style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              purchase.package?.name ?? purchase.providerTxId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              purchase.package != null
                  ? CoinFormat.coins(purchase.package!.coinAmount)
                  : '—',
              style: cellStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              MoneyFormat.format(purchase.paidPrice, purchase.currencyCode),
              style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(purchase.provider, style: cellStyle)),
          Expanded(
            child: WalletsStatusChip(
              label: purchase.status,
              tone: statusChipTone(purchase.status),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailWithdrawalsCompactList extends StatelessWidget {
  const _DetailWithdrawalsCompactList({
    required this.withdrawals,
    required this.dateFmt,
  });

  final List<WithdrawalEntity> withdrawals;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return WalletsCompactListFrame(
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = withdrawals[index];
        return WalletsCompactCard(
          title: withdrawal.payoutMethod,
          footer: Text(
            dateFmt.format(withdrawal.createdAt.toLocal()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CoinFormat.coins(withdrawal.amountCoins),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              WalletsStatusChip(
                label: withdrawal.status,
                tone: statusChipTone(withdrawal.status),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DetailWithdrawalsDesktopTable extends StatelessWidget {
  const _DetailWithdrawalsDesktopTable({
    required this.withdrawals,
    required this.dateFmt,
  });

  final List<WithdrawalEntity> withdrawals;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsDesktopTableFrame(
      header: Row(
        children: [
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Date')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Amount')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Method')),
          Expanded(child: WalletsTableHeaderLabel('Status')),
        ],
      ),
      rows: [
        for (var i = 0; i < withdrawals.length; i++)
          _DetailWithdrawalRow(
            withdrawal: withdrawals[i],
            dateFmt: dateFmt,
            striped: i.isOdd,
          ),
      ],
    );
  }
}

class _DetailWithdrawalRow extends StatelessWidget {
  const _DetailWithdrawalRow({
    required this.withdrawal,
    required this.dateFmt,
    required this.striped,
  });

  final WithdrawalEntity withdrawal;
  final DateFormat dateFmt;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cellStyle = walletsTableCellStyle(context);

    return WalletsHoverTableRow(
      striped: striped,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(withdrawal.createdAt.toLocal()),
              style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CoinFormat.coins(withdrawal.amountCoins),
              style: cellStyle?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(withdrawal.payoutMethod, style: cellStyle),
          ),
          Expanded(
            child: WalletsStatusChip(
              label: withdrawal.status,
              tone: statusChipTone(withdrawal.status),
            ),
          ),
        ],
      ),
    );
  }
}
