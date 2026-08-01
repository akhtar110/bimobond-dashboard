import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';
import 'category_callbacks.dart';
import 'category_icon.dart';
import 'category_ui_primitives.dart';
import 'subcategory_row.dart';

/// Detail (right) panel — lazy list of subcategories for the focused root.
class CategoryChildrenPanel extends StatefulWidget {
  const CategoryChildrenPanel({
    super.key,
    required this.root,
    required this.onFormRequest,
    required this.onDeleteRequest,
    this.showBackButton = false,
    this.onBack,
  });

  final CategoryEntity root;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final bool showBackButton;
  final VoidCallback? onBack;

  @override
  State<CategoryChildrenPanel> createState() => _CategoryChildrenPanelState();
}

class _CategoryChildrenPanelState extends State<CategoryChildrenPanel> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<CategoriesBloc, CategoriesState, _ChildrenPanelData>(
      selector: (state) {
        if (state is! CategoriesLoaded) {
          return const _ChildrenPanelData.empty();
        }
        final children = state.displayChildrenFor(widget.root.id);
        return _ChildrenPanelData(
          children: children,
          totalCount: state.subcategoryCountFor(widget.root.id),
          highlightedIds: state.highlightedIds,
          selectedIds: state.selectedCategoryIds,
          isSubmitting: state.isSubmitting,
          searchQuery: state.searchQuery,
        );
      },
      builder: (context, data) {
        final scheme = Theme.of(context).colorScheme;
        final accent =
            categoryAccentColor(widget.root.slug, widget.root.name);

        return ColoredBox(
          color: scheme.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ChildrenPanelHeader(
                root: widget.root,
                totalCount: data.totalCount,
                shownCount: data.children.length,
                searchQuery: data.searchQuery,
                showBackButton: widget.showBackButton,
                onBack: widget.onBack,
                accent: accent,
                isSubmitting: data.isSubmitting,
                onAddSubcategory: () => widget.onFormRequest(
                  parentForNew: widget.root,
                ),
              ),
              Divider(height: 1, color: scheme.outlineVariant),
              Expanded(
                child: data.children.isEmpty
                    ? _EmptyChildrenState(
                        rootName: widget.root.name,
                        hasSearch: data.searchQuery.trim().isNotEmpty,
                        hasAnyChildren: data.totalCount > 0,
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final panelMetrics =
                              CategoriesPanelMetrics(constraints.maxWidth);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const SubcategoryTableHeader(
                                showParentColumn: false,
                              ),
                              Expanded(
                                child: ListView.builder(
                                  controller: _scrollController,
                                  padding: EdgeInsets.only(
                                    top: panelMetrics.useSubcategoryCards
                                        ? 6
                                        : 0,
                                    bottom: panelMetrics.listHorizontalPadding,
                                  ),
                                  itemCount: data.children.length,
                                  itemBuilder: (context, index) {
                                    final sub = data.children[index];
                                    return RepaintBoundary(
                                      key: ValueKey(sub.id),
                                      child: SubcategoryRow(
                                        subcategory: sub,
                                        parentName: widget.root.name,
                                        childrenCount: 0,
                                        highlighted: data.highlightedIds
                                            .contains(sub.id),
                                        selected: data.selectedIds
                                            .contains(sub.id),
                                        showParentColumn: false,
                                        onFormRequest: widget.onFormRequest,
                                        onDeleteRequest:
                                            widget.onDeleteRequest,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChildrenPanelData {
  const _ChildrenPanelData({
    required this.children,
    required this.totalCount,
    required this.highlightedIds,
    required this.selectedIds,
    required this.isSubmitting,
    required this.searchQuery,
  });

  const _ChildrenPanelData.empty()
      : children = const [],
        totalCount = 0,
        highlightedIds = const {},
        selectedIds = const {},
        isSubmitting = false,
        searchQuery = '';

  final List<CategoryEntity> children;
  final int totalCount;
  final Set<String> highlightedIds;
  final Set<String> selectedIds;
  final bool isSubmitting;
  final String searchQuery;
}

class _ChildrenPanelHeader extends StatelessWidget {
  const _ChildrenPanelHeader({
    required this.root,
    required this.totalCount,
    required this.shownCount,
    required this.searchQuery,
    required this.showBackButton,
    required this.accent,
    required this.isSubmitting,
    required this.onAddSubcategory,
    this.onBack,
  });

  final CategoryEntity root;
  final int totalCount;
  final int shownCount;
  final String searchQuery;
  final bool showBackButton;
  final Color accent;
  final bool isSubmitting;
  final VoidCallback onAddSubcategory;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final hasSearch = searchQuery.trim().isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final panelWidth = constraints.maxWidth;
        final narrow = panelWidth < 520;
        final ultraNarrow = panelWidth < 320;

        return Padding(
          padding: EdgeInsets.fromLTRB(
            narrow ? 8 : 12,
            narrow ? 8 : 12,
            narrow ? 8 : 12,
            narrow ? 8 : 10,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showBackButton) ...[
                IconButton(
                  tooltip: l10n.tOr('back', 'Back'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  visualDensity: VisualDensity.compact,
                  onPressed: onBack,
                ),
                SizedBox(width: ultraNarrow ? 0 : 4),
              ],
              CategoryIcon(
                category: root,
                size: ultraNarrow ? 30 : (narrow ? 34 : 40),
                borderRadius: BorderRadius.circular(10),
                backgroundColor: accent.withValues(alpha: 0.12),
                iconColor: accent,
              ),
              SizedBox(width: ultraNarrow ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      root.name,
                      maxLines: ultraNarrow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: ultraNarrow ? 14 : (narrow ? 15 : null),
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasSearch
                          ? l10n.tOr(
                              'showingChildResultsCount',
                              'Showing $shownCount of $totalCount subcategories',
                            )
                          : l10n.tOr(
                              'subcategoriesCount',
                              '${formatCategoryCount(totalCount)} subcategories',
                            ),
                      maxLines: ultraNarrow ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: ultraNarrow ? 11 : null,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (narrow || ultraNarrow)
                Tooltip(
                  message: l10n.t('addSubcategory'),
                  child: IconButton(
                    icon: Icon(Icons.add_rounded, color: accent),
                    visualDensity: VisualDensity.compact,
                    onPressed: isSubmitting ? null : onAddSubcategory,
                  ),
                )
              else
                _AddSubcategoryButton(
                  accent: accent,
                  enabled: !isSubmitting,
                  onPressed: onAddSubcategory,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AddSubcategoryButton extends StatelessWidget {
  const _AddSubcategoryButton({
    required this.accent,
    required this.enabled,
    required this.onPressed,
  });

  final Color accent;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return FilledButton.tonalIcon(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        backgroundColor: accent.withValues(alpha: 0.12),
        foregroundColor: accent,
      ),
      icon: const Icon(Icons.add_rounded, size: 16),
      label: Text(
        l10n.t('addSubcategory'),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _EmptyChildrenState extends StatelessWidget {
  const _EmptyChildrenState({
    required this.rootName,
    required this.hasSearch,
    required this.hasAnyChildren,
  });

  final String rootName;
  final bool hasSearch;
  final bool hasAnyChildren;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isSearchMiss = hasSearch && hasAnyChildren;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearchMiss ? Icons.search_off : Icons.folder_open_outlined,
              size: 48,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 12),
            Text(
              isSearchMiss
                  ? l10n.tOr('noCategoriesFound', 'No categories found')
                  : l10n.tOr(
                      'noSubcategoriesYet',
                      'This category has no subcategories yet',
                    ),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              isSearchMiss
                  ? l10n.tOr('tryDifferentSearch', 'Try a different search term')
                  : rootName,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryChildrenPlaceholder extends StatelessWidget {
  const CategoryChildrenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_outlined,
                size: 48,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 12),
              Text(
                l10n.tOr(
                  'selectRootCategory',
                  'Select a root category to view subcategories',
                ),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
