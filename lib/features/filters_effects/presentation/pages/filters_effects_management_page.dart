import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../settings/presentation/bloc/settings_cubit.dart';
import '../../domain/entities/filters_effects_entities.dart';
import '../bloc/ar_overlays_bloc.dart';
import '../bloc/ar_overlays_event.dart';
import '../bloc/ar_overlays_state.dart';
import '../bloc/filters_effects_bloc.dart';
import '../bloc/filters_effects_event.dart';
import '../bloc/filters_effects_state.dart';
import '../utils/fe_api_errors.dart';
import '../utils/fe_filter_preview_support.dart';
import '../utils/filters_effects_responsive.dart';
import '../widgets/ar_overlays_tab.dart';
import '../widgets/catalog_tab.dart';
import '../widgets/effects_tab.dart';
import '../widgets/fe_bulk_selection_toolbar.dart';
import '../widgets/fe_category_tabs_bar.dart';
import '../widgets/fe_filters_panel.dart';
import '../widgets/filters_effects_header.dart';
import '../widgets/filters_effects_tab_bar.dart';
import '../widgets/filters_tab.dart';

class FiltersEffectsManagementPage extends StatefulWidget {
  const FiltersEffectsManagementPage({super.key});

  @override
  State<FiltersEffectsManagementPage> createState() =>
      _FiltersEffectsManagementPageState();
}

