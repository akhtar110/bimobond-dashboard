import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';
import 'category_callbacks.dart';
import 'category_icon.dart';
import 'category_ui_primitives.dart';

/// Shared column layout for subcategory header + rows (keeps alignment responsive).
class _SubcategoryTableLayout extends StatelessWidget {
  const _SubcategoryTableLayout({
    required this.metrics,
    required this.checkboxSlot,
    required this.iconSlot,
    required this.name,
    required this.parent,
    required this.status,
    required this.childrenColumn,
    required this.updated,
    required this.actions,
    this.showParentColumn = true,
  });

  final CategoriesPanelMetrics metrics;
  final Widget checkboxSlot;
  final Widget iconSlot;
  final Widget name;
  final Widget parent;
  final Widget status;
  final Widget childrenColumn;
  final Widget updated;
  final Widget actions;
  final bool showParentColumn;

  @override
  Widget build(BuildContext context) {
    final showParent = showParentColumn && metrics.subcategoryShowParent;
    final showChildren = metrics.subcategoryShowChildren;
    final showUpdated = metrics.subcategoryShowUpdated;
    final compactMeta = metrics.isCompact;
    final actionsWidth = metrics.subcategoryActionsWidth;
    final horizontalPadding = metrics.listHorizontalPadding;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: compactMeta ? 5 : 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: compactMeta ? 34 : 40,
            child: checkboxSlot,
          ),
          SizedBox(
            width: compactMeta ? 30 : 34,
            child: iconSlot,
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: name,
            ),
          ),
          if (showParent)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: parent,
              ),
            ),
          if (showChildren || showUpdated)
            Expanded(
              flex: compactMeta ? 2 : 4,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: status,
                    ),
                  ),
                  if (showChildren)
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.center,
                        child: childrenColumn,
                      ),
                    ),
                  if (showUpdated)
                    Expanded(
                      flex: 3,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: updated,
                      ),
                    ),
                ],
              ),
            )
          else
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: status,
              ),
            ),
          SizedBox(width: actionsWidth, child: actions),
        ],
      ),
    );
  }
}

class SubcategoryRow extends StatelessWidget {
  const SubcategoryRow({
    super.key,
    required this.subcategory,
    required this.parentName,
    required this.childrenCount,
    required this.highlighted,
    required this.selected,
    required this.onFormRequest,
    required this.onDeleteRequest,
    this.showParentColumn = true,
  });

  final CategoryEntity subcategory;
  final String parentName;
  final int childrenCount;
  final bool highlighted;
  final bool selected;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final bool showParentColumn;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = CategoriesPanelMetrics(constraints.maxWidth);
        if (metrics.useSubcategoryCards) {
          return _SubcategoryCard(
            subcategory: subcategory,
            parentName: parentName,
            childrenCount: childrenCount,
            highlighted: highlighted,
            selected: selected,
            metrics: metrics,
            onFormRequest: onFormRequest,
            onDeleteRequest: onDeleteRequest,
          );
        }

        return _SubcategoryTableRow(
          subcategory: subcategory,
          parentName: parentName,
          childrenCount: childrenCount,
          highlighted: highlighted,
          selected: selected,
          metrics: metrics,
          showParentColumn: showParentColumn,
          onFormRequest: onFormRequest,
          onDeleteRequest: onDeleteRequest,
        );
      },
    );
  }
}

