import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/status_chip.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../bloc/filters_effects_state.dart';
import '../utils/filters_effects_responsive.dart';

class CatalogTab extends StatelessWidget {
  const CatalogTab({
    super.key,
    required this.loaded,
    required this.metrics,
  });

  final FiltersEffectsLoaded loaded;
  final FiltersEffectsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final catalog = loaded.catalog;

    if (catalog == null) {
      return Center(
        child: EmptyView(
          message: l10n.tOr('feNoCatalog', 'Catalog not loaded.'),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Padding(
              padding: EdgeInsetsDirectional.all(metrics.isMobile ? 12 : 16),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: scheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.tOr('feCatalogVersionLabel', 'Version: ${catalog.version}'),
                      textAlign: TextAlign.start,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: metrics.sectionGap),
          Text(
            l10n.tOr('feFilterCategories', 'Filter categories'),
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: metrics.filterGap),
          if (catalog.filterCategories.isEmpty)
            Text(l10n.tOr('feNoFilterCategories', 'No filter categories found.'))
          else
            ...catalog.filterCategories.map(
              (category) => _CatalogCategoryTile(
                title: category.labelKey,
                subtitle: category.slug,
                isActive: category.isActive,
                children: category.filters
                    .map((f) => f.displayLabel)
                    .toList(growable: false),
                emptyLabel: l10n.tOr('feNoFiltersInCategory', 'No filters'),
              ),
            ),
          SizedBox(height: metrics.sectionGap),
          Text(
            l10n.tOr('feEffectCategories', 'Effect categories'),
            textAlign: TextAlign.start,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: metrics.filterGap),
          if (catalog.effectCategories.isEmpty)
            Text(l10n.tOr('feNoEffectCategories', 'No effect categories found.'))
          else
            ...catalog.effectCategories.map(
              (category) => _CatalogCategoryTile(
                title: category.labelKey,
                subtitle: category.slug,
                isActive: category.isActive,
                children: category.effects
                    .map((e) => e.emoji != null ? '${e.emoji} ${e.labelKey}' : e.labelKey)
                    .toList(growable: false),
                emptyLabel: l10n.tOr('feNoEffectsInCategory', 'No effects'),
              ),
            ),
        ],
      ),
    );
  }
}

class _CatalogCategoryTile extends StatelessWidget {
  const _CatalogCategoryTile({
    required this.title,
    required this.subtitle,
    required this.isActive,
    required this.children,
    required this.emptyLabel,
  });

  final String title;
  final String subtitle;
  final bool isActive;
  final List<String> children;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
          title: Text(title, textAlign: TextAlign.start),
          subtitle: Text(subtitle, textAlign: TextAlign.start),
          trailing: DashboardStatusChip(
            label: isActive
                ? l10n.tOr('feActive', 'Active')
                : l10n.tOr('feInactive', 'Inactive'),
            tone: isActive ? DashboardStatusTone.success : DashboardStatusTone.neutral,
          ),
          children: [
            if (children.isEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Text(emptyLabel),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final child in children)
                    Chip(
                      label: Text(child),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
