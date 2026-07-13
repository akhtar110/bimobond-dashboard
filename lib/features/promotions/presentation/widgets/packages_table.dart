import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/promotion_entities.dart';
import 'promotions_dashboard_widgets.dart';
import 'promotions_data_display_widgets.dart';

enum PackagesTableDensity { narrow, compact, wide }

PackagesTableDensity packagesTableDensityForWidth(double width) {
  if (width < 640) return PackagesTableDensity.narrow;
  if (width < 980) return PackagesTableDensity.compact;
  return PackagesTableDensity.wide;
}

class PackagesTable extends StatelessWidget {
  const PackagesTable({
    super.key,
    required this.packages,
    required this.dateFmt,
    required this.selectedIds,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onToggleSelect,
    required this.onSelectAllVisible,
    this.isSaving = false,
    this.canWrite = true,
  });

  final List<PromotionPackageEntity> packages;
  final DateFormat dateFmt;
  final Set<String> selectedIds;
  final ValueChanged<PromotionPackageEntity> onEdit;
  final void Function(PromotionPackageEntity pkg, {required bool activate})
      onToggleActive;
  final ValueChanged<PromotionPackageEntity> onDelete;
  final ValueChanged<String> onToggleSelect;
  final VoidCallback onSelectAllVisible;
  final bool isSaving;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final density = packagesTableDensityForWidth(constraints.maxWidth);
        if (density == PackagesTableDensity.narrow) {
          return _PackagesCardList(
            packages: packages,
            dateFmt: dateFmt,
            selectedIds: selectedIds,
            isSaving: isSaving,
            canWrite: canWrite,
            onEdit: onEdit,
            onToggleActive: onToggleActive,
            onDelete: onDelete,
            onToggleSelect: onToggleSelect,
          );
        }
        return _PackagesDataTable(
          packages: packages,
          dateFmt: dateFmt,
          selectedIds: selectedIds,
          density: density,
          isSaving: isSaving,
          canWrite: canWrite,
          onEdit: onEdit,
          onToggleActive: onToggleActive,
          onDelete: onDelete,
          onToggleSelect: onToggleSelect,
          onSelectAllVisible: onSelectAllVisible,
        );
      },
    );
  }
}

class _PackagesDataTable extends StatelessWidget {
  const _PackagesDataTable({
    required this.packages,
    required this.dateFmt,
    required this.selectedIds,
    required this.density,
    required this.isSaving,
    required this.canWrite,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onToggleSelect,
    required this.onSelectAllVisible,
  });

