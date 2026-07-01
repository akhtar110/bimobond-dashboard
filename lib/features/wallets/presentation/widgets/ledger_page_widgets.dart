import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/enums/wallet_enums.dart';
import '../bloc/ledger_bloc.dart';
import '../utils/ledger_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_page_widgets.dart';

class LedgerToolbar extends StatelessWidget {
  const LedgerToolbar({
    super.key,
    required this.state,
    required this.metrics,
    required this.type,
    required this.action,
    required this.onTypeChanged,
    required this.onActionChanged,
    required this.onClear,
  });

  final LedgerLoaded state;
  final WalletsLayoutMetrics metrics;
  final String? type;
  final String? action;
  final ValueChanged<String?> onTypeChanged;
  final ValueChanged<String?> onActionChanged;
  final VoidCallback onClear;

  bool get _hasActiveFilters => type != null || action != null;

  @override
  Widget build(BuildContext context) {
    final gap = metrics.filterGap;
    final controlHeight = metrics.filterControlHeight;

    final typeFilter = WalletsToolbarDropdown<String?>(
      value: type,
      hint: 'All types',
      icon: Icons.category_outlined,
      items: [
        const DropdownMenuItem(value: null, child: Text('All types')),
        ...LedgerType.values.map(
          (t) => DropdownMenuItem(
            value: t.apiValue,
            child: Text(ledgerTypeLabel(t.apiValue)),
          ),
        ),
      ],
      onChanged: onTypeChanged,
    );

    final actionFilter = WalletsToolbarDropdown<String?>(
      value: action,
      hint: 'All actions',
      icon: Icons.swap_horiz_rounded,
      items: [
        const DropdownMenuItem(value: null, child: Text('All actions')),
        ...LedgerAction.values.map(
          (a) => DropdownMenuItem(
            value: a.apiValue,
            child: Text(ledgerActionLabel(a.apiValue)),
          ),
        ),
      ],
      onChanged: onActionChanged,
    );

    final clearButton = _hasActiveFilters
        ? WalletsToolbarClearButton(
            controlHeight: controlHeight,
            onPressed: onClear,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              typeFilter,
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: actionFilter),
                  if (clearButton != null) ...[
                    SizedBox(width: gap),
                    clearButton,
                  ],
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: typeFilter),
            SizedBox(width: gap),
            Expanded(child: actionFilter),
            if (clearButton != null) ...[
              SizedBox(width: gap),
              clearButton,
            ],
          ],
        );
      },
    );
  }
}

class LedgerTableCard extends StatelessWidget {
  const LedgerTableCard({
    super.key,
    required this.state,
    required this.metrics,
    required this.dateFmt,
  });

  final LedgerLoaded state;
  final WalletsLayoutMetrics metrics;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsDataListCard(
      total: state.meta.total,
      totalLabel: 'entries',
      isEmpty: state.entries.isEmpty,
      emptyIcon: Icons.receipt_long_outlined,
      emptyTitle: 'No ledger entries',
      emptySubtitle: 'Try adjusting type or action filters.',
      page: state.meta.page,
      totalPages: state.meta.totalPages,
      onPage: (page) =>
          context.read<LedgerBloc>().add(LedgerPageChangedEvent(page)),
      child: metrics.useCompactTable
          ? _LedgerCompactList(entries: state.entries, dateFmt: dateFmt)
          : _LedgerDesktopTable(entries: state.entries, dateFmt: dateFmt),
    );
  }
}

class _LedgerCompactList extends StatelessWidget {
  const _LedgerCompactList({required this.entries, required this.dateFmt});

  final List<LedgerEntryEntity> entries;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsCompactListFrame(
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        final user = entry.wallet?.user;
        final amountPrefix = entry.action == 'DEBIT' ? '−' : '+';
        final scheme = Theme.of(context).colorScheme;

        return WalletsCompactCard(
          title: ledgerTypeLabel(entry.type),
          subtitle: user?.displayName ?? entry.wallet?.userId ?? '—',
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
                '$amountPrefix${CoinFormat.coinsAmount(entry.amountCoins)}',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: entry.action == 'DEBIT'
                          ? scheme.error
                          : scheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                ledgerActionLabel(entry.action),
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

class _LedgerDesktopTable extends StatelessWidget {
  const _LedgerDesktopTable({required this.entries, required this.dateFmt});

  final List<LedgerEntryEntity> entries;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsDesktopTableFrame(
      header: Row(
        children: [
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Date')),
          Expanded(flex: 3, child: WalletsTableHeaderLabel('User')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Type')),
          Expanded(child: WalletsTableHeaderLabel('Action')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Amount')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Balance after')),
          Expanded(flex: 3, child: WalletsTableHeaderLabel('Reason')),
        ],
      ),
      rows: [
        for (var i = 0; i < entries.length; i++)
          _LedgerTableRow(entry: entries[i], dateFmt: dateFmt, striped: i.isOdd),
      ],
    );
  }
}

class _LedgerTableRow extends StatelessWidget {
  const _LedgerTableRow({
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
    final user = entry.wallet?.user;
    final amountPrefix = entry.action == 'DEBIT' ? '−' : '+';
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
            flex: 3,
            child: Text(
              user?.displayName ?? entry.wallet?.userId ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              ledgerTypeLabel(entry.type),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
          ),
          Expanded(
            child: Text(ledgerActionLabel(entry.action), style: cellStyle),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$amountPrefix${CoinFormat.coinsAmount(entry.amountCoins)}',
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
