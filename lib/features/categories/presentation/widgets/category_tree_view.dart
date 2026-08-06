import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/category_entity.dart';
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';
import 'category_bulk_actions_bar.dart';
import 'category_callbacks.dart';
import 'category_children_panel.dart';
import 'root_category_tile.dart';

class CategoryTreeView extends StatefulWidget {
  const CategoryTreeView({
    super.key,
    required this.state,
    required this.onFormRequest,
    required this.onDeleteRequest,
    this.onToggleStatusRequest,
  });

  final CategoriesLoaded state;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final CategoryToggleStatusCallback? onToggleStatusRequest;

  @override
  State<CategoryTreeView> createState() => _CategoryTreeViewState();
}

class _CategoryTreeViewState extends State<CategoryTreeView> {
  final _rootsScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _rootsScrollController.addListener(_onRootsScroll);
  }

  @override
  void dispose() {
    _rootsScrollController.removeListener(_onRootsScroll);
    _rootsScrollController.dispose();
    super.dispose();
  }

  void _onRootsScroll() {
    if (!mounted || !_rootsScrollController.hasClients) return;

    final metrics = categoriesMetricsOf(context);
    if (!metrics.useInfiniteScroll) return;

    final position = _rootsScrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 240) {
      context.read<CategoriesBloc>().add(LoadMoreCategoriesEvent());
    }
  }

  void _maybeFillViewport() {
    if (!mounted || !_rootsScrollController.hasClients) return;
    final metrics = categoriesMetricsOf(context);
    if (!metrics.useInfiniteScroll) return;

    final state = context.read<CategoriesBloc>().state;
    if (state is! CategoriesLoaded || state.hasReachedMaxRoots) return;

    final position = _rootsScrollController.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent <= 0) {
      context.read<CategoriesBloc>().add(LoadMoreCategoriesEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final metrics = categoriesMetricsOf(context);

    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFillViewport());

    return ColoredBox(
      color: scheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final useSplitView = metrics.useMasterDetailSplit(width);

                if (useSplitView) {
                  return _SplitMasterDetailView(
                    state: widget.state,
                    rootsScrollController: _rootsScrollController,
                    onFormRequest: widget.onFormRequest,
                    onDeleteRequest: widget.onDeleteRequest,
                    onToggleStatusRequest: widget.onToggleStatusRequest,
                    useInfiniteScroll: metrics.useInfiniteScroll,
                    layoutMetrics: metrics,
                    totalWidth: width,
                  );
                }
                return _MobileMasterDetailView(
                  state: widget.state,
                  rootsScrollController: _rootsScrollController,
                  onFormRequest: widget.onFormRequest,
                  onDeleteRequest: widget.onDeleteRequest,
                  onToggleStatusRequest: widget.onToggleStatusRequest,
                  useInfiniteScroll: metrics.useInfiniteScroll,
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

class _SplitMasterDetailView extends StatelessWidget {
  const _SplitMasterDetailView({
    required this.state,
    required this.rootsScrollController,
    required this.onFormRequest,
    required this.onDeleteRequest,
    this.onToggleStatusRequest,
    required this.useInfiniteScroll,
    required this.layoutMetrics,
    required this.totalWidth,
  });

  final CategoriesLoaded state;
  final ScrollController rootsScrollController;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final CategoryToggleStatusCallback? onToggleStatusRequest;
  final bool useInfiniteScroll;
  final CategoriesLayoutMetrics layoutMetrics;
  final double totalWidth;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hideSubs = state.typeFilter == CategoryTypeFilter.rootOnly;
    final masterFlex = layoutMetrics.masterDetailMasterFlex(totalWidth);
    final detailFlex = layoutMetrics.masterDetailDetailFlex(totalWidth);
    final maxMasterWidth = layoutMetrics.masterPanelWidth(totalWidth);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: masterFlex,
          fit: FlexFit.tight,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 168,
              maxWidth: maxMasterWidth,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerLowest,
                border: Border(
                  right: BorderSide(color: scheme.outlineVariant),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _RootCategoriesPanel(
                    scrollController: rootsScrollController,
                    hideSubcategories: hideSubs,
                    panelMetrics: CategoriesPanelMetrics(constraints.maxWidth),
                    onFormRequest: onFormRequest,
                    onDeleteRequest: onDeleteRequest,
                    onToggleStatusRequest: onToggleStatusRequest,
                    useInfiniteScroll: useInfiniteScroll,
                  );
                },
              ),
            ),
          ),
        ),
        Expanded(
          flex: detailFlex,
          child: hideSubs
              ? const CategoryChildrenPlaceholder()
              : BlocSelector<CategoriesBloc, CategoriesState, CategoryEntity?>(
                  selector: (state) =>
                      state is CategoriesLoaded ? state.focusedRoot : null,
                  builder: (context, focusedRoot) {
                    if (focusedRoot == null) {
                      return const CategoryChildrenPlaceholder();
                    }
                    return CategoryChildrenPanel(
                      key: ValueKey(focusedRoot.id),
                      root: focusedRoot,
                      onFormRequest: onFormRequest,
                      onDeleteRequest: onDeleteRequest,
                      onToggleStatusRequest: onToggleStatusRequest,
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _MobileMasterDetailView extends StatelessWidget {
  const _MobileMasterDetailView({
    required this.state,
    required this.rootsScrollController,
    required this.onFormRequest,
    required this.onDeleteRequest,
    this.onToggleStatusRequest,
    required this.useInfiniteScroll,
  });

  final CategoriesLoaded state;
  final ScrollController rootsScrollController;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final CategoryToggleStatusCallback? onToggleStatusRequest;
  final bool useInfiniteScroll;

  @override
  Widget build(BuildContext context) {
    final hideSubs = state.typeFilter == CategoryTypeFilter.rootOnly;

    return BlocSelector<CategoriesBloc, CategoriesState, CategoryEntity?>(
      selector: (state) =>
          state is CategoriesLoaded ? state.focusedRoot : null,
      builder: (context, focusedRoot) {
        if (!hideSubs && focusedRoot != null) {
          return CategoryChildrenPanel(
            key: ValueKey(focusedRoot.id),
            root: focusedRoot,
            showBackButton: true,
            onBack: () => context
                .read<CategoriesBloc>()
                .add(ClearFocusedRootEvent()),
            onFormRequest: onFormRequest,
            onDeleteRequest: onDeleteRequest,
            onToggleStatusRequest: onToggleStatusRequest,
          );
        }

        return _RootCategoriesPanel(
          scrollController: rootsScrollController,
          hideSubcategories: hideSubs,
          panelMetrics: CategoriesPanelMetrics(
            MediaQuery.sizeOf(context).width,
          ),
          onFormRequest: onFormRequest,
          onDeleteRequest: onDeleteRequest,
          onToggleStatusRequest: onToggleStatusRequest,
          useInfiniteScroll: useInfiniteScroll,
        );
      },
    );
  }
}

class _RootCategoriesPanel extends StatelessWidget {
  const _RootCategoriesPanel({
    required this.scrollController,
    required this.hideSubcategories,
    required this.panelMetrics,
    required this.onFormRequest,
    required this.onDeleteRequest,
    this.onToggleStatusRequest,
    required this.useInfiniteScroll,
  });

  final ScrollController scrollController;
  final bool hideSubcategories;
  final CategoriesPanelMetrics panelMetrics;
  final CategoryFormCallback onFormRequest;
  final CategoryDeleteCallback onDeleteRequest;
  final CategoryToggleStatusCallback? onToggleStatusRequest;
  final bool useInfiniteScroll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocSelector<CategoriesBloc, CategoriesState, _RootsPanelData>(
      selector: (state) {
        if (state is! CategoriesLoaded) {
          return const _RootsPanelData.empty();
        }
        final roots = state.pagedLeftPanelRoots(
          infiniteScroll: useInfiniteScroll,
        );
        final counts = <String, int>{
          for (final root in roots)
            root.id: state.subcategoryCountFor(root.id),
        };
        return _RootsPanelData(
          roots: roots,
          subcategoryCounts: counts,
          focusedRootId: state.focusedRootId,
          selectedIds: state.selectedCategoryIds,
          hasReachedMax: state.hasReachedMaxRoots,
          totalRoots: state.rootsTotalCount,
        );
      },
      builder: (context, data) {
        if (data.roots.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tOr('noCategoriesFound', 'No categories found'),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.tOr('tryDifferentSearch', 'Try a different search term'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          );
        }

        final showEndLabel = useInfiniteScroll &&
            data.hasReachedMax &&
            data.totalRoots > CategoriesBloc.pageLimit;

        final hPad = panelMetrics.listHorizontalPadding;
        final titleSize = panelMetrics.rootTileCompact ? 11.5 : 12.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(hPad + 4, panelMetrics.listTopPadding, hPad + 4, 4),
              child: Text(
                l10n.tOr('rootCategories', 'Root categories'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: titleSize,
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: EdgeInsets.fromLTRB(hPad, 4, hPad, hPad),
                itemCount: data.roots.length + (showEndLabel ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= data.roots.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          l10n.tOr(
                            'allCategoriesLoaded',
                            'All categories loaded',
                          ),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    );
                  }
                  final root = data.roots[index];
                  return Padding(
                    padding: EdgeInsets.only(bottom: panelMetrics.tileSpacing),
                    child: RootCategoryTile(
                      key: ValueKey(root.id),
                      category: root,
                      subcategoryCount: data.subcategoryCounts[root.id] ?? 0,
                      isFocused: data.focusedRootId == root.id,
                      isSelected: data.selectedIds.contains(root.id),
                      panelMetrics: panelMetrics,
                      onFormRequest: onFormRequest,
                      onDeleteRequest: onDeleteRequest,
                      onToggleStatusRequest: onToggleStatusRequest,
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _RootsPanelData {
  const _RootsPanelData({
    required this.roots,
    required this.subcategoryCounts,
    required this.focusedRootId,
    required this.selectedIds,
    required this.hasReachedMax,
    required this.totalRoots,
  });

  const _RootsPanelData.empty()
      : roots = const [],
        subcategoryCounts = const {},
        focusedRootId = null,
        selectedIds = const {},
        hasReachedMax = true,
        totalRoots = 0;

  final List<CategoryEntity> roots;
  final Map<String, int> subcategoryCounts;
  final String? focusedRootId;
  final Set<String> selectedIds;
  final bool hasReachedMax;
  final int totalRoots;
}
