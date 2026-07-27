import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/persistent_bloc_provider.dart';
import '../../../../features/categories/presentation/bloc/categories_bloc.dart';
import '../../../../features/post_management/domain/entities/managed_post_author_enrichment.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../../../features/post_management/presentation/utils/post_management_navigation.dart';
import '../../../../injection_container.dart' as di;
import '../bloc/posts_bloc.dart';
import '../utils/posts_page_refresh.dart';
import '../utils/posts_responsive.dart';
import '../widgets/bulk_selection_toolbar.dart';
import '../widgets/posts_category_filter.dart';
import '../widgets/posts_content.dart';
import '../widgets/posts_keyboard_intents.dart';
import '../widgets/posts_page_header.dart';
import '../widgets/posts_page_states.dart';
import '../widgets/posts_skeleton_grid.dart';

class PostsPage extends StatelessWidget {
  const PostsPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('PostsPage rebuilt');
    return PersistentBlocProvider<PostsBloc>(
      debugLabel: 'PostsPage',
      create: () {
        if (kDebugMode) debugPrint('GetAllPosts dispatched');
        return di.sl<PostsBloc>()..add(GetAllPostsEvent());
      },
      child: PersistentBlocProvider<CategoriesBloc>(
        debugLabel: 'PostsPage/Categories',
        create: () => di.sl<CategoriesBloc>()
          ..add(LoadCategoriesEvent(forCatalog: true)),
        child: const _PostsPageView(),
      ),
    );
  }
}

class _PostsPageView extends StatefulWidget {
  const _PostsPageView();

  @override
  State<_PostsPageView> createState() => _PostsPageViewState();
}

class _PostsPageViewState extends State<_PostsPageView> {
  final _scrollController = ScrollController();
  bool _refreshScopeRegistered = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_refreshScopeRegistered) {
      _refreshScopeRegistered = true;
      PostsPageRefreshScope.register(_refreshFeed);
    }
  }

  @override
  void dispose() {
    PostsPageRefreshScope.unregister(_refreshFeed);
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshFeed() {
    if (!mounted) return;
    refreshPostsPageFeed(context);
  }

  void _onScroll() {
    if (!mounted || !_scrollController.hasClients) return;

    final width = MediaQuery.sizeOf(context).width;
    final metrics = PostsLayoutMetrics(getPostsDeviceType(width));
    if (!metrics.useInfiniteScroll) return;

    final position = _scrollController.position;
    if (!position.hasContentDimensions || position.maxScrollExtent <= 0) {
      return;
    }
    if (position.pixels >= position.maxScrollExtent - 300) {
      context.read<PostsBloc>().add(LoadMorePostsEvent());
    }
  }

  void _openPostManagement(ManagedPostEntity post) {
    navigateToPostManagementFromFeed(
      context,
      post: post,
      onResult: (result, listBaseline) {
        if (!mounted) return;
        if (result.deleted) {
          context.read<PostsBloc>().add(RemovePostEvent(post.id));
          refreshPostsPageFeed(context);
        } else if (result.post != null) {
          context.read<PostsBloc>().add(
                PatchPostEvent(
                  mergeManagedPostForListDisplay(listBaseline, result.post!),
                ),
              );
          refreshPostsPageFeed(context);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Shortcuts(
      shortcuts: {
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyA):
            const SelectAllPostsIntent(),
        LogicalKeySet(LogicalKeyboardKey.escape): const ClearSelectionIntent(),
      },
      child: Actions(
        actions: {
          SelectAllPostsIntent: CallbackAction<SelectAllPostsIntent>(
            onInvoke: (_) {
              context.read<PostsBloc>().add(SelectAllPostsEvent());
              return null;
            },
          ),
          ClearSelectionIntent: CallbackAction<ClearSelectionIntent>(
            onInvoke: (_) {
              context.read<PostsBloc>().add(ClearSelectionEvent());
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: BlocListener<PostsBloc, PostsState>(
            listenWhen: (prev, next) =>
                next is PostsLoaded &&
                next.bulkActionMessage != null &&
                (prev is! PostsLoaded ||
                    prev.bulkActionMessage != next.bulkActionMessage),
            listener: (context, state) {
              if (state is! PostsLoaded || state.bulkActionMessage == null) {
                return;
              }
              final messenger = ScaffoldMessenger.of(context);
              messenger.hideCurrentSnackBar();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.bulkActionMessage!),
                  backgroundColor:
                      state.bulkActionIsError ? Colors.red.shade700 : null,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              context.read<PostsBloc>().add(ClearBulkActionFeedbackEvent());
            },
            child: Container(
              color: scheme.surfaceContainerLowest,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1680),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final metrics = PostsLayoutMetrics(
                        getPostsDeviceType(constraints.maxWidth),
                      );
                      return Padding(
                        padding: EdgeInsetsDirectional.fromSTEB(
                          metrics.pageHorizontalPadding,
                          metrics.isMobile ? 6 : 8,
                          metrics.pageHorizontalPadding,
                          metrics.isMobile ? 10 : 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            PostsPageHeader(metrics: metrics),
                            SizedBox(height: metrics.isMobile ? 6 : 8),
                            PostsCategoryFilter(metrics: metrics),
                            SizedBox(height: metrics.filterGap),
                            const BulkSelectionToolbar(),
                            SizedBox(height: metrics.isMobile ? 6 : 8),
                            Expanded(
                              child: BlocBuilder<PostsBloc, PostsState>(
                                buildWhen: (prev, next) =>
                                    prev.runtimeType != next.runtimeType ||
                                    (prev is PostsLoaded &&
                                        next is PostsLoaded &&
                                        (prev.posts != next.posts ||
                                            prev.viewType != next.viewType ||
                                            prev.selectedPostIds !=
                                                next.selectedPostIds ||
                                            prev.isLoadingMore !=
                                                next.isLoadingMore ||
                                            prev.isApplyingFilters !=
                                                next.isApplyingFilters ||
                                            prev.currentPage !=
                                                next.currentPage ||
                                            prev.lastPage != next.lastPage ||
                                            prev.total != next.total ||
                                            prev.isPerformingBulkAction !=
                                                next.isPerformingBulkAction)),
                                builder: (context, state) => switch (state) {
                                  PostsInitial() || PostsLoading() =>
                                    LayoutBuilder(
                                      builder: (ctx, c) =>
                                          PostsSkeletonGrid(width: c.maxWidth),
                                    ),
                                  PostsEmpty() => PostsEmptyView(
                                      onClearFilters: () => context
                                          .read<PostsBloc>()
                                          .add(ClearPostFiltersEvent()),
                                    ),
                                  PostsError(:final message) => PostsErrorView(
                                      message: message,
                                      onRetry: () => context
                                          .read<PostsBloc>()
                                          .add(GetAllPostsEvent()),
                                    ),
                                  PostsLoaded() => PostsContent(
                                      state: state,
                                      scrollController: _scrollController,
                                      onPostTap: _openPostManagement,
                                    ),
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
