import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';

/// Compact sort control for the categories toolbar.
class CategoriesSortDropdown extends StatelessWidget {
  const CategoriesSortDropdown({super.key, required this.height});

  final double height;

  static const defaultSort = CategorySortOption.name;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<CategoriesBloc, CategoriesState, CategorySortOption>(
      selector: (state) => switch (state) {
        CategoriesLoaded(:final sortOption) => sortOption,
        _ => context.read<CategoriesBloc>().activeSortOption,
      },
      builder: (context, sort) {
        final isActive = sort != defaultSort;
        final fg = isActive ? scheme.primary : scheme.onSurfaceVariant;
        final bg = isActive
            ? scheme.primary.withValues(alpha: 0.08)
            : Colors.transparent;
        final border = isActive
            ? scheme.primary.withValues(alpha: 0.35)
            : scheme.outline.withValues(alpha: 0.22);

        return Tooltip(
          message: l10n.t('sortBy'),
          child: Material(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            child: PopupMenuButton<CategorySortOption>(
              tooltip: l10n.t('sortBy'),
              offset: Offset(0, height + 4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              onSelected: (value) {
                final bloc = context.read<CategoriesBloc>();
                if (bloc.activeSortOption == value) return;
                bloc.add(UpdateCategorySortEvent(value));
              },
              itemBuilder: (context) => [
                _sortItem(
                  context,
                  sort: sort,
                  value: CategorySortOption.name,
                  label: l10n.t('categorySortName'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: CategorySortOption.mostSubcategories,
                  label: l10n.tOr('sortMostSubcategories', 'Most subcategories'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: CategorySortOption.recentlyCreated,
                  label: l10n.tOr('sortRecentlyCreated', 'Recently created'),
                ),
                _sortItem(
                  context,
                  sort: sort,
                  value: CategorySortOption.recentlyUpdated,
                  label: l10n.tOr('sortRecentlyUpdated', 'Recently updated'),
                ),
              ],
              child: Container(
                height: height,
                width: height,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.swap_vert_rounded, size: 18, color: fg),
              ),
            ),
          ),
        );
      },
    );
  }

  PopupMenuItem<CategorySortOption> _sortItem(
    BuildContext context, {
    required CategorySortOption sort,
    required CategorySortOption value,
    required String label,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final selected = sort == value;
    return PopupMenuItem<CategorySortOption>(
      value: value,
      height: 36,
      child: Text(
        label,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          color: selected ? scheme.primary : null,
        ),
      ),
    );
  }
}

String categorySortLabel(AppLocalizations l10n, CategorySortOption sort) {
  return switch (sort) {
    CategorySortOption.name => l10n.t('categorySortName'),
    CategorySortOption.mostSubcategories =>
      l10n.tOr('sortMostSubcategories', 'Most subcategories'),
    CategorySortOption.recentlyCreated =>
      l10n.tOr('sortRecentlyCreated', 'Recently created'),
    CategorySortOption.recentlyUpdated =>
      l10n.tOr('sortRecentlyUpdated', 'Recently updated'),
  };
}
