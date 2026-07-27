import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../../domain/entities/gift_group_entities.dart';
import '../bloc/gift_groups_bloc.dart';
import '../bloc/gifts_bloc.dart';
import '../bloc/gifts_catalog_selection_cubit.dart';
import '../utils/gifts_page_layout.dart';
import '../utils/gifts_responsive.dart';
import '../widgets/create_gift_dialog.dart';
import '../widgets/edit_gift_dialog.dart';
import '../widgets/gifts_bulk_selection_toolbar.dart';
import '../widgets/gifts_catalog_tabs_bar.dart';
import '../widgets/gifts_filters_panel.dart';
import '../widgets/gifts_grid_sliver.dart';
import '../widgets/gifts_keyboard_intents.dart';
import '../widgets/gifts_page_header.dart';
import '../widgets/gifts_page_sliver_states.dart';

void showGiftPreviewDialog(BuildContext context, GiftEntity gift) {
  showPreviewGiftDialog(context, gift);
}

class GiftsPage extends StatelessWidget {
  const GiftsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('GiftsPage rebuilt');
    return PersistentBlocProvider<GiftsBloc>(
      debugLabel: 'GiftsPage',
      create: () => di.sl<GiftsBloc>()..add(LoadAdminGiftsEvent()),
      child: BlocProvider(
        create: (_) =>
            di.sl<GiftGroupsBloc>()..add(const LoadGiftGroupsEvent()),
        child: BlocProvider(
          create: (_) => GiftsCatalogSelectionCubit(),
          child: const _GiftsPageView(),
        ),
      ),
    );
  }
}

class _GiftsPageView extends StatefulWidget {
  const _GiftsPageView();

  @override
  State<_GiftsPageView> createState() => _GiftsPageViewState();
}

class _GiftsPageViewState extends State<_GiftsPageView> {
  final _scrollController = ScrollController();

  static const _maxContentWidth = 1680.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _horizontalPadding(double width) {
    if (width < 360) return 6;
    if (width < 400) return 8;
    if (width < 600) return 10;
    if (width < 960) return 14;
    return 20;
  }

  double _verticalPadding(double width) {
    if (width < 400) return 4;
    if (width < 720) return 6;
    return 10;
  }

