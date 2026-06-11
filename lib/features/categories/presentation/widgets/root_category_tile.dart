import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import 'category_callbacks.dart';
import 'category_icon.dart';
import 'category_ui_primitives.dart';
import 'subcategory_row.dart';

class RootCategoryTile extends StatelessWidget {
  const RootCategoryTile({
    super.key,
    required this.category,
    required this.subcategoryCount,
    required this.isExpanded,
    required this.isSelected,
    required this.hideSubcategories,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoryEntity category;
  final int subcategoryCount;
  final bool isExpanded;
  final bool isSelected;
  final bool hideSubcategories;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoriesBloc, CategoriesState, _RootTileData>(
      selector: (state) {
        if (state is! CategoriesLoaded) {
          return const _RootTileData.empty();
        }
        final subs = hideSubcategories
            ? const <CategoryEntity>[]
            : (isExpanded
                ? state.subcategoriesFor(category.id, root: category)
                : const <CategoryEntity>[]);
        return _RootTileData(
          highlightedIds: state.highlightedIds,
          selectedIds: state.selectedCategoryIds,
          subcategories: subs,
          isSubmitting: state.isSubmitting,
        );
      },
      builder: (context, data) {
        return _RootCategoryTileBody(
          category: category,
          subcategoryCount: subcategoryCount,
          isExpanded: isExpanded,
          isSelected: isSelected,
          hideSubcategories: hideSubcategories,
          onFormRequest: onFormRequest,
          onDeleteRequest: onDeleteRequest,
          tileData: data,
        );
      },
    );
  }
}

class _RootTileData {
  const _RootTileData({
    required this.highlightedIds,
    required this.selectedIds,
    required this.subcategories,
    required this.isSubmitting,
  });

  const _RootTileData.empty()
      : highlightedIds = const {},
        selectedIds = const {},
        subcategories = const [],
        isSubmitting = false;

  final Set<String> highlightedIds;
  final Set<String> selectedIds;
  final List<CategoryEntity> subcategories;
  final bool isSubmitting;
}

class _RootCategoryTileBody extends StatelessWidget {
  const _RootCategoryTileBody({
    required this.category,
    required this.subcategoryCount,
    required this.isExpanded,
    required this.isSelected,
    required this.hideSubcategories,
    required this.onFormRequest,
    required this.onDeleteRequest,
    required this.tileData,
  });

  final CategoryEntity category;
  final int subcategoryCount;
  final bool isExpanded;
  final bool isSelected;
  final bool hideSubcategories;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final _RootTileData tileData;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();
    final accent = categoryAccentColor(category.slug, category.name);
    final hasSubs = !hideSubcategories && subcategoryCount > 0;
    final depthLabel = hasSubs ? '2 ${l10n.tOr('levels', 'levels')}' : '1';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: hasSubs
                  ? () => bloc.add(ToggleCategoryExpandEvent(category.id))
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                child: Row(
                  children: [
                    Checkbox(
                      value: isSelected,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      onChanged: tileData.isSubmitting
                          ? null
                          : (_) => bloc.add(
                                ToggleCategorySelectionEvent(category.id),
                              ),
                    ),
                    if (hasSubs)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_down_rounded
                            : Icons.keyboard_arrow_right_rounded,
                        size: 20,
                        color: accent,
                      )
                    else
                      const SizedBox(width: 20),
                    const SizedBox(width: 6),
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
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: tileData.highlightedIds
                                          .contains(category.id)
                                      ? scheme.primary
                                      : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _InsightChip(
                                icon: Icons.account_tree_outlined,
                                label:
                                    '${formatCategoryCount(subcategoryCount)} ${l10n.tOr('subcategoriesShort', 'subs')}',
                                color: accent,
                              ),
                              _InsightChip(
                                icon: Icons.layers_outlined,
                                label: depthLabel,
                              ),
                              CategoryStatusBadge(isActive: category.isActive),
                              _InsightChip(
                                icon: Icons.calendar_today_outlined,
                                label: formatCategoryDate(category.createdAt),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: isExpanded
                          ? l10n.t('hideSubcategories')
                          : l10n.tOr('expand', 'Expand'),
                      icon: Icon(
                        isExpanded
                            ? Icons.unfold_less_rounded
                            : Icons.unfold_more_rounded,
                        size: 18,
                      ),
                      visualDensity: VisualDensity.compact,
                      onPressed: hasSubs
                          ? () => bloc.add(
                                ToggleCategoryExpandEvent(category.id),
                              )
                          : null,
                    ),
                    IconButton(
                      tooltip: l10n.t('edit'),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      visualDensity: VisualDensity.compact,
                      onPressed: tileData.isSubmitting
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
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: isExpanded && hasSubs
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Divider(height: 1, color: scheme.outlineVariant),
                      const SubcategoryTableHeader(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: tileData.subcategories.length,
                        itemBuilder: (context, index) {
                          final sub = tileData.subcategories[index];
                          return SubcategoryRow(
                            subcategory: sub,
                            parentName: category.name,
                            childrenCount: 0,
                            highlighted: tileData.highlightedIds
                                .contains(sub.id),
                            selected: tileData.selectedIds.contains(sub.id),
                            onFormRequest: onFormRequest,
                            onDeleteRequest: onDeleteRequest,
                          );
                        },
                      ),
                      Material(
                        color: scheme.surfaceContainerLow,
                        child: InkWell(
                          onTap: tileData.isSubmitting
                              ? null
                              : () =>
                                  onFormRequest(parentForNew: category),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded,
                                    size: 16, color: accent),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.t('addSubcategory'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({
    required this.icon,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = color ?? scheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: c),
          const SizedBox(width: 4),
          Text(
            label,
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