class _FiltersEffectsManagementPageState
    extends State<FiltersEffectsManagementPage> {
  static const _maxContentWidth = 1680.0;
  static const _snackBarDuration = Duration(seconds: 3);

  String? _selectedFilterCategoryId;
  String? _selectedEffectCategoryId;

  @override
  void initState() {
    super.initState();
    FeFilterPreviewSupport.ensureConfigured();
  }

  @override
  void didUpdateWidget(covariant FiltersEffectsManagementPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    FeFilterPreviewSupport.ensureConfigured();
  }

  String _resolveMessage(
    BuildContext context,
    FiltersEffectsLoaded state,
  ) {
    final l10n = context.l10n;
    final message = state.message;
    if (message == null) return '';
    if (message.startsWith('fe')) {
      final params = state.messageParams;
      if (params != null && params.isNotEmpty) {
        return context.tr(message, params);
      }
      return l10n.tOr(message, message);
    }
    return message;
  }

  void _showActionSnackBar(
    BuildContext context, {
    required String text,
    required bool isError,
  }) {
    if (text.trim().isEmpty) return;
    final scheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            text,
            style: TextStyle(
              color: isError ? scheme.onError : Colors.white,
            ),
          ),
          backgroundColor:
              isError ? scheme.error : const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          duration: _snackBarDuration,
        ),
      );
  }

  void _onFiltersEffectsMessage(
    BuildContext context,
    FiltersEffectsState state,
  ) {
    if (state is! FiltersEffectsLoaded || state.message == null) {
      return;
    }
    final isError = state.isErrorMessage;
    final text = _resolveMessage(context, state);
    final isDuplicatePopup =
        state.message == feFilterEffectAlreadyExistsKey;

    // Clear first so the same conflict can be shown again later.
    context.read<FiltersEffectsBloc>().add(
      const ClearFiltersEffectsMessage(),
    );

    // Duplicate create/edit must use a dialog: snackbars sit under the
    // open editor modal and are not visible.
    if (isError && isDuplicatePopup) {
      final l10n = context.l10n;
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(
            l10n.tOr('error', 'Error'),
          ),
          content: Text(text),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n.tOr('close', 'Close')),
            ),
          ],
        ),
      );
      return;
    }

    _showActionSnackBar(context, text: text, isError: isError);
  }

  void _onArOverlaysMessage(BuildContext context, ArOverlaysState state) {
    if (state is! ArOverlaysLoaded) return;
    final isError = state.errorMessage != null;
    final text = state.errorMessage ?? state.successMessage ?? '';
    if (text.isEmpty) return;

    context.read<ArOverlaysBloc>().add(const ClearArOverlaysMessageEvent());
    _showActionSnackBar(context, text: text, isError: isError);
  }

  @override
  Widget build(BuildContext context) {
    FeFilterPreviewSupport.ensureConfigured();

    // Rebuild all copy when language changes.
    context.select<SettingsCubit, Locale>((c) => c.state.locale);
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainerLowest,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final metrics = FiltersEffectsLayoutMetrics(
            getFiltersEffectsDeviceType(constraints.maxWidth),
          );

          return MultiBlocListener(
            listeners: [
              BlocListener<FiltersEffectsBloc, FiltersEffectsState>(
                listenWhen: (p, c) =>
                    c is FiltersEffectsLoaded &&
                    c.message != null &&
                    (p is! FiltersEffectsLoaded || p.message != c.message),
                listener: _onFiltersEffectsMessage,
              ),
              BlocListener<ArOverlaysBloc, ArOverlaysState>(
                listenWhen: (p, c) =>
                    c is ArOverlaysLoaded &&
                    (c.successMessage != null || c.errorMessage != null) &&
                    (p is! ArOverlaysLoaded ||
                        p.successMessage != c.successMessage ||
                        p.errorMessage != c.errorMessage),
                listener: _onArOverlaysMessage,
              ),
            ],
            child: BlocBuilder<FiltersEffectsBloc, FiltersEffectsState>(
              builder: (context, state) {
              final isInitialLoad =
                  state is FiltersEffectsInitial ||
                  state is FiltersEffectsLoading;
              final isRefreshing =
                  state is FiltersEffectsLoaded && state.isActioning;
              final loaded =
                  state is FiltersEffectsLoaded ? state : null;
              final activeTab = loaded == null
                  ? FiltersEffectsTab.filters
                  : FiltersEffectsTabBar.normalizeTab(loaded.activeTab);
              final isEffectsTab = activeTab == FiltersEffectsTab.effects;

              // Drop stale category selection / legacy category tabs.
              if (loaded != null) {
                if (activeTab != loaded.activeTab) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    context.read<FiltersEffectsBloc>().add(
                      FiltersEffectsTabChanged(activeTab),
                    );
                  });
                }
                if (_selectedFilterCategoryId != null &&
                    !loaded.filterCategories
                        .any((c) => c.id == _selectedFilterCategoryId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedFilterCategoryId = null);
                    }
                  });
                }
                if (_selectedEffectCategoryId != null &&
                    !loaded.effectCategories
                        .any((c) => c.id == _selectedEffectCategoryId)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedEffectCategoryId = null);
                    }
                  });
                }
              }

              final showListTools = loaded != null &&
                  (activeTab == FiltersEffectsTab.filters || isEffectsTab);

              return Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: _maxContentWidth,
                  ),
                  child: Padding(
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
                          activeTab: activeTab,
                          showCreateAction:
                              metrics.isCompact && loaded != null,
                        ),
                        SizedBox(height: metrics.toolbarSectionGap),
                        if (loaded != null) ...[
                          FiltersEffectsTabBar(
                            activeTab: activeTab,
                            metrics: metrics,
                            showCreateAction: !metrics.isCompact,
                            onTabChanged: (_) {
                              setState(() {
                                _selectedFilterCategoryId = null;
                                _selectedEffectCategoryId = null;
                              });
                            },
                          ),
                          SizedBox(height: metrics.toolbarFilterGap),
                        ],
                        if (showListTools) ...[
                          if (metrics.isCompact) ...[
                            FeFiltersPanel(
                              query: loaded.query,
                              showRenderType: isEffectsTab,
                              controlHeight: metrics.toolbarControlHeight,
                            ),
                            SizedBox(height: metrics.toolbarFilterGap),
                            FeCategoryTabsBar(
                              isEffectCategory: isEffectsTab,
                              categories: isEffectsTab
                                  ? loaded.effectCategories
                                  : loaded.filterCategories,
                              selectedCategoryId: isEffectsTab
                                  ? _selectedEffectCategoryId
                                  : _selectedFilterCategoryId,
                              onCategorySelected: (id) {
                                setState(() {
                                  if (isEffectsTab) {
                                    _selectedEffectCategoryId = id;
                                  } else {
                                    _selectedFilterCategoryId = id;
                                  }
                                });
                              },
                            ),
                          ] else
                            SizedBox(
                              height: metrics.toolbarControlHeight + 4,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: FeFiltersPanel(
                                      query: loaded.query,
                                      showRenderType: isEffectsTab,
                                      controlHeight:
                                          metrics.toolbarControlHeight,
                                    ),
                                  ),
                                  SizedBox(width: metrics.filterGap + 4),
                                  Expanded(
                                    flex: 6,
                                    child: FeCategoryTabsBar(
                                      isEffectCategory: isEffectsTab,
                                      categories: isEffectsTab
                                          ? loaded.effectCategories
                                          : loaded.filterCategories,
                                      selectedCategoryId: isEffectsTab
                                          ? _selectedEffectCategoryId
                                          : _selectedFilterCategoryId,
                                      onCategorySelected: (id) {
                                        setState(() {
                                          if (isEffectsTab) {
                                            _selectedEffectCategoryId = id;
                                          } else {
                                            _selectedFilterCategoryId = id;
                                          }
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(height: metrics.toolbarFilterGap),
                        ],
                        if (isInitialLoad || isRefreshing) ...[
                          const LinearProgressIndicator(minHeight: 2),
                          SizedBox(height: metrics.toolbarFilterGap),
                        ],
                        if (showListTools) ...[
                          FeBulkSelectionToolbar(
                            metrics: metrics,
                            activeTab: activeTab,
                          ),
                          SizedBox(height: metrics.toolbarFilterGap),
                        ],
                        Expanded(
                          child: _ManagementBody(
                            state: state,
                            metrics: metrics,
                            selectedFilterCategoryId:
                                _selectedFilterCategoryId,
                            selectedEffectCategoryId:
                                _selectedEffectCategoryId,
                            onClearCategory: () {
                              setState(() {
                                _selectedFilterCategoryId = null;
                                _selectedEffectCategoryId = null;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          );
        },
      ),
    );
  }
}

class _ManagementBody extends StatelessWidget {
  const _ManagementBody({
    required this.state,
    required this.metrics,
    required this.selectedFilterCategoryId,
    required this.selectedEffectCategoryId,
    required this.onClearCategory,
  });

  final FiltersEffectsState state;
  final FiltersEffectsLayoutMetrics metrics;
  final String? selectedFilterCategoryId;
  final String? selectedEffectCategoryId;
  final VoidCallback onClearCategory;

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
    final activeTab = FiltersEffectsTabBar.normalizeTab(loaded.activeTab);

    return switch (activeTab) {
      FiltersEffectsTab.filters ||
      FiltersEffectsTab.filterCategories => FiltersTab(
        loaded: loaded,
        metrics: metrics,
        selectedCategoryId: selectedFilterCategoryId,
        onClearCategory: onClearCategory,
      ),
      FiltersEffectsTab.effects ||
      FiltersEffectsTab.effectCategories => EffectsTab(
        loaded: loaded,
        metrics: metrics,
        selectedCategoryId: selectedEffectCategoryId,
        onClearCategory: onClearCategory,
      ),
      FiltersEffectsTab.arOverlays => ArOverlaysTab(metrics: metrics),
      FiltersEffectsTab.catalog => CatalogTab(loaded: loaded, metrics: metrics),
    };
  }
}