  double _sectionSpacing(double width) {
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllGiftsIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape):
            const ClearGiftSelectionIntent(),
      },
      child: Actions(
        actions: {
          SelectAllGiftsIntent: CallbackAction<SelectAllGiftsIntent>(
            onInvoke: (_) {
              context.read<GiftsBloc>().add(SelectAllGiftsEvent());
              return null;
            },
          ),
          ClearGiftSelectionIntent: CallbackAction<ClearGiftSelectionIntent>(
            onInvoke: (_) {
              context.read<GiftsBloc>().add(ClearGiftSelectionEvent());
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: ColoredBox(
            color: scheme.surfaceContainerLowest,
            child: MultiBlocListener(
              listeners: [
                BlocListener<GiftsBloc, GiftsState>(
                  listenWhen: (prev, next) =>
                      next is GiftsLoaded &&
                      next.bulkActionMessage != null &&
                      (prev is! GiftsLoaded ||
                          prev.bulkActionMessage != next.bulkActionMessage),
                  listener: (context, state) {
                    if (state is! GiftsLoaded ||
                        state.bulkActionMessage == null) {
                      return;
                    }
                    final messenger = ScaffoldMessenger.of(context);
                    messenger.hideCurrentSnackBar();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(state.bulkActionMessage!),
                        backgroundColor:
                            state.bulkActionIsError ? scheme.error : null,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context
                        .read<GiftsBloc>()
                        .add(ClearGiftsBulkFeedbackEvent());
                  },
                ),
                BlocListener<GiftsBloc, GiftsState>(
                  listenWhen: (prev, next) =>
                      next is GiftsLoaded &&
                      (next.successMessage != null ||
                          next.errorMessage != null) &&
                      (prev is! GiftsLoaded ||
                          prev.successMessage != next.successMessage ||
                          prev.errorMessage != next.errorMessage),
                  listener: (ctx, state) {
                    if (state is! GiftsLoaded) return;
                    final messenger = ScaffoldMessenger.of(ctx);
                    if (state.successMessage != null) {
                      // Keep tab membership UI in sync after create/update
                      // (group assign runs in GiftsBloc via replace-group-gifts).
                      ctx.read<GiftGroupsBloc>().add(
                            const LoadGiftGroupsEvent(refresh: true),
                          );
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(state.successMessage!),
                            backgroundColor: scheme.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    }
                    if (state.errorMessage != null) {
                      final l10n = ctx.l10n;
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              l10n.tOr(
                                state.errorMessage!,
                                state.errorMessage!,
                              ),
                            ),
                            backgroundColor: scheme.error,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    }
                  },
                ),
                BlocListener<GiftGroupsBloc, GiftGroupsState>(
                  listenWhen: (previous, current) =>
                      current is GiftGroupsLoaded &&
                      current.feedbackMessage != null,
                  listener: (context, state) {
                    if (state is! GiftGroupsLoaded ||
                        state.feedbackMessage == null) {
                      return;
                    }
                    final l10n = context.l10n;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.tOr(
                            state.feedbackMessage!,
                            state.feedbackMessage!,
                          ),
                        ),
                        backgroundColor:
                            state.feedbackIsError ? scheme.error : null,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    context
                        .read<GiftGroupsBloc>()
                        .add(const ClearGiftGroupsFeedbackEvent());
                  },
                ),
              ],
              child: BlocBuilder<GiftsBloc, GiftsState>(
                buildWhen: (prev, next) {
                  if (prev.runtimeType != next.runtimeType) return true;
                  if (prev is! GiftsLoaded || next is! GiftsLoaded) {
                    return true;
                  }
                  // Skip snackbar / pending-image-only updates so the catalog
                  // scroll view is not rebuilt while the user is scrolling.
                  return prev.gifts != next.gifts ||
                      prev.selectedTab != next.selectedTab ||
                      prev.selectedSort != next.selectedSort ||
                      prev.viewType != next.viewType ||
                      prev.searchQuery != next.searchQuery ||
                      prev.fromDate != next.fromDate ||
                      prev.toDate != next.toDate ||
                      prev.minPriceFilter != next.minPriceFilter ||
                      prev.maxPriceFilter != next.maxPriceFilter ||
                      prev.typeFilter != next.typeFilter ||
                      prev.tagFilter != next.tagFilter ||
                      prev.sizeFilter != next.sizeFilter ||
                      prev.publishedFilter != next.publishedFilter ||
                      prev.selectedGiftIds != next.selectedGiftIds ||
                      prev.isPerformingBulkAction !=
                          next.isPerformingBulkAction ||
                      prev.isActioning != next.isActioning ||
                      prev.currentPage != next.currentPage;
                },
                builder: (ctx, state) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final metrics =
                          GiftsLayoutMetrics(getGiftsDeviceType(width));
                      final hPad = _horizontalPadding(width);
                      final vPad = _verticalPadding(width);
                      final sectionGap = _sectionSpacing(width);
                      final compactHeader = width < 720;
                      final isLoaded = state is GiftsLoaded;
                      final loaded = isLoaded ? state : null;
                      final showDesktopPagination =
                          metrics.useDesktopPagination &&
                              loaded != null &&
                              loaded.giftsTotalCount > 0;

                      final isSelectionMode =
                          loaded != null && loaded.isSelectionMode;
                      final tightGap = width < 520 ? 4.0 : 6.0;

                      Widget buildBodyPanel() {
                        return _CatalogBodyPanel(
                          state: state,
                          radius: _panelRadius(width),
                          scrollController: _scrollController,
                        );
                      }

                      final headerWidget = GiftsPageHeader(
                        isLoading: state is GiftsLoading,
                        showViewToggle: isLoaded,
                        canAdd: isLoaded,
                        compact: compactHeader,
                        onAdd: () => showCreateGiftDialog(ctx),
                        onRefresh: () {
                          ctx
                              .read<GiftsBloc>()
                              .add(LoadAdminGiftsEvent());
                          ctx.read<GiftGroupsBloc>().add(
                                const LoadGiftGroupsEvent(
                                  refresh: true,
                                ),
                              );
                        },
                      );

                      final filtersPanelWidget = loaded != null
                          ? GiftsFiltersPanel(
                              loaded: loaded,
                              screenWidth: width,
                              onStatusFilterSelected: (_) {
                                context
                                    .read<GiftsCatalogSelectionCubit>()
                                    .clear();
                              },
                            )
                          : null;

                      final catalogTabsWidget = loaded != null
                          ? BlocSelector<GiftsCatalogSelectionCubit, String?,
                              String?>(
                              selector: (id) => id,
                              builder: (context, selectedGroupId) {
                                return GiftsCatalogTabsBar(
                                  selectedGroupId: selectedGroupId,
                                  onGroupSelected: (group) {
                                    context
                                        .read<GiftsCatalogSelectionCubit>()
                                        .selectGroup(group?.id);
                                    if (group != null) {
                                      ctx.read<GiftsBloc>().add(
                                            GoToGiftsPageEvent(1),
                                          );
                                    }
                                  },
                                );
                              },
                            )
                          : null;

                      final paginationWidget = showDesktopPagination
                          ? BlocSelector<GiftsCatalogSelectionCubit, String?,
                              String?>(
                              selector: (id) => id,
                              builder: (context, selectedGroupId) {
                                return _CatalogPagination(
                                  loaded: loaded,
                                  selectedGroupId: selectedGroupId,
                                );
                              },
                            )
                          : null;

                      // Single scroll surface for gifts; chrome stays compact
                      // so the grid gets maximum vertical room on all sizes.
                      final content = Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          headerWidget,
                          SizedBox(height: sectionGap),
                          if (loaded != null) ...[
                            filtersPanelWidget!,
                            SizedBox(height: sectionGap),
                            catalogTabsWidget!,
                            if (isSelectionMode) ...[
                              SizedBox(height: tightGap),
                              const GiftsBulkSelectionToolbar(),
                            ],
                            SizedBox(height: tightGap),
                          ],
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, bodyConstraints) {
                                return GiftsViewportWidth(
                                  width: bodyConstraints.maxWidth,
                                  child: buildBodyPanel(),
                                );
                              },
                            ),
                          ),
                          if (paginationWidget != null) ...[
                            SizedBox(height: tightGap),
                            paginationWidget,
                          ],
                        ],
                      );

                      return Align(
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
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CatalogBodyPanel extends StatelessWidget {
  const _CatalogBodyPanel({
    required this.state,
    required this.radius,
    required this.scrollController,
  });

  final GiftsState state;
  final double radius;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Avoid ClipRRect around the scroll surface — clipping the full catalog
    // every frame is expensive with many shadowed gift cards. Keep the same
    // surface color; corner radius remains on the surrounding chrome.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state is GiftsLoading) {
      return CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: const [GiftsSliverSkeletons()],
      );
    }
    if (state is GiftsError) {
      return CustomScrollView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          GiftsSliverError(message: (state as GiftsError).message),
        ],
      );
    }
    if (state is GiftsLoaded) {
      return BlocSelector<GiftsCatalogSelectionCubit, String?, String?>(
        selector: (id) => id,
        builder: (context, selectedGroupId) {
          return _CatalogLoadedScroll(
            scrollController: scrollController,
            selectedGroupId: selectedGroupId,
          );
        },
      );
    }
    return const SizedBox.shrink();
  }
}

