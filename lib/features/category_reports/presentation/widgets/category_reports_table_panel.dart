import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/category_report_entities.dart';
import '../bloc/category_reports_bloc.dart';
import '../utils/category_report_format.dart';
import 'category_reports_pagination_bar.dart';

class CategoryReportsTablePanel extends StatelessWidget {
  const CategoryReportsTablePanel({
    super.key,
    required this.state,
    required this.searchController,
    this.onRowTap,
    this.hideSearchBar = false,
    this.denseLayout = false,
  });

  final CategoryReportsLoaded state;
  final TextEditingController searchController;
  final ValueChanged<String>? onRowTap;
  final bool hideSearchBar;
  final bool denseLayout;

  static const _sortOptions = [
    CategoryReportsSort.newest,
    CategoryReportsSort.oldest,
    CategoryReportsSort.mostViews,
    CategoryReportsSort.mostLikes,
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CategoryReportsFiltersBar(
          state: state,
          searchController: searchController,
          hideSearchBar: hideSearchBar,
          denseLayout: denseLayout,
        ),
        if (denseLayout && state.isListFetching)
          const LinearProgressIndicator(minHeight: 2),
        SizedBox(height: denseLayout ? 6 : 12),
        if (state.listError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              state.listError!,
              style: TextStyle(color: scheme.error, fontSize: 13),
            ),
          ),
        Expanded(
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  _Header(scheme: scheme),
                  Expanded(
                    child: state.items.isEmpty
                        ? Center(
                            child: Text(
                              context.l10n.t('noCategoriesFound'),
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: state.items.length,
                            separatorBuilder: (_, __) => Divider(
                              height: 1,
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            itemBuilder: (context, index) {
                              final item = state.items[index];
                              return _CategoryRow(
                                item: item,
                                onTap: onRowTap == null
                                    ? null
                                    : () => onRowTap!(item.id),
                              );
                            },
                          ),
                  ),
                  CategoryReportsPaginationBar(
                    currentPage: state.currentPage,
                    lastPage: state.lastPage,
                    total: state.total,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _CategoryReportsFiltersBar extends StatelessWidget {
  const _CategoryReportsFiltersBar({
    required this.state,
    required this.searchController,
    required this.hideSearchBar,
    required this.denseLayout,
  });

  final CategoryReportsLoaded state;
  final TextEditingController searchController;
  final bool hideSearchBar;
  final bool denseLayout;

  String _sortLabel(BuildContext context, CategoryReportsSort sort) {
    final l10n = context.l10n;
    return switch (sort) {
      CategoryReportsSort.newest => l10n.t('sortNewestFirst'),
      CategoryReportsSort.oldest => l10n.t('sortOldestFirst'),
      CategoryReportsSort.mostViews => l10n.t('sortMostViewed'),
      CategoryReportsSort.mostLikes => l10n.t('categorySortMostLikes'),
      _ => l10n.t('sortNewestFirst'),
    };
  }

  CategoryReportsSort get _selectedSort {
    if (CategoryReportsTablePanel._sortOptions.contains(state.sort)) {
      return state.sort;
    }
    return CategoryReportsSort.newest;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final bloc = context.read<CategoryReportsBloc>();
    final pad = denseLayout ? 0.0 : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 640;
        final itemWidth = narrow
            ? (constraints.maxWidth - pad - 8) / 2
            : 118.0;

        Widget dropdown({
          required Widget child,
          bool fullWidth = false,
        }) {
          if (fullWidth && narrow) {
            return SizedBox(width: constraints.maxWidth - pad, child: child);
          }
          return SizedBox(width: itemWidth, child: child);
        }

        return Padding(
          padding: EdgeInsets.fromLTRB(pad, denseLayout ? 0 : 0, pad, 0),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (!hideSearchBar)
                SizedBox(
                  width: narrow ? constraints.maxWidth - pad : 260,
                  height: 34,
                  child: TextField(
                    controller: searchController,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: l10n.t('searchCategories'),
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: scheme.outlineVariant),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: scheme.outlineVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    onChanged: (value) =>
                        bloc.add(UpdateCategoryReportsSearchEvent(value)),
                  ),
                ),
              dropdown(
                child: _CompactDropdown<bool?>(
                  value: state.isActiveFilter,
                  hint: l10n.t('categoryFilterStatus'),
                  items: [
                    (label: l10n.t('filterAll'), value: null),
                    (label: l10n.t('active'), value: true),
                    (label: l10n.t('inactive'), value: false),
                  ],
                  onChanged: (value) => bloc.add(
                    UpdateCategoryReportsActiveFilterEvent(value),
                  ),
                ),
              ),
              dropdown(
                child: _CompactDropdown<bool?>(
                  value: state.isMainFilter,
                  hint: l10n.t('categoryFilterLevel'),
                  items: [
                    (label: l10n.t('filterAll'), value: null),
                    (label: l10n.t('rootCategoriesOnly'), value: true),
                    (label: l10n.t('subcategoriesOnly'), value: false),
                  ],
                  onChanged: (value) => bloc.add(
                    UpdateCategoryReportsMainFilterEvent(value),
                  ),
                ),
              ),
              dropdown(
                child: _CompactDropdown<CategoryReportsSort>(
                  value: _selectedSort,
                  hint: l10n.t('sortBy'),
                  items: CategoryReportsTablePanel._sortOptions
                      .map(
                        (sort) => (
                          label: _sortLabel(context, sort),
                          value: sort,
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (sort) {
                    if (sort != null) {
                      bloc.add(UpdateCategoryReportsSortEvent(sort));
                    }
                  },
                ),
              ),
              if (state.isListFetching)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _CompactDropdown<T> extends StatelessWidget {
  const _CompactDropdown({
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String hint;
  final List<({String label, T? value})> items;
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 34,
      child: DropdownButtonFormField<T>(
        value: value,
        isDense: true,
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: scheme.outlineVariant),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: 0.7),
            ),
          ),
        ),
        style: TextStyle(fontSize: 12, color: scheme.onSurface),
        hint: Text(
          hint,
          style: const TextStyle(fontSize: 12),
          overflow: TextOverflow.ellipsis,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<T>(
                value: e.value,
                child: Text(
                  e.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            )
            .toList(growable: false),
        onChanged: onChanged,
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: scheme.onSurfaceVariant,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: scheme.surfaceContainerLow,
      child: Row(
        children: [
          const SizedBox(width: 44),
          Expanded(flex: 3, child: Text(l10n.t('categories'), style: style)),
          Expanded(child: Text(l10n.t('posts'), style: style)),
          Expanded(child: Text(l10n.t('views'), style: style)),
          Expanded(child: Text(l10n.t('columnType'), style: style)),
          Expanded(child: Text(l10n.t('status'), style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({required this.item, this.onTap});

  final CategoryReportListItemEntity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (onTap != null) {
            onTap!();
            return;
          }
          Navigator.of(context).pushNamed(
            AppRoutes.categoryReportDetail,
            arguments: item.id,
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: item.iconUrl != null && item.iconUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.iconUrl!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _iconFallback(scheme),
                      )
                    : _iconFallback(scheme),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      item.slug,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  formatCategoryReportCount(item.postMetrics.postCount),
                ),
              ),
              Expanded(
                child: Text(
                  formatCategoryReportCount(item.postMetrics.views),
                ),
              ),
              Expanded(
                child: Text(
                  item.isMain
                      ? l10n.t('categoryTypeMain')
                      : l10n.t('categoryTypeSub'),
                ),
              ),
              Expanded(
                child: Text(
                  item.isActive ? l10n.t('active') : l10n.t('inactive'),
                  style: TextStyle(
                    color: item.isActive ? Colors.green.shade700 : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconFallback(ColorScheme scheme) {
    return Container(
      width: 36,
      height: 36,
      color: scheme.primaryContainer,
      child: Icon(Icons.label_outline, size: 18, color: scheme.primary),
    );
  }
}
