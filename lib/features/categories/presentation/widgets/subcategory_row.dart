import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import 'category_callbacks.dart';
import 'category_icon.dart';
import 'category_ui_primitives.dart';

/// Shared column layout for subcategory header + rows (keeps alignment responsive).
class _SubcategoryTableLayout extends StatelessWidget {
  const _SubcategoryTableLayout({
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

  final Widget checkboxSlot;
  final Widget iconSlot;
  final Widget name;
  final Widget parent;
  final Widget status;
  final Widget childrenColumn;
  final Widget updated;
  final Widget actions;
  final bool showParentColumn;

  static const _checkboxWidth = 40.0;
  static const _iconWidth = 34.0;
  static const _actionsWidth = 80.0;
  static const _horizontalPadding = 12.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final showParent = showParentColumn && width >= 640;
        final showChildren = width >= 520;
        final showUpdated = width >= 420;
        final compactMeta = width < 640;
        final actionsWidth = width < 360 ? 64.0 : _actionsWidth;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: width < 360 ? 8 : _horizontalPadding,
            vertical: 6,
          ),
          child: Row(
            children: [
              SizedBox(width: _checkboxWidth, child: checkboxSlot),
              SizedBox(width: _iconWidth, child: iconSlot),
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
      },
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
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent =
        categoryAccentColor(subcategory.slug, subcategory.name);

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
            size: 24,
            borderRadius: BorderRadius.circular(6),
            backgroundColor: accent.withValues(alpha: 0.12),
            iconColor: accent,
          ),
          name: _HighlightText(
            text: subcategory.name,
            highlighted: highlighted,
            style: TextStyle(
              fontSize: 13,
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
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: l10n.t('edit'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () => onFormRequest(editing: subcategory),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    size: 18, color: scheme.error),
                tooltip: l10n.t('delete'),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
                onPressed: () => onDeleteRequest(subcategory),
              ),
            ],
          ),
        ),
      ),
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

    final headerStyle = TextStyle(
      fontSize: 11,
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
        showParentColumn: showParentColumn,
        checkboxSlot: const SizedBox.shrink(),
        iconSlot: const SizedBox.shrink(),
        name: Text(l10n.t('categoryName'), style: headerStyle),
        parent: Text(l10n.tOr('parent', 'Parent'), style: headerStyle),
        status: Text(l10n.t('categoryFilterStatus'), style: headerStyle),
        childrenColumn: Text(l10n.tOr('children', 'Children'), style: headerStyle),
        updated: Text(l10n.tOr('updated', 'Updated'), style: headerStyle),
        actions: trailing ?? const SizedBox.shrink(),
      ),
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
