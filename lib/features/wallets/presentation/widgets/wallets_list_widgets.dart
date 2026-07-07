import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/widgets/toolbar_filter_style.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/wallet_entities.dart';
import '../../domain/enums/wallet_enums.dart';
import '../bloc/wallets_list_bloc.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_page_widgets.dart';

class WalletsListHeader extends StatelessWidget {
  const WalletsListHeader({super.key, required this.metrics});

  final WalletsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final compact = metrics.isMobile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          walletL10nOr(context, 'walletTitleWalletsList', 'Wallets'),
          style: (compact
                  ? Theme.of(context).textTheme.titleLarge
                  : Theme.of(context).textTheme.headlineSmall)
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        SizedBox(height: metrics.toolbarFilterGap),
        Text(
          walletL10nOr(context,
            'walletSubtitleWalletsList',
            'Search users and filter by balance. Tap a row to open wallet details.',
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
      ],
    );
  }
}

class WalletsListToolbar extends StatefulWidget {
  const WalletsListToolbar({
    super.key,
    required this.state,
    required this.metrics,
    required this.searchController,
    required this.minBalanceController,
    required this.maxBalanceController,
  });

  final WalletsListLoaded state;
  final WalletsLayoutMetrics metrics;
  final TextEditingController searchController;
  final TextEditingController minBalanceController;
  final TextEditingController maxBalanceController;

  @override
  State<WalletsListToolbar> createState() => _WalletsListToolbarState();
}

class _WalletsListToolbarState extends State<WalletsListToolbar> {
  Timer? _balanceDebounce;

  @override
  void dispose() {
    _balanceDebounce?.cancel();
    super.dispose();
  }

