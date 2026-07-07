import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/coin_format.dart';
import '../../domain/entities/promotion_entities.dart';
import 'promotions_data_display_widgets.dart';

class PackagesTable extends StatelessWidget {
  const PackagesTable({
    super.key,
    required this.packages,
    required this.dateFmt,
    required this.onEdit,
    required this.onToggleActive,
    this.isSaving = false,
  });

  final List<PromotionPackageEntity> packages;
  final DateFormat dateFmt;
  final ValueChanged<PromotionPackageEntity> onEdit;
  final void Function(PromotionPackageEntity pkg, {required bool activate})
      onToggleActive;
  final bool isSaving;

  @override
  Widget build(BuildContext context) {
    if (packages.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final headerStyle = promotionsTableHeaderStyle(context);
    final cellStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: 11.5,
          height: 1.25,
        );

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
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
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
                  Expanded(
                    flex: 2,
                    child: Text(l10n.t('createdAt'), style: headerStyle),
                  ),
                  SizedBox(
                    width: 72,
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
                isSaving: isSaving,
                onEdit: () => onEdit(packages[i]),
                onToggleActive: (activate) =>
                    onToggleActive(packages[i], activate: activate),
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
    required this.isSaving,
    required this.onEdit,
    required this.onToggleActive,
  });

  final PromotionPackageEntity package;
  final DateFormat dateFmt;
  final TextStyle? cellStyle;
  final bool striped;
  final bool isSaving;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggleActive;

  @override
  State<_PackageTableRow> createState() => _PackageTableRowState();
}

class _PackageTableRowState extends State<_PackageTableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final pkg = widget.package;

    Color rowColor;
    if (_hovered) {
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
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    pkg.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: widget.cellStyle?.copyWith(fontWeight: FontWeight.w700),
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
                    '${pkg.impressionCount}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.cellStyle,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    pkg.isActive ? l10n.t('active') : l10n.t('inactive'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: widget.cellStyle?.copyWith(
                      color: pkg.isActive
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
                  width: 72,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: l10n.t('edit'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        onPressed: widget.isSaving ? null : widget.onEdit,
                      ),
                      IconButton(
                        tooltip: pkg.isActive
                            ? l10n.t('deactivate')
                            : l10n.t('activate'),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                        icon: Icon(
                          pkg.isActive
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 18,
                        ),
                        onPressed: widget.isSaving
                            ? null
                            : () => widget.onToggleActive(!pkg.isActive),
                      ),
                    ],
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