class _SubcategoryTableRow extends StatelessWidget {
  const _SubcategoryTableRow({
    required this.subcategory,
    required this.parentName,
    required this.childrenCount,
    required this.highlighted,
    required this.selected,
    required this.metrics,
    required this.showParentColumn,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity subcategory;
  final String parentName;
  final int childrenCount;
  final bool highlighted;
  final bool selected;
  final CategoriesPanelMetrics metrics;
  final bool showParentColumn;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent =
        categoryAccentColor(subcategory.slug, subcategory.name);
    final compact = metrics.isCompact;

    return Material(
      color: highlighted
          ? accent.withValues(alpha: 0.1)
          : selected
              ? scheme.primaryContainer.withValues(alpha: 0.2)
              : Colors.transparent,
      child: InkWell(
        onTap: () => bloc.add(
          ToggleCategorySelectionEvent(subcategory.id),
        ),
        child: _SubcategoryTableLayout(
          metrics: metrics,
          showParentColumn: showParentColumn,
          checkboxSlot: Checkbox(
            value: selected,
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            onChanged: (_) => bloc.add(
              ToggleCategorySelectionEvent(subcategory.id),
            ),
          ),
          iconSlot: CategoryIcon(
            category: subcategory,
            size: compact ? 22 : 24,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: accent.withValues(alpha: 0.12),
            iconColor: accent,
          ),
          name: _HighlightText(
            text: subcategory.name,
            highlighted: highlighted,
            style: TextStyle(
              fontSize: compact ? 12.5 : 13,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          parent: Text(
            parentName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          status: CategoryStatusBadge(isActive: subcategory.isActive),
          childrenColumn: Text(
            '$childrenCount',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: scheme.onSurfaceVariant,
            ),
          ),
          updated: Text(
            formatCategoryDate(subcategory.updatedAt),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: scheme.onSurfaceVariant,
            ),
          ),
          actions: _SubcategoryActions(
            subcategory: subcategory,
            compact: compact || metrics.isNarrow,
            onFormRequest: onFormRequest,
            onDeleteRequest: onDeleteRequest,
          ),
        ),
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  const _SubcategoryCard({
    required this.subcategory,
    required this.parentName,
    required this.childrenCount,
    required this.highlighted,
    required this.selected,
    required this.metrics,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity subcategory;
  final String parentName;
  final int childrenCount;
  final bool highlighted;
  final bool selected;
  final CategoriesPanelMetrics metrics;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent =
        categoryAccentColor(subcategory.slug, subcategory.name);
    final hPad = metrics.listHorizontalPadding;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, metrics.tileSpacing),
      child: Material(
        color: highlighted
            ? accent.withValues(alpha: 0.1)
            : selected
                ? scheme.primaryContainer.withValues(alpha: 0.18)
                : scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => bloc.add(
            ToggleCategorySelectionEvent(subcategory.id),
          ),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant),
            ),
            padding: EdgeInsets.all(metrics.isNarrow ? 8 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: selected,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: (_) => bloc.add(
                        ToggleCategorySelectionEvent(subcategory.id),
                      ),
                    ),
                    CategoryIcon(
                      category: subcategory,
                      size: 28,
                      borderRadius: BorderRadius.circular(8),
                      backgroundColor: accent.withValues(alpha: 0.12),
                      iconColor: accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _HighlightText(
                            text: subcategory.name,
                            highlighted: highlighted,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              CategoryStatusBadge(
                                isActive: subcategory.isActive,
                              ),
                              Text(
                                formatCategoryDate(subcategory.updatedAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _SubcategoryActions(
                      subcategory: subcategory,
                      compact: true,
                      onFormRequest: onFormRequest,
                      onDeleteRequest: onDeleteRequest,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SubcategoryActions extends StatelessWidget {
  const _SubcategoryActions({
    required this.subcategory,
    required this.compact,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity subcategory;
  final bool compact;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    if (compact) {
      return PopupMenuButton<String>(
        tooltip: l10n.tOr('moreActions', 'More'),
        icon: const Icon(Icons.more_vert_rounded, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        itemBuilder: (context) => [
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
              onFormRequest(editing: subcategory);
            case 'delete':
              onDeleteRequest(subcategory);
          }
        },
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 18),
          tooltip: l10n.t('edit'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => onFormRequest(editing: subcategory),
        ),
        IconButton(
          icon: Icon(Icons.delete_outline_rounded,
              size: 18, color: scheme.error),
          tooltip: l10n.t('delete'),
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          onPressed: () => onDeleteRequest(subcategory),
        ),
      ],
    );
  }
}

class SubcategoryTableHeader extends StatelessWidget {
  const SubcategoryTableHeader({
    super.key,
    this.showParentColumn = true,
    this.trailing,
  });

  final bool showParentColumn;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = CategoriesPanelMetrics(constraints.maxWidth);
        if (!metrics.showSubcategoryTableHeader) {
          return const SizedBox.shrink();
        }

        final headerStyle = TextStyle(
          fontSize: metrics.isCompact ? 10.5 : 11,
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
          letterSpacing: 0.3,
        );

        return Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerLow,
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: _SubcategoryTableLayout(
            metrics: metrics,
            showParentColumn: showParentColumn,
            checkboxSlot: const SizedBox.shrink(),
            iconSlot: const SizedBox.shrink(),
            name: Text(l10n.t('categoryName'), style: headerStyle),
            parent: Text(l10n.tOr('parent', 'Parent'), style: headerStyle),
            status: Text(l10n.t('categoryFilterStatus'), style: headerStyle),
            childrenColumn:
                Text(l10n.tOr('children', 'Children'), style: headerStyle),
            updated: Text(l10n.tOr('updated', 'Updated'), style: headerStyle),
            actions: trailing ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}

class _HighlightText extends StatelessWidget {
  const _HighlightText({
    required this.text,
    required this.highlighted,
    required this.style,
  });

  final String text;
  final bool highlighted;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    if (!highlighted) {
      return Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: style,
      );
    }
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: style.copyWith(
        color: Theme.of(context).colorScheme.primary,
        decoration: TextDecoration.underline,
        decorationColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