  void _applyBalanceFilters() {
    _balanceDebounce?.cancel();
    _balanceDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      final minText = widget.minBalanceController.text.trim();
      final maxText = widget.maxBalanceController.text.trim();
      context.read<WalletsListBloc>().add(
            WalletsListBalanceFilterEvent(
              minBalance: minText.isEmpty ? null : double.tryParse(minText),
              maxBalance: maxText.isEmpty ? null : double.tryParse(maxText),
            ),
          );
    });
  }

  bool get _hasActiveFilters {
    final q = widget.state.query;
    return (q.search != null && q.search!.trim().isNotEmpty) ||
        q.minBalance != null ||
        q.maxBalance != null ||
        q.sort != WalletSort.balanceDesc;
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final bloc = context.read<WalletsListBloc>();
    final m = widget.metrics;
    final controlHeight = m.filterControlHeight;
    final gap = m.filterGap;

    return LayoutBuilder(
      builder: (context, constraints) {
        final veryNarrow = constraints.maxWidth < 520;
        final narrow = constraints.maxWidth < 760;
        final medium = constraints.maxWidth < 1040;

        const balanceFieldWidth = 148.0;

        final searchField = WalletsToolbarSearchField(
          controller: widget.searchController,
          hintText: walletL10nOr(context,
            'walletSearchUserHint',
            'Search by username, name, or email',
          ),
          onChanged: (value) => bloc.add(WalletsListSearchEvent(value)),
        );

        final minField = WalletsToolbarNumberField(
          controller: widget.minBalanceController,
          hintText: walletL10nOr(context, 'walletMinCoins', 'Min coins'),
          onChanged: (_) => _applyBalanceFilters(),
        );

        final maxField = WalletsToolbarNumberField(
          controller: widget.maxBalanceController,
          hintText: walletL10nOr(context, 'walletMaxCoins', 'Max coins'),
          onChanged: (_) => _applyBalanceFilters(),
        );

        final sortFilter = _WalletsSortDropdown(
          value: widget.state.query.sort,
          onChanged: (sort) {
            if (sort != null) {
              bloc.add(WalletsListSortChangedEvent(sort));
            }
          },
        );

        final clearButton = _hasActiveFilters
            ? WalletsToolbarClearButton(
                controlHeight: controlHeight,
                onPressed: () {
                  widget.searchController.clear();
                  widget.minBalanceController.clear();
                  widget.maxBalanceController.clear();
                  bloc.add(ClearWalletsListFiltersEvent());
                },
              )
            : null;

        Widget sized(Widget child, {double? width}) {
          return SizedBox(
            width: width,
            height: controlHeight,
            child: child,
          );
        }

        if (veryNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: minField),
                  SizedBox(width: gap),
                  Expanded(child: maxField),
                ],
              ),
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: sortFilter),
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
              searchField,
              SizedBox(height: gap),
              Row(
                children: [
                  Expanded(child: minField),
                  SizedBox(width: gap),
                  Expanded(child: maxField),
                  SizedBox(width: gap),
                  Expanded(child: sortFilter),
                  if (clearButton != null) ...[
                    SizedBox(width: gap),
                    clearButton,
                  ],
                ],
              ),
            ],
          );
        }

        if (medium) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              searchField,
              SizedBox(height: gap),
              Row(
                children: [
                  sized(minField, width: balanceFieldWidth),
                  SizedBox(width: gap),
                  sized(maxField, width: balanceFieldWidth),
                  SizedBox(width: gap),
                  Expanded(child: sortFilter),
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: searchField),
            SizedBox(width: gap),
            sized(minField, width: balanceFieldWidth),
            SizedBox(width: gap),
            sized(maxField, width: balanceFieldWidth),
            SizedBox(width: gap),
            sized(sortFilter, width: 168),
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

class _WalletsSortDropdown extends StatelessWidget {
  const _WalletsSortDropdown({
    required this.value,
    required this.onChanged,
  });

  final WalletSort value;
  final ValueChanged<WalletSort?> onChanged;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      height: ToolbarFilterStyle.controlHeight,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: ToolbarFilterStyle.boxDecoration(scheme),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<WalletSort>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: ToolbarFilterStyle.radius,
          dropdownColor: scheme.surface,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurface),
          hint: Text(
            walletL10nOr(context, 'walletSort', 'Sort'),
            style: textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          icon: Icon(
            Icons.swap_vert_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
          items: WalletSort.values
              .map(
                (sort) => DropdownMenuItem(
                  value: sort,
                  child: Text(
                    walletSortLabel(context, sort),
                    style: textTheme.bodySmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class WalletsListTableCard extends StatelessWidget {
  const WalletsListTableCard({
    super.key,
    required this.state,
    required this.metrics,
    required this.dateFmt,
  });

  final WalletsListLoaded state;
  final WalletsLayoutMetrics metrics;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    return WalletsDataListCard(
      total: state.meta.total,
      totalLabel: walletL10nOr(context, 'walletCountWallets', 'wallets'),
      isEmpty: state.wallets.isEmpty,
      emptyIcon: Icons.account_balance_wallet_outlined,
      emptyTitle: walletL10nOr(context, 'walletEmptyWallets', 'No wallets found'),
      emptySubtitle: walletL10nOr(context,
        'walletEmptyMsgWallets',
        'Try adjusting your search or balance filters.',
      ),
      page: state.meta.page,
      totalPages: state.meta.totalPages,
      onPage: (page) => context
          .read<WalletsListBloc>()
          .add(WalletsListPageChangedEvent(page)),
      child: metrics.useCompactTable
          ? _WalletsCompactList(
              wallets: state.wallets,
              dateFmt: dateFmt,
            )
          : _WalletsDesktopTable(
              wallets: state.wallets,
              dateFmt: dateFmt,
            ),
    );
  }
}

class _WalletsCompactList extends StatelessWidget {
  const _WalletsCompactList({
    required this.wallets,
    required this.dateFmt,
  });

  final List<WalletListItemEntity> wallets;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: wallets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return _WalletsCompactCard(
          wallet: wallets[index],
          dateFmt: dateFmt,
        );
      },
    );
  }
}

class _WalletsCompactCard extends StatelessWidget {
  const _WalletsCompactCard({
    required this.wallet,
    required this.dateFmt,
  });

  final WalletListItemEntity wallet;
  final DateFormat dateFmt;

  void _open(BuildContext context) {
    Navigator.of(context).pushNamed(
      AppRoutes.walletDetail,
      arguments: wallet.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final user = wallet.user;
    final updatedAt = dateFmt.format(wallet.updatedAt.toLocal());
    final ledgerCount = '${wallet.counts?.accountings ?? 0}';

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.65)),
      ),
      child: InkWell(
        onTap: () => _open(context),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              WalletUserAvatar(user: user),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? wallet.userId,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    if (user != null)
                      Text(
                        '@${user.username}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      walletL10nArgs(context,
                        'walletUpdatedAt',
                        {'date': updatedAt},
                        'Updated $updatedAt',
                      ),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CoinFormat.coins(wallet.balanceCoins),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    walletL10nArgs(context,
                      'walletSummaryLedgerCount',
                      {'count': ledgerCount},
                      '$ledgerCount ledger',
                    ),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WalletsDesktopTable extends StatelessWidget {
  const _WalletsDesktopTable({
    required this.wallets,
    required this.dateFmt,
  });

  final List<WalletListItemEntity> wallets;
  final DateFormat dateFmt;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.2),
        border: Border(
          top: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final showCounts = constraints.maxWidth >= 720;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                height: kWalletsTableHeaderHeight,
                color: scheme.surfaceContainerLow,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _WalletsRowLayout(
                  showCounts: showCounts,
                  user: Text(
                    walletL10nOr(context, 'walletColUser', 'User'),
                    style: _headerStyle(context),
                  ),
                  balance: Text(
                    walletL10nOr(context, 'walletColBalance', 'Balance'),
                    style: _headerStyle(context),
                  ),
                  ledger: Text(
                    walletL10nOr(context, 'walletColLedger', 'Ledger'),
                    style: _headerStyle(context),
                  ),
                  withdrawals: Text(
                    walletL10nOr(context, 'walletColWithdrawals', 'Withdrawals'),
                    style: _headerStyle(context),
                  ),
                  updated: Text(
                    walletL10nOr(context, 'walletColUpdated', 'Updated'),
                    style: _headerStyle(context),
                  ),
                  actions: const SizedBox(width: 36),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: wallets.length,
                  separatorBuilder: (_, index) {
                    if (index >= wallets.length - 1) {
                      return const SizedBox.shrink();
                    }
                    return Divider(
                      height: 1,
                      color: scheme.outlineVariant.withValues(alpha: 0.35),
                    );
                  },
                  itemBuilder: (context, index) {
                    return _WalletsTableRow(
                      wallet: wallets[index],
                      dateFmt: dateFmt,
                      striped: index.isOdd,
                      showCounts: showCounts,
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  TextStyle? _headerStyle(BuildContext context) {
    return Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontSize: 10,
          letterSpacing: 0.2,
        );
  }
}

class _WalletsTableRow extends StatefulWidget {
  const _WalletsTableRow({
    required this.wallet,
    required this.dateFmt,
    required this.striped,
    required this.showCounts,
  });

  final WalletListItemEntity wallet;
  final DateFormat dateFmt;
  final bool striped;
  final bool showCounts;

  @override
  State<_WalletsTableRow> createState() => _WalletsTableRowState();
}

class _WalletsTableRowState extends State<_WalletsTableRow> {
  bool _hovered = false;

  void _open() {
    Navigator.of(context).pushNamed(
      AppRoutes.walletDetail,
      arguments: widget.wallet.userId,
    );
  }

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final wallet = widget.wallet;
    final user = wallet.user;
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );

    final rowColor = _hovered
        ? scheme.surfaceContainerHighest
        : widget.striped
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.35)
            : scheme.surface;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: _open,
          child: SizedBox(
            height: kWalletsTableRowHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _WalletsRowLayout(
                showCounts: widget.showCounts,
                user: Row(
                  children: [
                    WalletUserAvatar(user: user, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? wallet.userId,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cellStyle?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (user != null)
                            Text(
                              '@${user.username}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: cellStyle?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                balance: Text(
                  CoinFormat.coins(wallet.balanceCoins),
                  style: cellStyle?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                ledger: Text(
                  '${wallet.counts?.accountings ?? 0}',
                  style: cellStyle,
                ),
                withdrawals: Text(
                  '${wallet.counts?.withdrawals ?? 0}',
                  style: cellStyle,
                ),
                updated: Text(
                  widget.dateFmt.format(wallet.updatedAt.toLocal()),
                  style: cellStyle?.copyWith(color: scheme.onSurfaceVariant),
                ),
                actions: IconButton(
                  tooltip: walletL10nOr(context, 'walletViewWallet', 'View wallet'),
                  visualDensity: VisualDensity.compact,
                  onPressed: _open,
                  icon: const Icon(Icons.open_in_new_rounded, size: 18),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WalletsRowLayout extends StatelessWidget {
  const _WalletsRowLayout({
    required this.showCounts,
    required this.user,
    required this.balance,
    required this.ledger,
    required this.withdrawals,
    required this.updated,
    required this.actions,
  });

  final bool showCounts;
  final Widget user;
  final Widget balance;
  final Widget ledger;
  final Widget withdrawals;
  final Widget updated;
  final Widget actions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 4, child: user),
        Expanded(
          flex: 2,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: balance,
          ),
        ),
        if (showCounts) ...[
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: ledger,
            ),
          ),
          Expanded(
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: withdrawals,
            ),
          ),
        ],
        Expanded(
          flex: 2,
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: updated,
          ),
        ),
        SizedBox(width: 36, child: actions),
      ],
    );
  }
}
