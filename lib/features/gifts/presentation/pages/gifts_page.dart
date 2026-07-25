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
        child: const _GiftsPageView(),
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
  String? _selectedGroupId;

  static const _maxContentWidth = 1680.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final width = MediaQuery.sizeOf(context).width;
    final metrics = GiftsLayoutMetrics(getGiftsDeviceType(width));
    if (!metrics.useInfiniteScroll) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<GiftsBloc>().add(LoadMoreGiftsEvent());
    }
  }

  double _horizontalPadding(double width) {
    if (width < 400) return 10;
    if (width < 600) return 14;
    return GiftsLayoutMetrics(getGiftsDeviceType(width)).pageHorizontalPadding;
  }

  double _verticalPadding(double width) {
    if (width < 400) return 10;
    if (width < 720) return 12;
    return 16;
  }

  double _sectionSpacing(double width) {
    if (width < 400) return 8;
    if (width < 720) return 10;
    return 12;
  }

  double _panelRadius(double width) => width < 520 ? 12 : 16;

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
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(state.errorMessage!),
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
                              vPad,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                GiftsPageHeader(
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
                                ),
                                SizedBox(height: sectionGap),
                                if (loaded != null) ...[
                                  GiftsFiltersPanel(
                                    loaded: loaded,
                                    screenWidth: width,
                                    onStatusFilterSelected: (_) {
                                      setState(
                                        () => _selectedGroupId = null,
                                      );
                                    },
                                  ),
                                  SizedBox(height: sectionGap),
                                  GiftsCatalogTabsBar(
                                    selectedGroupId: _selectedGroupId,
                                    onGroupSelected: (group) {
                                      setState(
                                        () => _selectedGroupId = group?.id,
                                      );
                                      if (group != null) {
                                        ctx.read<GiftsBloc>().add(
                                              GoToGiftsPageEvent(1),
                                            );
                                      }
                                    },
                                  ),
                                  SizedBox(height: width < 520 ? 8 : 10),
                                  const GiftsBulkSelectionToolbar(),
                                  SizedBox(height: width < 520 ? 8 : 10),
                                ],
                                Expanded(
                                  child: _CatalogBodyPanel(
                                    state: state,
                                    radius: _panelRadius(width),
                                    scrollController: _scrollController,
                                    selectedGroupId: _selectedGroupId,
                                  ),
                                ),
                                if (showDesktopPagination) ...[
                                  SizedBox(height: width < 720 ? 8 : 10),
                                  _CatalogPagination(
                                    loaded: loaded,
                                    selectedGroupId: _selectedGroupId,
                                  ),
                                ],
                              ],
                            ),
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
    this.selectedGroupId,
  });

  final GiftsState state;
  final double radius;
  final ScrollController scrollController;
  final String? selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: _buildContent(context),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (state is GiftsLoading) {
      return CustomScrollView(
        controller: scrollController,
        slivers: const [GiftsSliverSkeletons()],
      );
    }
    if (state is GiftsError) {
      return CustomScrollView(
        controller: scrollController,
        slivers: [
          GiftsSliverError(message: (state as GiftsError).message),
        ],
      );
    }
    if (state is GiftsLoaded) {
      return _CatalogLoadedScroll(
        scrollController: scrollController,
        selectedGroupId: selectedGroupId,
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

  GiftGroupEntity? _resolveGroup(GiftGroupsState groupsState) {
    if (selectedGroupId == null || groupsState is! GiftGroupsLoaded) {
      return null;
    }
    for (final group in groupsState.groups) {
      if (group.id == selectedGroupId) return group;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final groupsState = context.watch<GiftGroupsBloc>().state;
    final selectedGroup = _resolveGroup(groupsState);
    final giftIdFilter =
        selectedGroup?.gifts.map((m) => m.gift.id).toSet();
    final preferOrder =
        selectedGroup?.gifts.map((m) => m.gift.id).toList();

    return CustomScrollView(
      controller: scrollController,
      slivers: [
        if (selectedGroup != null)
          SliverToBoxAdapter(
            child: _SelectedGroupBanner(group: selectedGroup),
          ),
        GiftsGridSliver(
          key: ValueKey('gifts-grid-${selectedGroupId ?? 'all'}'),
          onPreviewGift: showGiftPreviewDialog,
          giftIdFilter: giftIdFilter,
          preferGiftIdOrder: preferOrder,
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.primaryContainer.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.primary.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.tab_rounded, size: 18, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${group.name} · ${group.giftCount} ${l10n.tOr('giftGroupGiftsCount', 'gifts')}',
                  maxLines: 2,
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
