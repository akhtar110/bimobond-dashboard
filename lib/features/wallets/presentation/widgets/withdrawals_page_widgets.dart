import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/enums/wallet_enums.dart';
import '../bloc/withdrawals_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_page_widgets.dart';

class WithdrawalsToolbar extends StatelessWidget {
  const WithdrawalsToolbar({
    super.key,
    required this.status,
    required this.metrics,
    required this.onStatusChanged,
    required this.onClear,
  });

  final String? status;
  final WalletsLayoutMetrics metrics;
  final ValueChanged<String?> onStatusChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final gap = metrics.filterGap;
    final controlHeight = metrics.filterControlHeight;
    final allStatuses = walletL10nOr(context, 'walletAllStatuses', 'All statuses');

    final statusFilter = WalletsToolbarDropdown<String?>(
      value: status,
      hint: allStatuses,
      icon: Icons.flag_outlined,
      items: [
        DropdownMenuItem(value: null, child: Text(allStatuses)),
        ...WithdrawalStatus.values.map(
          (s) => DropdownMenuItem(
            value: s.apiValue,
            child: Text(withdrawalStatusLabel(context, s.apiValue)),
          ),
        ),
      ],
      onChanged: onStatusChanged,
    );

    final clearButton = status != null
        ? WalletsToolbarClearButton(
            controlHeight: controlHeight,
            onPressed: onClear,
          )
        : null;

    return Row(
      children: [
        Expanded(child: statusFilter),
        if (clearButton != null) ...[
          SizedBox(width: gap),
          clearButton,
        ],
      ],
    );
  }
}

class WithdrawalsTableCard extends StatelessWidget {
  const WithdrawalsTableCard({
    super.key,
    required this.state,
    required this.metrics,
    required this.dateFmt,
  });

  final WithdrawalsLoaded state;
  final WalletsLayoutMetrics metrics;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    return WalletsDataListCard(
      total: state.meta.total,
      totalLabel: walletL10nOr(context, 'walletCountWithdrawals', 'withdrawals'),
      isEmpty: state.withdrawals.isEmpty,
      emptyIcon: Icons.account_balance_outlined,
      emptyTitle: walletL10nOr(context, 'walletEmptyWithdrawals', 'No withdrawals'),
      emptySubtitle: walletL10nOr(context,
        'walletEmptyMsgWithdrawals',
        'Try adjusting the status filter.',
      ),
      page: state.meta.page,
      totalPages: state.meta.totalPages,
      onPage: (page) => context
          .read<WithdrawalsBloc>()
          .add(WithdrawalsPageChangedEvent(page)),
      child: metrics.useCompactTable
          ? _WithdrawalsCompactList(
              withdrawals: state.withdrawals,
              dateFmt: dateFmt,
            )
          : _WithdrawalsDesktopTable(
              withdrawals: state.withdrawals,
              dateFmt: dateFmt,
            ),
    );
  }
}

class _WithdrawalsCompactList extends StatelessWidget {
  const _WithdrawalsCompactList({
    required this.withdrawals,
    required this.dateFmt,
  });

  final List<WithdrawalEntity> withdrawals;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;

    return WalletsCompactListFrame(
      itemCount: withdrawals.length,
      itemBuilder: (context, index) {
        final w = withdrawals[index];
        final user = w.wallet?.user;

        return WalletsCompactCard(
          title: user?.displayName ?? w.wallet?.userId ?? '—',
          subtitle: w.payoutMethod,
          footer: Text(
            dateFmt.format(w.createdAt.toLocal()),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CoinFormat.coins(w.amountCoins),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
              ),
              const SizedBox(height: 4),
              WalletsStatusChip(
                label: withdrawalStatusLabel(context, w.status),
                tone: statusChipTone(w.status),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WithdrawalsDesktopTable extends StatelessWidget {
  const _WithdrawalsDesktopTable({
    required this.withdrawals,
    required this.dateFmt,
  });

  final List<WithdrawalEntity> withdrawals;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    return WalletsDesktopTableFrame(
      header: Row(
        children: [
          Expanded(
            flex: 2,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColDate', 'Date'),
            ),
          ),
          Expanded(
            flex: 3,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColUser', 'User'),
            ),
          ),
          Expanded(
            flex: 2,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColAmount', 'Amount'),
            ),
          ),
          Expanded(
            flex: 2,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColMethod', 'Method'),
            ),
          ),
          Expanded(
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColStatus', 'Status'),
            ),
          ),
        ],
      ),
      rows: [
        for (var i = 0; i < withdrawals.length; i++)
          _WithdrawalRow(
            withdrawal: withdrawals[i],
            dateFmt: dateFmt,
            striped: i.isOdd,
          ),
      ],
    );
  }
}

class _WithdrawalRow extends StatelessWidget {
  const _WithdrawalRow({
    required this.withdrawal,
    required this.dateFmt,
    required this.striped,
  });

  final WithdrawalEntity withdrawal;
  final DateFormat dateFmt;
  final bool striped;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final cellStyle = walletsTableCellStyle(context);
    final user = withdrawal.wallet?.user;

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
            flex: 3,
            child: Text(
              user?.displayName ?? withdrawal.wallet?.userId ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
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
              label: withdrawalStatusLabel(context, withdrawal.status),
              tone: statusChipTone(withdrawal.status),
            ),
          ),
        ],
      ),
    );
  }
}
