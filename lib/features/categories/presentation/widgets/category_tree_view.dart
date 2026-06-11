import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/categories_bloc.dart';
import 'category_bulk_actions_bar.dart';
import 'category_callbacks.dart';
import 'category_filters_bar.dart';
import 'category_search_bar.dart';
import 'root_category_tile.dart';

class CategoryTreeView extends StatefulWidget {
  const CategoryTreeView({
    super.key,
    required this.state,
    required this.onFormRequest,
    required this.onDeleteRequest,
  });

  final CategoriesLoaded state;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;

  @override
  State<CategoryTreeView> createState() => _CategoryTreeViewState();
}

class _CategoryTreeViewState extends State<CategoryTreeView> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final roots = widget.state.displayRoots;
    final hideSubs =
        widget.state.typeFilter == CategoryTypeFilter.rootOnly;

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CategorySearchBar(initialQuery: widget.state.searchQuery),
                const SizedBox(height: 10),
                CategoryFiltersBar(state: widget.state),
                const SizedBox(height: 6),
                Text(
                  _categoryResultsLabel(l10n, widget.state),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: scheme.outlineVariant),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 72),
              itemCount: roots.length,
              itemBuilder: (context, index) {
                final root = roots[index];
                return RootCategoryTile(
                  category: root,
                  subcategoryCount: widget.state.subcategoryCountFor(root.id),
                  isExpanded: widget.state.isCategoryExpanded(root.id),
                  isSelected: widget.state.isCategorySelected(root.id),
                  hideSubcategories: hideSubs,
                  onFormRequest: widget.onFormRequest,
                  onDeleteRequest: widget.onDeleteRequest,
                );
              },
            ),
          ),
          CategoryBulkActionsBar(roots: widget.state.catalogRoots),
        ],
      ),
    );
  }
}

String _categoryResultsLabel(AppLocalizations l10n, CategoriesLoaded state) {
  final template =
      l10n.tOr('showingResultsCount', 'Showing {shown} of {total}');
  final total = state.typeFilter == CategoryTypeFilter.subOnly
      ? state.catalogCategories.where((c) => !c.isRoot).length
      : state.typeFilter == CategoryTypeFilter.rootOnly
          ? state.catalogRoots.length
          : state.catalogCategories.length;
  return template
      .replaceAll('{shown}', '${state.displayRoots.length}')
      .replaceAll('{total}', '$total');
}
