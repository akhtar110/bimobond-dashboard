import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../../../core/utils/money_format.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/wallet_entities.dart';
import '../utils/wallet_labels.dart';
import '../utils/wallets_responsive.dart';
import 'wallets_dashboard_widgets.dart';
import 'wallets_page_widgets.dart';

class CoinPackagesTableCard extends StatelessWidget {
  const CoinPackagesTableCard({
    super.key,
    required this.packages,
    required this.metrics,
    required this.canManage,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CoinPackageEntity> packages;
  final WalletsLayoutMetrics metrics;
  final bool canManage;
  final bool isSaving;
  final ValueChanged<CoinPackageEntity> onEdit;
  final ValueChanged<CoinPackageEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    return WalletsDataListCard(
      total: packages.length,
      totalLabel: walletL10nOr(context, 'walletCountPackages', 'packages'),
      isEmpty: packages.isEmpty,
      emptyIcon: Icons.inventory_2_outlined,
      emptyTitle: walletL10nOr(context, 'walletEmptyPackages', 'No packages'),
      emptySubtitle: canManage
          ? walletL10nOr(context,
              'walletEmptyMsgPackagesCreate',
              'Create a package to offer coin bundles for purchase.',
            )
          : null,
      child: metrics.useCompactTable
          ? _CoinPackagesCompactList(
              packages: packages,
              canManage: canManage,
              isSaving: isSaving,
              onEdit: onEdit,
              onDelete: onDelete,
            )
          : _CoinPackagesDesktopTable(
              packages: packages,
              canManage: canManage,
              isSaving: isSaving,
              onEdit: onEdit,
              onDelete: onDelete,
            ),
    );
  }
}

class _CoinPackagesCompactList extends StatelessWidget {
  const _CoinPackagesCompactList({
    required this.packages,
    required this.canManage,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CoinPackageEntity> packages;
  final bool canManage;
  final bool isSaving;
  final ValueChanged<CoinPackageEntity> onEdit;
  final ValueChanged<CoinPackageEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final activeLabel = walletL10nOr(context, 'active', 'Active');
    final inactiveLabel = walletL10nOr(context, 'inactive', 'Inactive');

    return WalletsCompactListFrame(
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        return WalletsCompactCard(
          title: pkg.name,
          subtitle: CoinFormat.coins(pkg.coinAmount),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                MoneyFormat.format(pkg.price, pkg.currencyCode),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              WalletsStatusChip(
                label: pkg.isActive ? activeLabel : inactiveLabel,
                tone: pkg.isActive
                    ? WalletsChipTone.success
                    : WalletsChipTone.neutral,
              ),
              if (canManage) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: walletL10nOr(context, 'edit', 'Edit'),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: isSaving ? null : () => onEdit(pkg),
                    ),
                    IconButton(
                      tooltip: walletL10nOr(context, 'delete', 'Delete'),
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: scheme.error,
                      ),
                      onPressed: isSaving ? null : () => onDelete(pkg),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _CoinPackagesDesktopTable extends StatelessWidget {
  const _CoinPackagesDesktopTable({
    required this.packages,
    required this.canManage,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final List<CoinPackageEntity> packages;
  final bool canManage;
  final bool isSaving;
  final ValueChanged<CoinPackageEntity> onEdit;
  final ValueChanged<CoinPackageEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    return WalletsDesktopTableFrame(
      header: Row(
        children: [
          Expanded(
            flex: 3,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColName', 'Name'),
            ),
          ),
          Expanded(
            flex: 2,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColCoins', 'Coins'),
            ),
          ),
          Expanded(
            flex: 2,
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColFiatPrice', 'Fiat price'),
            ),
          ),
          Expanded(
            child: WalletsTableHeaderLabel(
              walletL10nOr(context, 'walletColStatus', 'Status'),
            ),
          ),
          if (canManage)
            SizedBox(
              width: 88,
              child: WalletsTableHeaderLabel(
                walletL10nOr(context, 'walletColActions', 'Actions'),
              ),
            ),
        ],
      ),
      rows: [
        for (var i = 0; i < packages.length; i++)
          _CoinPackageRow(
            package: packages[i],
            striped: i.isOdd,
            canManage: canManage,
            isSaving: isSaving,
            onEdit: onEdit,
            onDelete: onDelete,
          ),
      ],
    );
  }
}

class _CoinPackageRow extends StatelessWidget {
  const _CoinPackageRow({
    required this.package,
    required this.striped,
    required this.canManage,
    required this.isSaving,
    required this.onEdit,
    required this.onDelete,
  });

  final CoinPackageEntity package;
  final bool striped;
  final bool canManage;
  final bool isSaving;
  final ValueChanged<CoinPackageEntity> onEdit;
  final ValueChanged<CoinPackageEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final l10n = context.l10n;

    final scheme = Theme.of(context).colorScheme;
    final cellStyle = walletsTableCellStyle(context);
    final pkg = package;
    final activeLabel = walletL10nOr(context, 'active', 'Active');
    final inactiveLabel = walletL10nOr(context, 'inactive', 'Inactive');

    return WalletsHoverTableRow(
      striped: striped,
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              pkg.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: cellStyle?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              CoinFormat.coins(pkg.coinAmount),
              style: cellStyle?.copyWith(
                fontWeight: FontWeight.w800,
                color: scheme.primary,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              MoneyFormat.format(pkg.price, pkg.currencyCode),
              style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: WalletsStatusChip(
              label: pkg.isActive ? activeLabel : inactiveLabel,
              tone: pkg.isActive
                  ? WalletsChipTone.success
                  : WalletsChipTone.neutral,
            ),
          ),
          if (canManage)
            SizedBox(
              width: 88,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: walletL10nOr(context, 'edit', 'Edit'),
                    visualDensity: VisualDensity.compact,
                    onPressed: isSaving ? null : () => onEdit(pkg),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                  ),
                  IconButton(
                    tooltip: walletL10nOr(context, 'delete', 'Delete'),
                    visualDensity: VisualDensity.compact,
                    onPressed: isSaving ? null : () => onDelete(pkg),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: scheme.error,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