  final List<PromotionPackageEntity> packages;
  final DateFormat dateFmt;
  final Set<String> selectedIds;
  final PackagesTableDensity density;
  final bool isSaving;
  final bool canWrite;
  final ValueChanged<PromotionPackageEntity> onEdit;
  final void Function(PromotionPackageEntity pkg, {required bool activate})
      onToggleActive;
  final ValueChanged<PromotionPackageEntity> onDelete;
  final ValueChanged<String> onToggleSelect;
  final VoidCallback onSelectAllVisible;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final headerStyle = promotionsTableHeaderStyle(context);
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );
    final allSelected =
        packages.isNotEmpty && packages.every((p) => selectedIds.contains(p.id));
    final someSelected =
        !allSelected && packages.any((p) => selectedIds.contains(p.id));
    final showCreated = density == PackagesTableDensity.wide;

    return DecoratedBox(
      decoration: promotionsInnerTableDecoration(scheme),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: kPromotionsDataTableHeaderHeight,
              color: scheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  if (canWrite)
                    SizedBox(
                      width: 40,
                      child: Checkbox(
                        tristate: true,
                        value: allSelected
                            ? true
                            : someSelected
                                ? null
                                : false,
                        onChanged: isSaving ? null : (_) => onSelectAllVisible(),
                      ),
                    ),
                  Expanded(
                    flex: 3,
                    child: Text(l10n.t('name'), style: headerStyle),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('promoPrice'), style: headerStyle),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      l10n.t('promoImpressionCount'),
                      style: headerStyle,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('status'), style: headerStyle),
                  ),
                  if (showCreated)
                    Expanded(
                      flex: 2,
                      child: Text(l10n.t('createdAt'), style: headerStyle),
                    ),
                  SizedBox(
                    width: canWrite ? 48 : 40,
                    child: Icon(
                      Icons.more_horiz_rounded,
                      size: 16,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (var i = 0; i < packages.length; i++) ...[
              _PackageTableRow(
                package: packages[i],
                dateFmt: dateFmt,
                cellStyle: cellStyle,
                striped: i.isOdd,
                selected: selectedIds.contains(packages[i].id),
                showCreated: showCreated,
                isSaving: isSaving,
                canWrite: canWrite,
                onEdit: () => onEdit(packages[i]),
                onToggleActive: (activate) =>
                    onToggleActive(packages[i], activate: activate),
                onDelete: () => onDelete(packages[i]),
                onToggleSelect: () => onToggleSelect(packages[i].id),
              ),
              if (i < packages.length - 1)
                Divider(
                  height: 1,
                  color: scheme.outlineVariant.withValues(alpha: 0.35),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PackageTableRow extends StatefulWidget {
  const _PackageTableRow({
    required this.package,
    required this.dateFmt,
    required this.cellStyle,
    required this.striped,
    required this.selected,
    required this.showCreated,
    required this.isSaving,
    required this.canWrite,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onToggleSelect,
  });

  final PromotionPackageEntity package;
  final DateFormat dateFmt;
  final TextStyle? cellStyle;
  final bool striped;
  final bool selected;
  final bool showCreated;
  final bool isSaving;
  final bool canWrite;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelect;

  @override
  State<_PackageTableRow> createState() => _PackageTableRowState();
}

class _PackageTableRowState extends State<_PackageTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pkg = widget.package;

    Color rowColor;
    if (widget.selected) {
      rowColor = scheme.primaryContainer.withValues(alpha: 0.35);
    } else if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: rowColor,
        child: SizedBox(
          height: kPromotionsDataRowHeight,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                if (widget.canWrite)
                  SizedBox(
                    width: 40,
                    child: Checkbox(
                      value: widget.selected,
                      onChanged:
                          widget.isSaving ? null : (_) => widget.onToggleSelect(),
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: Text(
                    pkg.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style:
                        widget.cellStyle?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    CoinFormat.coins(pkg.priceCoins),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.cellStyle,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    NumberFormat.compact().format(pkg.impressionCount),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.cellStyle,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: _PackageStatusBadge(isActive: pkg.isActive),
                  ),
                ),
                if (widget.showCreated)
                  Expanded(
                    flex: 2,
                    child: Text(
                      widget.dateFmt.format(pkg.createdAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: widget.cellStyle?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                SizedBox(
                  width: widget.canWrite ? 48 : 40,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _PackageActionsMenu(
                      package: pkg,
                      isSaving: widget.isSaving,
                      canWrite: widget.canWrite,
                      onEdit: widget.onEdit,
                      onToggleActive: widget.onToggleActive,
                      onDelete: widget.onDelete,
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

class _PackagesCardList extends StatelessWidget {
  const _PackagesCardList({
    required this.packages,
    required this.dateFmt,
    required this.selectedIds,
    required this.isSaving,
    required this.canWrite,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onToggleSelect,
  });

  final List<PromotionPackageEntity> packages;
  final DateFormat dateFmt;
  final Set<String> selectedIds;
  final bool isSaving;
  final bool canWrite;
  final ValueChanged<PromotionPackageEntity> onEdit;
  final void Function(PromotionPackageEntity pkg, {required bool activate})
      onToggleActive;
  final ValueChanged<PromotionPackageEntity> onDelete;
  final ValueChanged<String> onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        for (var i = 0; i < packages.length; i++) ...[
          if (i > 0) const SizedBox(height: PromotionsSpace.sm),
          _PackageCard(
            package: packages[i],
            dateFmt: dateFmt,
            selected: selectedIds.contains(packages[i].id),
            isSaving: isSaving,
            canWrite: canWrite,
            priceLabel: l10n.t('promoPrice'),
            impressionsLabel: l10n.t('promoImpressionCount'),
            onEdit: () => onEdit(packages[i]),
            onToggleActive: (activate) =>
                onToggleActive(packages[i], activate: activate),
            onDelete: () => onDelete(packages[i]),
            onToggleSelect: () => onToggleSelect(packages[i].id),
          ),
        ],
      ],
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({
    required this.package,
    required this.dateFmt,
    required this.selected,
    required this.isSaving,
    required this.canWrite,
    required this.priceLabel,
    required this.impressionsLabel,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
    required this.onToggleSelect,
  });

  final PromotionPackageEntity package;
  final DateFormat dateFmt;
  final bool selected;
  final bool isSaving;
  final bool canWrite;
  final String priceLabel;
  final String impressionsLabel;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;
  final VoidCallback onToggleSelect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: selected
          ? scheme.primaryContainer.withValues(alpha: 0.28)
          : scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: canWrite && !isSaving ? onToggleSelect : null,
        onLongPress: canWrite && !isSaving ? onEdit : null,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.45)
                  : scheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (canWrite)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Checkbox(
                      value: selected,
                      onChanged: isSaving ? null : (_) => onToggleSelect(),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              package.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _PackageStatusBadge(isActive: package.isActive),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _MetaChip(
                            icon: Icons.payments_outlined,
                            label: '$priceLabel · ${CoinFormat.coins(package.priceCoins)}',
                          ),
                          _MetaChip(
                            icon: Icons.visibility_outlined,
                            label:
                                '$impressionsLabel · ${NumberFormat.compact().format(package.impressionCount)}',
                          ),
                          _MetaChip(
                            icon: Icons.calendar_today_outlined,
                            label: dateFmt.format(package.createdAt),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _PackageActionsMenu(
                  package: package,
                  isSaving: isSaving,
                  canWrite: canWrite,
                  onEdit: onEdit,
                  onToggleActive: onToggleActive,
                  onDelete: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _PackageStatusBadge extends StatelessWidget {
  const _PackageStatusBadge({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final color = isActive ? scheme.primary : scheme.onSurfaceVariant;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isActive ? l10n.t('active') : l10n.t('inactive'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PackageActionsMenu extends StatelessWidget {
  const _PackageActionsMenu({
    required this.package,
    required this.isSaving,
    required this.canWrite,
    required this.onEdit,
    required this.onToggleActive,
    required this.onDelete,
  });

  final PromotionPackageEntity package;
  final bool isSaving;
  final bool canWrite;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      enabled: !isSaving,
      padding: EdgeInsets.zero,
      iconSize: 20,
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'activate':
            onToggleActive(true);
          case 'deactivate':
            onToggleActive(false);
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        if (canWrite)
          PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                const SizedBox(width: 8),
                Text(l10n.t('edit')),
              ],
            ),
          ),
        if (canWrite)
          PopupMenuItem(
            value: package.isActive ? 'deactivate' : 'activate',
            child: Row(
              children: [
                Icon(
                  package.isActive
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  package.isActive ? l10n.t('deactivate') : l10n.t('activate'),
                ),
              ],
            ),
          ),
        if (canWrite)
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 18, color: scheme.error),
                const SizedBox(width: 8),
                Text(
                  l10n.t('delete'),
                  style: TextStyle(color: scheme.error),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
