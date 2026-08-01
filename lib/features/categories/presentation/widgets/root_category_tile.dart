import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';
import 'category_callbacks.dart';
import 'category_icon.dart';
import 'category_ui_primitives.dart';

/// Compact selectable root category item for the master (left) panel.
class RootCategoryTile extends StatelessWidget {
  const RootCategoryTile({
    super.key,
    required this.category,
    required this.subcategoryCount,
    required this.isFocused,
    required this.isSelected,
    required this.panelMetrics,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity category;
  final int subcategoryCount;
  final bool isFocused;
  final bool isSelected;
  final CategoriesPanelMetrics panelMetrics;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoriesBloc, CategoriesState, _RootTileData>(
      selector: (state) {
        if (state is! CategoriesLoaded) {
          return const _RootTileData.empty();
        }
        return _RootTileData(
          highlighted: state.isCategoryHighlighted(category.id),
          isSubmitting: state.isSubmitting,
        );
      },
      builder: (context, data) {
        return RepaintBoundary(
          child: _RootCategoryTileBody(
            key: ValueKey(category.id),
            category: category,
            subcategoryCount: subcategoryCount,
            isFocused: isFocused,
            isSelected: isSelected,
            highlighted: data.highlighted,
            isSubmitting: data.isSubmitting,
            panelMetrics: panelMetrics,
            onFormRequest: onFormRequest,
            onDeleteRequest: onDeleteRequest,
          ),
        );
      },
    );
  }
}

class _RootTileData {
  const _RootTileData({
    required this.highlighted,
    required this.isSubmitting,
  });

  const _RootTileData.empty()
      : highlighted = false,
        isSubmitting = false;

  final bool highlighted;
  final bool isSubmitting;
}

class _RootCategoryTileBody extends StatelessWidget {
  const _RootCategoryTileBody({
    super.key,
    required this.category,
    required this.subcategoryCount,
    required this.isFocused,
    required this.isSelected,
    required this.highlighted,
    required this.isSubmitting,
    required this.panelMetrics,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity category;
  final int subcategoryCount;
  final bool isFocused;
  final bool isSelected;
  final bool highlighted;
  final bool isSubmitting;
  final CategoriesPanelMetrics panelMetrics;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent = categoryAccentColor(category.slug, category.name);
    final compact = panelMetrics.rootTileCompact;
    final ultraCompact = panelMetrics.rootTileUltraCompact;
    final iconSize = panelMetrics.rootIconSize;
    final radius = compact ? 10.0 : 12.0;

    final backgroundColor = isFocused
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : scheme.surfaceContainerLowest;
    final borderColor = isFocused
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outlineVariant;

    final menuButton = PopupMenuButton<String>(
      tooltip: l10n.tOr('moreActions', 'More'),
      icon: Icon(Icons.more_vert_rounded, size: compact ? 16 : 18),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints(
        minWidth: compact ? 28 : 32,
        minHeight: compact ? 28 : 32,
      ),
      itemBuilder: (context) => [
        if (!panelMetrics.rootShowInlineEdit)
          PopupMenuItem(
            value: 'edit',
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.edit_outlined, size: 18),
              title: Text(l10n.t('edit')),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        PopupMenuItem(
          value: 'add_sub',
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.add_rounded, size: 18),
            title: Text(l10n.t('addSubcategory')),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.delete_outline_rounded,
                size: 18, color: scheme.error),
            title: Text(l10n.t('delete')),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onFormRequest(editing: category);
          case 'add_sub':
            onFormRequest(parentForNew: category);
          case 'delete':
            onDeleteRequest(category);
        }
      },
    );

    return Material(
      color: backgroundColor,
      elevation: isFocused ? 1 : 0,
      shadowColor: scheme.shadow.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(radius),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: isSubmitting
            ? null
            : () => bloc.add(FocusRootCategoryEvent(category.id)),
        hoverColor: scheme.primary.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor,
              width: isFocused ? 1.5 : 1,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            compact ? 4 : 8,
            compact ? 8 : 10,
            compact ? 2 : 6,
            compact ? 8 : 10,
          ),
          child: Row(
            children: [
              if (!ultraCompact)
                Checkbox(
                  value: isSelected,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: isSubmitting
                      ? null
                      : (_) => bloc.add(
                            ToggleCategorySelectionEvent(category.id),
                          ),
                ),
              CategoryIcon(
                category: category,
                size: iconSize,
                borderRadius: BorderRadius.circular(compact ? 8 : 10),
                backgroundColor: accent.withValues(alpha: 0.12),
                iconColor: accent,
              ),
              SizedBox(width: compact ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      maxLines: ultraCompact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: compact ? 12.5 : null,
                            color: highlighted ? scheme.primary : null,
                          ),
                    ),
                    if (panelMetrics.rootShowCountBadge ||
                        panelMetrics.rootShowStatusBadge) ...[
                      SizedBox(height: compact ? 2 : 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (panelMetrics.rootShowCountBadge)
                            _CountBadge(
                              count: subcategoryCount,
                              label: l10n.tOr('subcategoriesShort', 'subs'),
                              color: accent,
                              compact: compact,
                            ),
                          if (panelMetrics.rootShowStatusBadge)
                            CategoryStatusBadge(isActive: category.isActive),
                        ],
                      ),
                    ] else if (subcategoryCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          formatCategoryCount(subcategoryCount),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (subcategoryCount > 0)
                Icon(
                  Icons.chevron_right_rounded,
                  size: compact ? 18 : 20,
                  color: isFocused ? scheme.primary : scheme.onSurfaceVariant,
                ),
              if (panelMetrics.rootShowInlineEdit)
                IconButton(
                  tooltip: l10n.t('edit'),
                  icon: Icon(Icons.edit_outlined, size: compact ? 16 : 18),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(
                    minWidth: compact ? 28 : 32,
                    minHeight: compact ? 28 : 32,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () => onFormRequest(editing: category),
                ),
              menuButton,
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.label,
    required this.color,
    this.compact = false,
  });

  final int count;
  final String label;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: compact ? 10 : 11, color: color),
          const SizedBox(width: 4),
          Text(
            compact ? formatCategoryCount(count) : '${formatCategoryCount(count)} $label',
            style: TextStyle(
              fontSize: compact ? 9.5 : 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
