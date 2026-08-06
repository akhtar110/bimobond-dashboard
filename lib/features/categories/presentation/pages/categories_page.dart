import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/l10n_message.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/categories_bloc.dart';
import '../utils/categories_page_layout.dart';
import '../widgets/categories_page_body_states.dart';
import '../widgets/categories_page_header.dart';
import '../widgets/categories_selection_header.dart';
import '../widgets/category_form_dialog.dart';
import '../widgets/category_tree_view.dart';

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('CategoriesPage rebuilt');
    return PersistentBlocProvider<CategoriesBloc>(
      debugLabel: 'CategoriesPage',
      create: () => di.sl<CategoriesBloc>()..add(LoadCategoriesEvent()),
      child: const _CategoriesPageBody(),
    );
  }
}

class _CategoriesPageBody extends StatelessWidget {
  const _CategoriesPageBody();

  static const _maxContentWidth = 1680.0;

  double _horizontalPadding(double width) {
    if (width < 360) return 6;
    if (width < 400) return 8;
    if (width < 600) return 10;
    if (width < 960) return 14;
    return categoriesPageHorizontalPadding(width);
  }

  double _verticalPadding(double width, bool hasTree) {
    if (width < 400) return 4;
    if (width < 720) return 6;
    return hasTree ? 8 : 12;
  }

  double _sectionSpacing(double width, bool hasTree) {
    if (width < 400) return 4;
    if (width < 720) return 6;
    return 8;
  }

  double _panelRadius(double width) {
    if (width < 360) return 8;
    if (width < 520) return 10;
    return 14;
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CategoriesBloc, CategoriesState>(
      listenWhen: (previous, current) {
        if (current is! CategoriesLoaded) return false;
        final newMsg =
            current.successMessage ?? current.failureMessage;
        if (newMsg == null) return false;
        if (previous is! CategoriesLoaded) return true;
        final prevMsg = previous.successMessage ?? previous.failureMessage;
        return newMsg != prevMsg;
      },
      listener: (context, state) {
        if (state is! CategoriesLoaded) return;
        final scheme = Theme.of(context).colorScheme;
        final messenger = ScaffoldMessenger.of(context);
        if (state.successMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(localizeMessage(context, state.successMessage!)),
              backgroundColor: scheme.primary,
              behavior: SnackBarBehavior.floating,
            ));
        } else if (state.failureMessage != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              content: Text(
                localizeMessage(context, state.failureMessage!),
              ),
              backgroundColor: scheme.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final scheme = theme.colorScheme;
        final metrics = categoriesMetricsOf(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final loaded = state is CategoriesLoaded ? state : null;
            final hasTree = loaded != null &&
                (loaded.catalogCategories.isNotEmpty ||
                    loaded.searchQuery.trim().isNotEmpty ||
                    loaded.filter != CategoryFilter.all ||
                    loaded.typeFilter != CategoryTypeFilter.all);
            final hPad = _horizontalPadding(width);
            final vPad = _verticalPadding(width, hasTree);
            final sectionGap = _sectionSpacing(width, hasTree);
            final compactHeader = width < 720;
            final showDesktopPagination = metrics.useDesktopPagination &&
                loaded != null &&
                loaded.rootsTotalCount > 0;
            final isSelectionMode =
                loaded != null && loaded.isSelectionMode;
            final tightGap = width < 520 ? 4.0 : 6.0;

            Widget buildBodyContainer() {
              final bodyChild = _buildBody(context, state, isDark);
              if (!hasTree) return bodyChild;

              final radius = _panelRadius(width);
              return ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surface,
                    border: Border.all(
                      color: scheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: bodyChild,
                ),
              );
            }

            final headerWidget = CategoriesPageHeader(
              isDark: isDark,
              state: state,
              compact: compactHeader,
              showToolbar: hasTree,
              metrics: metrics,
            );

            final paginationWidget = showDesktopPagination
                ? _CategoriesDesktopPagination(state: loaded)
                : null;

            // Single column layout (no nested scroll) so the tree gets
            // maximum vertical room on phones, tablets, and desktop.
            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                headerWidget,
                SizedBox(height: sectionGap),
                if (isSelectionMode) ...[
                  const CategoriesSelectionHeader(),
                  SizedBox(height: tightGap),
                ],
                Expanded(
                  child: buildBodyContainer(),
                ),
                if (paginationWidget != null) ...[
                  SizedBox(height: tightGap),
                  paginationWidget,
                ],
              ],
            );

            return ColoredBox(
              color: scheme.surfaceContainerLowest,
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maxContentWidth,
                  ),
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(
                      hPad,
                      vPad,
                      hPad,
                      width < 720 ? 4 : vPad,
                    ),
                    child: content,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CategoriesState state, bool isDark) {
    if (state is CategoriesLoading) {
      return CategoriesLoadingView(isDark: isDark);
    }
    if (state is CategoriesError) {
      return CategoriesErrorView(
        message: state.message,
        onRetry: () => context.read<CategoriesBloc>().add(LoadCategoriesEvent()),
      );
    }
    if (state is CategoriesLoaded) {
      final hasCatalog = state.catalogCategories.isNotEmpty;
      final filtersActive = state.searchQuery.trim().isNotEmpty ||
          state.filter != CategoryFilter.all ||
          state.typeFilter != CategoryTypeFilter.all;

      if (!hasCatalog && !filtersActive) {
        return CategoriesEmptyView(isDark: isDark);
      }

      return CategoryTreeView(
        state: state,
        onFormRequest: ({editing, parentForNew}) => showCategoryForm(
          context,
          editing: editing,
          parentForNew: parentForNew,
        ),
        onDeleteRequest: (category) =>
            confirmDeleteCategory(context, category),
        onToggleStatusRequest: (category) =>
            confirmToggleCategoryStatus(context, category),
      );
    }
    return const SizedBox.shrink();
  }
}

class _CategoriesDesktopPagination extends StatelessWidget {
  const _CategoriesDesktopPagination({required this.state});

  final CategoriesLoaded state;

  @override
  Widget build(BuildContext context) {
    final visible = state.pagedLeftPanelRoots(infiniteScroll: false);

    return AppPaginationBar(
      currentPage: state.currentPage,
      lastPage: state.lastPage,
      total: state.rootsTotalCount,
      pageSize: CategoriesBloc.pageLimit,
      itemCount: visible.length,
      // Keep visible even for a single page so the footer is never missing.
      hideWhenSinglePage: false,
      showBorder: false,
      borderRadius: BorderRadius.circular(12),
      onPageChanged: (page) =>
          context.read<CategoriesBloc>().add(GoToCategoriesPageEvent(page)),
    );
  }
}
