import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../utils/filters_effects_responsive.dart';
import '../widgets/catalog_tab.dart';
import '../widgets/effect_categories_tab.dart';
import '../widgets/effects_tab.dart';
import '../widgets/filter_categories_tab.dart';
import '../widgets/filters_effects_header.dart';
import '../widgets/filters_effects_overview_cards.dart';
import '../widgets/filters_effects_tab_bar.dart';
import '../widgets/filters_tab.dart';

class FiltersEffectsManagementPage extends StatelessWidget {
  const FiltersEffectsManagementPage({super.key});

  String _resolveMessage(BuildContext context, String message) {
    final l10n = context.l10n;
    if (message.startsWith('fe')) {
      return l10n.tOr(message, message);
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    // Rebuild all copy when language changes.
    context.select<SettingsCubit, Locale>((c) => c.state.locale);

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = FiltersEffectsLayoutMetrics(
          getFiltersEffectsDeviceType(constraints.maxWidth),
        );

        return BlocConsumer<FiltersEffectsBloc, FiltersEffectsState>(
          listenWhen: (p, c) =>
              c is FiltersEffectsLoaded &&
              c.message != null &&
              (p is! FiltersEffectsLoaded || p.message != c.message),
          listener: (context, state) {
            if (state is! FiltersEffectsLoaded || state.message == null) {
              return;
            }
            final scheme = Theme.of(context).colorScheme;
            final isError = state.isErrorMessage;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    _resolveMessage(context, state.message!),
                    style: TextStyle(
                      color: isError ? scheme.onError : Colors.white,
                    ),
                  ),
                  backgroundColor:
                      isError ? scheme.error : const Color(0xFF2E7D32),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            context
                .read<FiltersEffectsBloc>()
                .add(const ClearFiltersEffectsMessage());
          },
          builder: (context, state) {
            final isInitialLoad = state is FiltersEffectsInitial ||
                state is FiltersEffectsLoading;
            final isRefreshing =
                state is FiltersEffectsLoaded && state.isActioning;

            return Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                metrics.pageHorizontalPadding,
                metrics.pageTopPadding,
                metrics.pageHorizontalPadding,
                metrics.pageBottomPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FiltersEffectsHeader(
                    metrics: metrics,
                    isLoading: isInitialLoad || isRefreshing,
                  ),
                  SizedBox(height: metrics.toolbarSectionGap),
                  if (state is FiltersEffectsLoaded &&
                      state.overview != null) ...[
                    FiltersEffectsOverviewCards(
                      overview: state.overview!,
                      metrics: metrics,
                    ),
                    SizedBox(height: metrics.sectionGap),
                  ] else if (isInitialLoad) ...[
                    FiltersEffectsOverviewSkeleton(metrics: metrics),
                    SizedBox(height: metrics.sectionGap),
                  ],
                  if (state is FiltersEffectsLoaded) ...[
                    FiltersEffectsTabBar(
                      activeTab: state.activeTab,
                      metrics: metrics,
                    ),
                    SizedBox(height: metrics.toolbarFilterGap),
                  ],
                  if (isInitialLoad || isRefreshing) ...[
                    const LinearProgressIndicator(minHeight: 2),
                    SizedBox(height: metrics.toolbarFilterGap),
                  ],
                  SizedBox(height: metrics.sectionGap),
                  Expanded(
                    child: _ManagementBody(
                      state: state,
                      metrics: metrics,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _ManagementBody extends StatelessWidget {
  const _ManagementBody({
    required this.state,
    required this.metrics,
  });

  final FiltersEffectsState state;
  final FiltersEffectsLayoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    if (state is FiltersEffectsError) {
      return Center(
        child: ErrorView(
          message: (state as FiltersEffectsError).message,
          retryLabel: context.l10n.t('retry'),
          onRetry: () => context.read<FiltersEffectsBloc>().add(
                const LoadFiltersEffects(),
              ),
        ),
      );
    }

    if (state is FiltersEffectsInitial || state is FiltersEffectsLoading) {
      return const Center(child: LoadingView());
    }

    final loaded = state as FiltersEffectsLoaded;

    return switch (loaded.activeTab) {
      FiltersEffectsTab.filters => FiltersTab(
          loaded: loaded,
          metrics: metrics,
        ),
      FiltersEffectsTab.filterCategories => FilterCategoriesTab(
          loaded: loaded,
          metrics: metrics,
        ),
      FiltersEffectsTab.effects => EffectsTab(
          loaded: loaded,
          metrics: metrics,
        ),
      FiltersEffectsTab.effectCategories => EffectCategoriesTab(
          loaded: loaded,
          metrics: metrics,
        ),
      FiltersEffectsTab.catalog => CatalogTab(
          loaded: loaded,
          metrics: metrics,
        ),
    };
  }
}
