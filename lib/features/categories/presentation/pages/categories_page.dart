import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/l10n_message.dart';
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
    if (width < 400) return 10;
    if (width < 600) return 14;
    return categoriesPageHorizontalPadding(width);
  }

  double _verticalPadding(double width, bool hasTree) {
    if (width < 400) return hasTree ? 8 : 12;
    if (width < 720) return hasTree ? 10 : 14;
    return hasTree ? 12 : 20;
  }

  double _sectionSpacing(double width, bool hasTree) {
    if (width < 400) return hasTree ? 8 : 10;
    if (width < 720) return hasTree ? 10 : 12;
    return hasTree ? 12 : 16;
  }

  double _panelRadius(double width) => width < 520 ? 12 : 16;

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
              content: Text(state.failureMessage!),
              backgroundColor: scheme.error,
              behavior: SnackBarBehavior.floating,
            ));
        }
      },
      builder: (context, state) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        final scheme = theme.colorScheme;

        return LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final hasTree = state is CategoriesLoaded &&
                state.catalogCategories.isNotEmpty;
            final hPad = _horizontalPadding(width);
            final vPad = _verticalPadding(width, hasTree);
            final sectionGap = _sectionSpacing(width, hasTree);
            final compactHeader = width < 720;

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
                      vPad,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        CategoriesPageHeader(
                          isDark: isDark,
                          state: state,
                          compact: compactHeader,
                        ),
                        SizedBox(height: sectionGap),
                        const CategoriesSelectionHeader(),
                        if (hasTree) SizedBox(height: width < 520 ? 8 : 10),
                        Expanded(
                          child: hasTree
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    _panelRadius(width),
                                  ),
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: scheme.outlineVariant,
                                      ),
                                      borderRadius: BorderRadius.circular(
                                        _panelRadius(width),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: scheme.shadow
                                              .withValues(alpha: 0.04),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: _buildBody(context, state, isDark),
                                  ),
                                )
                              : _buildBody(context, state, isDark),
                        ),
                      ],
                    ),
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
      final noFiltersApplied = state.searchQuery.trim().isEmpty &&
          state.filter == CategoryFilter.all &&
          state.typeFilter == CategoryTypeFilter.all;

      if (!hasCatalog && noFiltersApplied) {
        return CategoriesEmptyView(isDark: isDark);
      }

      if (state.isFetching && state.displayRoots.isEmpty) {
        return Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        );
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
      );
    }
    return const SizedBox.shrink();
  }
}