class _CatalogLoadedScroll extends StatelessWidget {
  const _CatalogLoadedScroll({
    required this.scrollController,
    this.selectedGroupId,
  });

  final ScrollController scrollController;
  final String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final selectedGroupId = this.selectedGroupId;
    if (selectedGroupId == null) {
      return CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        cacheExtent: 800,
        slivers: [
          GiftsGridSliver(
            key: const ValueKey('gifts-grid-all'),
            onPreviewGift: showGiftPreviewDialog,
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),
        ],
      );
    }

    return BlocSelector<GiftGroupsBloc, GiftGroupsState, GiftGroupEntity?>(
      selector: (groupsState) {
        if (groupsState is! GiftGroupsLoaded) return null;
        for (final group in groupsState.groups) {
          if (group.id == selectedGroupId) return group;
        }
        return null;
      },
      builder: (context, selectedGroup) {
        final giftIdFilter =
            selectedGroup?.gifts.map((m) => m.gift.id).toSet();
        final preferOrder =
            selectedGroup?.gifts.map((m) => m.gift.id).toList();

        return CustomScrollView(
          controller: scrollController,
          physics: const ClampingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          cacheExtent: 800,
          slivers: [
            if (selectedGroup != null)
              SliverToBoxAdapter(
                child: _SelectedGroupBanner(group: selectedGroup),
              ),
            GiftsGridSliver(
              key: ValueKey('gifts-grid-$selectedGroupId'),
              onPreviewGift: showGiftPreviewDialog,
              giftIdFilter: giftIdFilter,
              preferGiftIdOrder: preferOrder,
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
          ],
        );
      },
    );
  }
}

class _CatalogPagination extends StatelessWidget {
  const _CatalogPagination({
    required this.loaded,
    this.selectedGroupId,
  });

  final GiftsLoaded loaded;
  final String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final groupsState = context.watch<GiftGroupsBloc>().state;
    Set<String>? giftIdFilter;
    if (selectedGroupId != null && groupsState is GiftGroupsLoaded) {
      for (final group in groupsState.groups) {
        if (group.id == selectedGroupId) {
          giftIdFilter = group.gifts.map((m) => m.gift.id).toSet();
          break;
        }
      }
    }

    final total = giftsFilteredTotalCount(
      loaded,
      giftIdFilter: giftIdFilter,
    );
    final lastPage = total <= 0
        ? 1
        : (total + GiftsBloc.pageLimit - 1) ~/ GiftsBloc.pageLimit;
    final itemCount = giftsPagedForView(
      loaded,
      infiniteScroll: false,
      giftIdFilter: giftIdFilter,
    ).length;

    return AppPaginationBar(
      currentPage: loaded.currentPage.clamp(1, lastPage),
      lastPage: lastPage,
      total: total,
      pageSize: GiftsBloc.pageLimit,
      itemCount: itemCount,
      hideWhenSinglePage: false,
      borderRadius: BorderRadius.circular(12),
      onPageChanged: (page) =>
          context.read<GiftsBloc>().add(GoToGiftsPageEvent(page)),
    );
  }
}

class _SelectedGroupBanner extends StatelessWidget {
  const _SelectedGroupBanner({required this.group});

  final GiftGroupEntity group;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.tab_rounded, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${group.name} · ${group.giftCount} ${l10n.tOr('giftGroupGiftsCount', 'gifts')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
