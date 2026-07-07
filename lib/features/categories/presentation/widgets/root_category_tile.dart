import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
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
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity category;
  final int subcategoryCount;
  final bool isFocused;
  final bool isSelected;
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
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity category;
  final int subcategoryCount;
  final bool isFocused;
  final bool isSelected;
  final bool highlighted;
  final bool isSubmitting;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent = categoryAccentColor(category.slug, category.name);

    final backgroundColor = isFocused
        ? scheme.primaryContainer.withValues(alpha: 0.45)
        : scheme.surfaceContainerLowest;
    final borderColor = isFocused
        ? scheme.primary.withValues(alpha: 0.55)
        : scheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: backgroundColor,
        elevation: isFocused ? 1 : 0,
        shadowColor: scheme.shadow.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: isSubmitting
              ? null
              : () => bloc.add(FocusRootCategoryEvent(category.id)),
          hoverColor: scheme.primary.withValues(alpha: 0.06),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor, width: isFocused ? 1.5 : 1),
            ),
            padding: const EdgeInsets.fromLTRB(8, 10, 6, 10),
            child: Row(
              children: [
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
                  size: 36,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: accent.withValues(alpha: 0.12),
                  iconColor: accent,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: highlighted ? scheme.primary : null,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _CountBadge(
                            count: subcategoryCount,
                            label: l10n.tOr('subcategoriesShort', 'subs'),
                            color: accent,
                          ),
                          CategoryStatusBadge(isActive: category.isActive),
                        ],
                      ),
                    ],
                  ),
                ),
                if (subcategoryCount > 0)
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: isFocused ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                IconButton(
                  tooltip: l10n.t('edit'),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: isSubmitting
                      ? null
                      : () => onFormRequest(editing: category),
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.tOr('moreActions', 'More'),
                  icon: const Icon(Icons.more_vert_rounded, size: 18),
                  itemBuilder: (context) => [
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
                      case 'add_sub':
                        onFormRequest(parentForNew: category);
                      case 'delete':
                        onDeleteRequest(category);
                    }
                  },
                ),
              ],
            ),
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
  });

  final int count;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_tree_outlined, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            '${formatCategoryCount(count)} $label',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
