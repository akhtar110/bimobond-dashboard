import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/presentation/widgets/admin_user_search_field.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/enums/wallet_enums.dart';
import '../bloc/fiat_purchases_bloc.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_page_widgets.dart';

class FiatPurchasesToolbar extends StatelessWidget {
  const FiatPurchasesToolbar({
    super.key,
    required this.state,
    required this.metrics,
    required this.selectedUser,
    required this.status,
    required this.provider,
    required this.onUserSelected,
    required this.onStatusChanged,
    required this.onProviderChanged,
    required this.onClear,
  });

  final FiatPurchasesLoaded state;
  final WalletsLayoutMetrics metrics;
  final UserEntity? selectedUser;
  final String? status;
  final String? provider;
  final ValueChanged<UserEntity?> onUserSelected;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onProviderChanged;
  final VoidCallback onClear;

  bool get _hasActiveFilters {
    final q = state.query;
    return q.userId != null && q.userId!.isNotEmpty ||
        status != null ||
        provider != null;
  }

  @override
  Widget build(BuildContext context) {
    final gap = metrics.filterGap;
    final controlHeight = metrics.filterControlHeight;

    final userSearch = AdminUserSearchField(
      compact: true,
      compactFilterStyle: true,
      hintText: 'Search by username, name, or email',
      selectedUser: selectedUser,
      onUserSelected: onUserSelected,
    );

    final statusFilter = WalletsToolbarDropdown<String?>(
      value: status,
      hint: 'All statuses',
      icon: Icons.flag_outlined,
      items: [
        const DropdownMenuItem(value: null, child: Text('All statuses')),
        ...FiatPurchaseStatus.values.map(
          (s) => DropdownMenuItem(value: s.apiValue, child: Text(s.apiValue)),
        ),
      ],
      onChanged: onStatusChanged,
    );

    final providerFilter = WalletsToolbarDropdown<String?>(
      value: provider,
      hint: 'All providers',
      icon: Icons.payments_outlined,
      items: [
        const DropdownMenuItem(value: null, child: Text('All providers')),
        ...FiatProvider.values.map(
          (p) => DropdownMenuItem(value: p.apiValue, child: Text(p.apiValue)),
        ),
      ],
      onChanged: onProviderChanged,
    );

    final clearButton = _hasActiveFilters
        ? WalletsToolbarClearButton(
            controlHeight: controlHeight,
            onPressed: onClear,
          )
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final veryNarrow = constraints.maxWidth < 520;
        final narrow = constraints.maxWidth < 760;

        if (veryNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              userSearch,
              SizedBox(height: gap),
              statusFilter,
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: providerFilter),
                  if (clearButton != null) ...[
                    SizedBox(width: gap),
                    clearButton,
                  ],
                ],
              ),
            ],
          );
        }

        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              userSearch,
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: statusFilter),
                  SizedBox(width: gap),
                  Expanded(child: providerFilter),
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
            Expanded(flex: 3, child: userSearch),
            SizedBox(width: gap),
            Expanded(flex: 2, child: statusFilter),
            SizedBox(width: gap),
            Expanded(flex: 2, child: providerFilter),
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

class FiatPurchasesTableCard extends StatelessWidget {
  const FiatPurchasesTableCard({
    super.key,
    required this.state,
    required this.metrics,
    required this.dateFmt,
  });

  final FiatPurchasesLoaded state;
  final WalletsLayoutMetrics metrics;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return WalletsDataListCard(
      total: state.meta.total,
      totalLabel: 'purchases',
      isEmpty: state.purchases.isEmpty,
      emptyIcon: Icons.shopping_cart_outlined,
      emptyTitle: 'No purchases',
      emptySubtitle:
          'Try another user or adjust status and provider filters.',
      page: state.meta.page,
      totalPages: state.meta.totalPages,
      onPage: (page) => context
          .read<FiatPurchasesBloc>()
          .add(FiatPurchasesPageChangedEvent(page)),
      child: metrics.useCompactTable
          ? _FiatPurchasesCompactList(
              purchases: state.purchases,
              dateFmt: dateFmt,
            )
          : _FiatPurchasesDesktopTable(
              purchases: state.purchases,
              dateFmt: dateFmt,
            ),
    );
  }
}

String _txnLabel(FiatPurchaseEntity purchase) {
  final tx = purchase.providerTxId.trim();
  if (tx.isNotEmpty) return tx;
  return purchase.id;
}

class _FiatPurchasesCompactList extends StatelessWidget {
  const _FiatPurchasesCompactList({
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
        final p = purchases[index];
        final package = p.package?.name;
        final subtitle = [
          if (package != null && package.isNotEmpty) package,
          '${p.provider} · ${_txnLabel(p)}',
        ].join(' · ');

        return WalletsCompactCard(
          title: p.user?.displayName ?? p.userId,
          subtitle: subtitle,
          footer: Text(
            dateFmt.format(p.createdAt.toLocal()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormat.format(p.paidPrice, p.currencyCode),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 4),
              WalletsStatusChip(
                label: p.status,
                tone: statusChipTone(p.status),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FiatPurchasesDesktopTable extends StatelessWidget {
  const _FiatPurchasesDesktopTable({
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
          Expanded(flex: 3, child: WalletsTableHeaderLabel('User')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Package')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Provider ref')),
          Expanded(child: WalletsTableHeaderLabel('Coins')),
          Expanded(flex: 2, child: WalletsTableHeaderLabel('Fiat')),
          Expanded(child: WalletsTableHeaderLabel('Provider')),
          Expanded(child: WalletsTableHeaderLabel('Status')),
        ],
      ),
      rows: [
        for (var i = 0; i < purchases.length; i++)
          _FiatPurchaseRow(
            purchase: purchases[i],
            dateFmt: dateFmt,
            striped: i.isOdd,
          ),
      ],
    );
  }
}

class _FiatPurchaseRow extends StatelessWidget {
  const _FiatPurchaseRow({
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
    final p = purchase;
    final txn = _txnLabel(p);

    return WalletsHoverTableRow(
      striped: striped,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              dateFmt.format(p.createdAt.toLocal()),
              style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              p.user?.displayName ?? p.userId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              p.package?.name ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Tooltip(
              message: txn,
              child: Text(
                txn,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: cellStyle?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 10.5,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              p.package != null
                  ? CoinFormat.coins(p.package!.coinAmount)
                  : '—',
              style: cellStyle,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              MoneyFormat.format(p.paidPrice, p.currencyCode),
              style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(child: Text(p.provider, style: cellStyle)),
          Expanded(
            child: WalletsStatusChip(
              label: p.status,
              tone: statusChipTone(p.status),
            ),
          ),
        ],
      ),
    );
  }
}
