import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../promotions/presentation/widgets/promotions_dashboard_widgets.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../utils/filters_effects_responsive.dart';

/// Compact KPI strip — tiles size to content; horizontal scroll on wide screens.
class FiltersEffectsOverviewCards extends StatelessWidget {
  const FiltersEffectsOverviewCards({
    super.key,
    required this.overview,
    this.metrics,
  });

  final FiltersEffectsOverviewEntity overview;
  final FiltersEffectsLayoutMetrics? metrics;

  static const stripHeight = 44.0;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final dateFmt = DateFormat.yMMMd();
    final published = overview.catalogPublishedAt != null
        ? dateFmt.format(overview.catalogPublishedAt!.toLocal())
        : l10n.tOr('feNeverPublished', 'Not published');

    final items = <_FeKpiItem>[
      _FeKpiItem(
        label: l10n.tOr('feFiltersTotal', 'Filters'),
        value: '${overview.filters.total}',
        icon: Icons.filter_rounded,
      ),
      _FeKpiItem(
        label: l10n.tOr('feFiltersActive', 'Active filters'),
        value: '${overview.filters.active}',
        icon: Icons.check_circle_outline_rounded,
      ),
      _FeKpiItem(
        label: l10n.tOr('feFiltersInactive', 'Inactive filters'),
        value: '${overview.filters.inactive}',
        icon: Icons.pause_circle_outline_rounded,
      ),
      _FeKpiItem(
        label: l10n.tOr('feFilterCategoriesTotal', 'Filter categories'),
        value: '${overview.filterCategories.total}',
        icon: Icons.category_outlined,
      ),
      _FeKpiItem(
        label: l10n.tOr('feEffectsTotal', 'Effects'),
        value: '${overview.effects.total}',
        icon: Icons.auto_awesome_outlined,
      ),
      _FeKpiItem(
        label: l10n.tOr('feEffectsActive', 'Active effects'),
        value: '${overview.effects.active}',
        icon: Icons.star_outline_rounded,
      ),
      _FeKpiItem(
        label: l10n.tOr('feEffectsInactive', 'Inactive effects'),
        value: '${overview.effects.inactive}',
        icon: Icons.block_outlined,
      ),
      _FeKpiItem(
        label: l10n.tOr('feEffectCategoriesTotal', 'Effect categories'),
        value: '${overview.effectCategories.total}',
        icon: Icons.layers_outlined,
      ),
      _FeKpiItem(
        label: l10n.tOr('feCatalogVersion', 'Catalog version'),
        value: overview.catalogVersion,
        icon: Icons.publish_rounded,
        tooltip: '${l10n.tOr('feCatalogPublished', 'Published')}: $published',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = metrics?.filterGap ?? PromotionsSpace.sm;
        final useWrap = constraints.maxWidth < 720;

        if (useWrap) {
          return Wrap(
            spacing: gap,
            runSpacing: gap,
            children: [
              for (final item in items)
                _CompactKpiTile(item: item, layout: _KpiTileLayout.wrap),
            ],
          );
        }

        return SizedBox(
          height: stripHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.hardEdge,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0) SizedBox(width: gap),
                  _CompactKpiTile(
                    item: items[i],
                    layout: _KpiTileLayout.strip,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class FiltersEffectsOverviewSkeleton extends StatelessWidget {
  const FiltersEffectsOverviewSkeleton({super.key, this.metrics});

  final FiltersEffectsLayoutMetrics? metrics;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const widths = [96.0, 112.0, 120.0, 132.0, 96.0, 112.0, 120.0, 128.0, 140.0];

    return SizedBox(
      height: FiltersEffectsOverviewCards.stripHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          children: [
            for (var i = 0; i < widths.length; i++) ...[
              if (i > 0) const SizedBox(width: PromotionsSpace.sm),
              Container(
                width: widths[i],
                height: FiltersEffectsOverviewCards.stripHeight,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum _KpiTileLayout { strip, wrap }

class _FeKpiItem {
  const _FeKpiItem({
    required this.label,
    required this.value,
    required this.icon,
    this.tooltip,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? tooltip;
}

class _CompactKpiTile extends StatelessWidget {
  const _CompactKpiTile({
    required this.item,
    required this.layout,
  });

  final _FeKpiItem item;
  final _KpiTileLayout layout;

  static const minTileWidth = 72.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tooltip = item.tooltip ?? '${item.value} · ${item.label}';
    final labelStyle = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: scheme.onSurfaceVariant,
          fontSize: 10,
          height: 1.15,
        );
    final valueStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          height: 1.05,
        );

    final labelMaxLines = layout == _KpiTileLayout.wrap ? 3 : 1;

    return Tooltip(
      message: tooltip,
      child: Container(
        constraints: BoxConstraints(
          minWidth: minTileWidth,
          minHeight: layout == _KpiTileLayout.strip
              ? FiltersEffectsOverviewCards.stripHeight
              : 40,
        ),
        padding: const EdgeInsetsDirectional.fromSTEB(10, 5, 12, 5),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.45),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(item.icon, size: 14, color: scheme.primary),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.value,
                  style: valueStyle,
                ),
                Text(
                  item.label,
                  maxLines: labelMaxLines,
                  softWrap: true,
                  style: labelStyle,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
