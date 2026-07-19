import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../core/widgets/dashboard/app_pagination_bar.dart';
import '../../../../injection_container.dart' as di;
import '../../domain/entities/gift_entity.dart';
import '../bloc/gifts_bloc.dart';
import '../utils/gifts_responsive.dart';
import '../widgets/create_gift_dialog.dart';
import '../widgets/edit_gift_dialog.dart';
import '../widgets/gifts_bulk_selection_toolbar.dart';
import '../widgets/gifts_filter_bar_delegate.dart';
import '../widgets/gifts_grid_sliver.dart';
import '../widgets/gifts_keyboard_intents.dart';
import '../widgets/gifts_page_sliver_states.dart';
import '../widgets/gifts_sliver_header.dart';

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
      child: const _GiftsPageView(),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllGiftsIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const ClearGiftSelectionIntent(),
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
          child: Scaffold(
            backgroundColor: scheme.surfaceContainerLowest,
            body: BlocListener<GiftsBloc, GiftsState>(
              listenWhen: (prev, next) =>
                  next is GiftsLoaded &&
                  next.bulkActionMessage != null &&
                  (prev is! GiftsLoaded ||
                      prev.bulkActionMessage != next.bulkActionMessage),
              listener: (context, state) {
                if (state is! GiftsLoaded || state.bulkActionMessage == null) {
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
                context.read<GiftsBloc>().add(ClearGiftsBulkFeedbackEvent());
              },
              child: BlocConsumer<GiftsBloc, GiftsState>(
                listenWhen: (prev, next) =>
                    next is GiftsLoaded &&
                    (next.successMessage != null || next.errorMessage != null) &&
                    (prev is! GiftsLoaded ||
                        prev.successMessage != next.successMessage ||
                        prev.errorMessage != next.errorMessage),
                listener: (ctx, state) {
                  if (state is GiftsLoaded) {
                    final messenger = ScaffoldMessenger.of(ctx);
                    if (state.successMessage != null) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text(state.successMessage!),
                          backgroundColor: scheme.primary,
                          behavior: SnackBarBehavior.floating,
                        ));
                    }
                    if (state.errorMessage != null) {
                      messenger
                        ..hideCurrentSnackBar()
                        ..showSnackBar(SnackBar(
                          content: Text(state.errorMessage!),
                          backgroundColor: scheme.error,
                          behavior: SnackBarBehavior.floating,
                        ));
                    }
                  }
                },
                builder: (ctx, state) {
                  final width = MediaQuery.sizeOf(ctx).width;
                  final metrics = GiftsLayoutMetrics(getGiftsDeviceType(width));
                  final pad = metrics.pageHorizontalPadding;
                  final isLoaded = state is GiftsLoaded;
                  final loaded = isLoaded ? state : null;

                  return CustomScrollView(
                    controller: _scrollController,
                    slivers: [
                      GiftsSliverHeader(
                        theme: theme,
                        isLoading: state is GiftsLoading,
                        showViewToggle: isLoaded,
                        canAdd: isLoaded,
                        onAdd: () => showCreateGiftDialog(ctx),
                        onRefresh: () =>
                            ctx.read<GiftsBloc>().add(LoadAdminGiftsEvent()),
                      ),
                      if (loaded != null) ...[
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: GiftsFilterBarDelegate(
                            selectedTab: loaded.selectedTab,
                            selectedSort: loaded.selectedSort,
                            searchQuery: loaded.searchQuery,
                            fromDate: loaded.fromDate,
                            toDate: loaded.toDate,
                            minPrice: loaded.minPriceFilter,
                            maxPrice: loaded.maxPriceFilter,
                            theme: theme,
                            displayedCount: loaded.displayed.length,
                            totalCount: loaded.gifts.length,
                            hasActiveFilters: loaded.hasActiveFilters,
                            screenWidth: width,
                          ),
                        ),
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(
                            pad,
                            metrics.isMobile ? 6 : 10,
                            pad,
                            0,
                          ),
                          sliver: const SliverToBoxAdapter(
                            child: GiftsBulkSelectionToolbar(),
                          ),
                        ),
                        const _GiftsPageGridSliver(),
                        if (metrics.useDesktopPagination &&
                            loaded.giftsTotalCount > 0)
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(
                                pad,
                                metrics.isMobile ? 10 : 14,
                                pad,
                                0,
                              ),
                              child: AppPaginationBar(
                                currentPage: loaded.currentPage,
                                lastPage: loaded.lastPage,
                                total: loaded.giftsTotalCount,
                                pageSize: GiftsBloc.pageLimit,
                                itemCount: loaded
                                    .pagedDisplayed(infiniteScroll: false)
                                    .length,
                                hideWhenSinglePage: false,
                                borderRadius: BorderRadius.circular(12),
                                onPageChanged: (page) => ctx
                                    .read<GiftsBloc>()
                                    .add(GoToGiftsPageEvent(page)),
                              ),
                            ),
                          ),
                      ] else if (state is GiftsLoading) ...[
                        const GiftsSliverSkeletons(),
                      ] else if (state is GiftsError) ...[
                        GiftsSliverError(message: state.message),
                      ],
                      SliverToBoxAdapter(
                        child: SizedBox(height: metrics.isMobile ? 40 : 56),
                      ),
                    ],
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

class _GiftsPageGridSliver extends StatelessWidget {
  const _GiftsPageGridSliver();

  @override
  Widget build(BuildContext context) {
    return GiftsGridSliver(onPreviewGift: showGiftPreviewDialog);
  }
}
