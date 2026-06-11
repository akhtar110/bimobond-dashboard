import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';

class CategoryFiltersBar extends StatelessWidget {
  const CategoryFiltersBar({super.key, required this.state});

  final CategoriesLoaded state;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoriesBloc>();

    final allCount = state.catalogRoots.length;
    final activeCount =
        state.catalogRoots.where((c) => c.isActive).length;
    final inactiveCount = allCount - activeCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipButton(
            label: l10n.t('filterAll'),
            count: allCount,
            selected: state.filter == CategoryFilter.all,
            onTap: () => bloc.add(ChangeCategoryFilterEvent(CategoryFilter.all)),
          ),
          const SizedBox(width: 6),
          _FilterChipButton(
            label: l10n.t('active'),
            count: activeCount,
            selected: state.filter == CategoryFilter.active,
            onTap: () =>
                bloc.add(ChangeCategoryFilterEvent(CategoryFilter.active)),
          ),
          const SizedBox(width: 6),
          _FilterChipButton(
            label: l10n.t('inactive'),
            count: inactiveCount,
            selected: state.filter == CategoryFilter.inactive,
            onTap: () =>
                bloc.add(ChangeCategoryFilterEvent(CategoryFilter.inactive)),
          ),
          const SizedBox(width: 8),
          _PopupFilterChip<CategoryTypeFilter>(
            icon: Icons.category_outlined,
            label: _typeLabel(l10n, state.typeFilter),
            onSelected: (v) => bloc.add(UpdateCategoryTypeFilterEvent(v)),
            items: [
              (CategoryTypeFilter.all, l10n.t('filterAll')),
              (CategoryTypeFilter.rootOnly, l10n.t('rootCategoriesOnly')),
              (CategoryTypeFilter.subOnly, l10n.t('subcategoriesOnly')),
            ],
          ),
          const SizedBox(width: 6),
          _PopupFilterChip<CategoryHasChildrenFilter>(
            icon: Icons.account_tree_outlined,
            label: _hasChildrenLabel(l10n, state.hasChildrenFilter),
            onSelected: (v) =>
                bloc.add(UpdateCategoryHasChildrenFilterEvent(v)),
            items: [
              (CategoryHasChildrenFilter.all, l10n.t('filterAll')),
              (
                CategoryHasChildrenFilter.yes,
                l10n.tOr('hasChildrenYes', 'Has children'),
              ),
              (
                CategoryHasChildrenFilter.no,
                l10n.tOr('hasChildrenNo', 'No children'),
              ),
            ],
          ),
          const SizedBox(width: 6),
          _PopupFilterChip<CategorySortOption>(
            icon: Icons.sort_rounded,
            label: _sortLabel(l10n, state.sortOption),
            onSelected: (v) => bloc.add(UpdateCategorySortEvent(v)),
            items: [
              (CategorySortOption.name, l10n.t('categorySortName')),
              (
                CategorySortOption.mostSubcategories,
                l10n.tOr('sortMostSubcategories', 'Most subcategories'),
              ),
              (
                CategorySortOption.recentlyCreated,
                l10n.tOr('sortRecentlyCreated', 'Recently created'),
              ),
              (
                CategorySortOption.recentlyUpdated,
                l10n.tOr('sortRecentlyUpdated', 'Recently updated'),
              ),
            ],
          ),
          if (state.isFetching) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: scheme.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _typeLabel(AppLocalizations l10n, CategoryTypeFilter f) =>
      switch (f) {
        CategoryTypeFilter.all => l10n.t('filterAll'),
        CategoryTypeFilter.rootOnly => l10n.t('rootCategoriesOnly'),
        CategoryTypeFilter.subOnly => l10n.t('subcategoriesOnly'),
      };

  String _hasChildrenLabel(
    AppLocalizations l10n,
    CategoryHasChildrenFilter f,
  ) =>
      switch (f) {
        CategoryHasChildrenFilter.all => l10n.tOr('hasChildren', 'Children'),
        CategoryHasChildrenFilter.yes =>
          l10n.tOr('hasChildrenYes', 'Has children'),
        CategoryHasChildrenFilter.no =>
          l10n.tOr('hasChildrenNo', 'No children'),
      };

  String _sortLabel(AppLocalizations l10n, CategorySortOption s) =>
      switch (s) {
        CategorySortOption.name => l10n.t('categorySortName'),
        CategorySortOption.mostSubcategories =>
          l10n.tOr('sortMostSubcategories', 'Most subcategories'),
        CategorySortOption.recentlyCreated =>
          l10n.tOr('sortRecentlyCreated', 'Recently created'),
        CategorySortOption.recentlyUpdated =>
          l10n.tOr('sortRecentlyUpdated', 'Recently updated'),
      };
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final primary = scheme.primary;

    return Material(
      color: selected ? primary : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? primary : scheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? scheme.onPrimary : scheme.onSurface,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: selected
                      ? scheme.onPrimary.withValues(alpha: 0.85)
                      : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PopupFilterChip<T> extends StatelessWidget {
  const _PopupFilterChip({
    required this.icon,
    required this.label,
    required this.onSelected,
    required this.items,
  });

  final IconData icon;
  final String label;
  final ValueChanged<T> onSelected;
  final List<(T, String)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<T>(
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final item in items)
          PopupMenuItem(value: item.$1, child: Text(item.$2)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded,
                size: 16, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
