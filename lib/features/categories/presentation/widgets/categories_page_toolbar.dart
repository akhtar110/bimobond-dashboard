import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../posts/presentation/widgets/posts_filter_button.dart';
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';
import 'categories_filter_bar.dart';
import 'categories_filter_popup.dart';
import 'categories_sort_dropdown.dart';

/// Responsive categories toolbar — matches posts layout.
class CategoriesPageToolbar extends StatelessWidget {
  const CategoriesPageToolbar({super.key, required this.metrics});

  final CategoriesLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final controlHeight = metrics.filterControlHeight;
    final gap = metrics.filterGap + 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final inline = metrics.toolbarInlineAt(width);

        return _CategoriesToolbarRow(
          metrics: metrics,
          controlHeight: controlHeight,
          gap: gap,
          availableWidth: width,
          inline: inline,
        );
      },
    );
  }
}

class _CategoriesToolbarRow extends StatelessWidget {
  const _CategoriesToolbarRow({
    required this.metrics,
    required this.controlHeight,
    required this.gap,
    required this.availableWidth,
    required this.inline,
  });

  final CategoriesLayoutMetrics metrics;
  final double controlHeight;
  final double gap;
  final double availableWidth;
  final bool inline;

  Widget _searchField() {
    return CategoriesFilterBar(
      metrics: metrics,
      height: controlHeight,
    );
  }

  void _openFilters(
    BuildContext context, {
    required CategoryFilter statusFilter,
    required CategoryTypeFilter typeFilter,
    required CategoryHasChildrenFilter hasChildrenFilter,
  }) {
    final box = context.findRenderObject() as RenderBox?;
    final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
    final size = box?.size ?? Size.zero;
    showCategoriesFilterPopup(
      context: context,
      statusFilter: statusFilter,
      typeFilter: typeFilter,
      hasChildrenFilter: hasChildrenFilter,
      anchorRect: Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<
        CategoriesBloc,
        CategoriesState,
        ({
          CategoryFilter status,
          CategoryTypeFilter type,
          CategoryHasChildrenFilter hasChildren,
        })>(
      selector: (state) {
        final bloc = context.read<CategoriesBloc>();
        return (
          status: state is CategoriesLoaded
              ? state.filter
              : bloc.activeStatusFilter,
          type: state is CategoriesLoaded
              ? state.typeFilter
              : bloc.activeTypeFilter,
          hasChildren: state is CategoriesLoaded
              ? state.hasChildrenFilter
              : bloc.activeHasChildrenFilter,
        );
      },
      builder: (context, filters) {
        final activeCount = categoriesAppliedFilterCount(
          filter: filters.status,
          typeFilter: filters.type,
          hasChildrenFilter: filters.hasChildren,
        );

        final filterButton = Builder(
          builder: (buttonContext) {
            return PostsFilterButton(
              activeCount: activeCount,
              height: controlHeight,
              iconOnly: true,
              onPressed: () => _openFilters(
                buttonContext,
                statusFilter: filters.status,
                typeFilter: filters.type,
                hasChildrenFilter: filters.hasChildren,
              ),
            );
          },
        );

        final actions = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CategoriesSortDropdown(height: controlHeight),
            SizedBox(width: gap),
            filterButton,
          ],
        );

        if (inline) {
          final actionsWidth = (controlHeight * 2) + gap;
          final searchWidth = (availableWidth - actionsWidth)
              .clamp(120.0, metrics.inlineSearchWidthFor(availableWidth));
          return SizedBox(
            height: controlHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: searchWidth,
                      minWidth: 120,
                      minHeight: controlHeight,
                      maxHeight: controlHeight,
                    ),
                    child: _searchField(),
                  ),
                ),
                SizedBox(width: gap),
                actions,
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: controlHeight, child: _searchField()),
            SizedBox(height: gap),
            SizedBox(
              height: controlHeight,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: actions,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Dismissible chips for active category filters (excludes search).
class CategoriesActiveFilterChips extends StatelessWidget {
  const CategoriesActiveFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return BlocBuilder<CategoriesBloc, CategoriesState>(
      buildWhen: (prev, next) {
        if (prev is CategoriesLoaded && next is CategoriesLoaded) {
          return prev.filter != next.filter ||
              prev.typeFilter != next.typeFilter ||
              prev.hasChildrenFilter != next.hasChildrenFilter ||
              prev.sortOption != next.sortOption;
        }
        return prev.runtimeType != next.runtimeType;
      },
      builder: (context, state) {
        if (state is! CategoriesLoaded) return const SizedBox.shrink();

        final chips = <Widget>[];

        if (state.filter != CategoryFilter.all) {
          chips.add(
            _ActiveFilterChip(
              label: categoryStatusLabel(l10n, state.filter),
              onRemove: () => context.read<CategoriesBloc>().add(
                    ChangeCategoryFilterEvent(CategoryFilter.all),
                  ),
            ),
          );
        }

        if (state.typeFilter != CategoryTypeFilter.all) {
          chips.add(
            _ActiveFilterChip(
              label: categoryTypeLabel(l10n, state.typeFilter),
              onRemove: () => context.read<CategoriesBloc>().add(
                    UpdateCategoryTypeFilterEvent(CategoryTypeFilter.all),
                  ),
            ),
          );
        }

        if (state.hasChildrenFilter != CategoryHasChildrenFilter.all) {
          chips.add(
            _ActiveFilterChip(
              label: categoryHasChildrenLabel(l10n, state.hasChildrenFilter),
              onRemove: () => context.read<CategoriesBloc>().add(
                    UpdateCategoryHasChildrenFilterEvent(
                      CategoryHasChildrenFilter.all,
                    ),
                  ),
            ),
          );
        }

        if (state.sortOption != CategoriesSortDropdown.defaultSort) {
          chips.add(
            _ActiveFilterChip(
              label: categorySortLabel(l10n, state.sortOption),
              onRemove: () => context.read<CategoriesBloc>().add(
                    UpdateCategorySortEvent(CategoriesSortDropdown.defaultSort),
                  ),
            ),
          );
        }

        if (chips.isEmpty) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 2),
          child: Wrap(
            spacing: 6,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ...chips,
              TextButton(
                onPressed: () {
                  final bloc = context.read<CategoriesBloc>();
                  bloc.add(ChangeCategoryFilterEvent(CategoryFilter.all));
                  bloc.add(UpdateCategoryTypeFilterEvent(CategoryTypeFilter.all));
                  bloc.add(
                    UpdateCategoryHasChildrenFilterEvent(
                      CategoryHasChildrenFilter.all,
                    ),
                  );
                  bloc.add(
                    UpdateCategorySortEvent(CategoriesSortDropdown.defaultSort),
                  );
                  bloc.add(UpdateCategorySearchEvent(''));
                },
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n.t('clearAllFilters'),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
  });

  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primary.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onRemove,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(10, 4, 4, 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: scheme.primary,
                ),
              ),
              Icon(
                Icons.close_rounded,
                size: 14,
                color: scheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
