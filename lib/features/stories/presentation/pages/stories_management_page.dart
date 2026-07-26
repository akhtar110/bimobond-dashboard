import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/widgets/state_widgets.dart';
import '../../../../injection_container.dart' as di;
import '../../../posts/presentation/utils/posts_responsive.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
import '../../../rbac/presentation/widgets/access_denied_view.dart';
import '../../domain/entities/story_entity.dart';
import '../../domain/entities/story_viewer_slide.dart';
import '../bloc/stories_bloc.dart';
import '../bloc/stories_event.dart';
import '../bloc/stories_state.dart';
import '../utils/stories_feedback.dart';
import '../widgets/stories_content.dart';
import '../widgets/stories_empty_view.dart';
import '../widgets/stories_page_header.dart';
import '../widgets/stories_skeleton.dart';
import '../widgets/story_card.dart';
import '../widgets/story_delete_dialog.dart';
import '../widgets/story_details_dialog.dart';
import '../widgets/story_edit_dialog.dart';
import '../widgets/story_viewer_dialog.dart';

const int storiesDashboardTabIndex = 6;

class StoriesManagementPage extends StatelessWidget {
  const StoriesManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    return FeatureAccessBoundary(
      canAccess: PermissionManager.canReadStories,
      child: BlocProvider(
        create: (_) => di.sl<StoriesBloc>()..add(const LoadStoriesEvent()),
        child: const _StoriesManagementView(),
      ),
    );
  }
}

class _StoriesManagementView extends StatefulWidget {
  const _StoriesManagementView();

  @override
  State<_StoriesManagementView> createState() => _StoriesManagementViewState();
}

class _StoriesManagementViewState extends State<_StoriesManagementView> {
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

    final metrics = PostsLayoutMetrics(
      getPostsDeviceType(MediaQuery.sizeOf(context).width),
    );
    if (!metrics.useInfiniteScroll) return;

    final state = context.read<StoriesBloc>().state;
    if (state is! StoriesLoaded ||
        state.hasReachedMax ||
        state.isLoadingMore) {
      return;
    }

    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    if (position.maxScrollExtent <= 0 ||
        position.pixels >= position.maxScrollExtent - 300) {
      context.read<StoriesBloc>().add(const LoadMoreStoriesEvent());
    }
  }

  void _scheduleInfiniteScrollCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _onScroll();
    });
  }

  Future<void> _handleAction(
    StoryEntity story,
    StoryCardActionType action,
    List<StoryEntity> stories,
  ) async {
    switch (action) {
      case StoryCardActionType.viewDetails:
        await showStoryDetailsDialog(
          context,
          story: story,
          onEdit: () => _handleAction(story, StoryCardActionType.edit, stories),
        );
      case StoryCardActionType.edit:
        await showStoryEditDialog(context, story: story);
      case StoryCardActionType.delete:
        await showStoryDeleteDialog(context, storyId: story.id);
    }
  }

  void _openViewer(StoryEntity story, List<StoryEntity> stories) {
    final userStories = stories
        .where((item) => item.userId == story.userId)
        .toList(growable: false);
    final slides = userStories.toViewerSlides();
    final initialIndex = userStories.indexWhere((item) => item.id == story.id);
    if (slides.isEmpty || initialIndex < 0) return;

    showStoryViewerDialog(
      context,
      stories: slides,
      initialIndex: initialIndex,
      onViewDetails: (_) async {
        await showStoryDetailsDialog(context, story: story);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BlocConsumer<StoriesBloc, StoriesState>(
      listenWhen: (prev, next) {
        if (StoriesFeedback.hasFeedback(next)) return true;
        if (next is! StoriesLoaded) return false;
        final metrics = PostsLayoutMetrics(
          getPostsDeviceType(MediaQuery.sizeOf(context).width),
        );
        if (!metrics.useInfiniteScroll) return false;
        return prev is! StoriesLoaded ||
            prev.stories.length != next.stories.length ||
            prev.currentPage != next.currentPage ||
            prev.isApplyingFilters != next.isApplyingFilters;
      },
      listener: (context, state) {
        if (StoriesFeedback.hasFeedback(state)) {
          StoriesFeedback.showSnackBar(context, state);
          context.read<StoriesBloc>().add(const ClearStoriesFeedbackEvent());
          return;
        }

        if (state is StoriesLoaded) {
          _scheduleInfiniteScrollCheck();
        }
      },
      builder: (context, state) {
        return Container(
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
                      metrics.isMobile ? 8 : 12,
                      metrics.pageHorizontalPadding,
                      metrics.isMobile ? 12 : 16,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        StoriesPageHeader(metrics: metrics),
                        SizedBox(height: metrics.sectionGap),
                        Expanded(
                          child: BlocBuilder<StoriesBloc, StoriesState>(
                            buildWhen: (prev, next) =>
                                prev.runtimeType != next.runtimeType ||
                                (prev is StoriesLoaded &&
                                    next is StoriesLoaded &&
                                    (prev.stories != next.stories ||
                                        prev.useGridView != next.useGridView ||
                                        prev.isLoadingMore !=
                                            next.isLoadingMore ||
                                        prev.isApplyingFilters !=
                                            next.isApplyingFilters ||
                                        prev.isRefreshing != next.isRefreshing ||
                                        prev.currentPage != next.currentPage ||
                                        prev.totalPages != next.totalPages ||
                                        prev.total != next.total)),
                            builder: (context, state) => switch (state) {
                              StoriesInitial() || StoriesLoading() =>
                                SingleChildScrollView(
                                  child: StoriesSkeletonGrid(),
                                ),
                              StoriesEmpty() => StoriesEmptyView(
                                  onClearFilters: () => context
                                      .read<StoriesBloc>()
                                      .add(const ClearStoriesFiltersEvent()),
                                ),
                              StoriesError(:final message) => ErrorView(
                                  message: message,
                                  retryLabel: context.l10n.tOr('retry', 'Retry'),
                                  onRetry: () => context
                                      .read<StoriesBloc>()
                                      .add(const LoadStoriesEvent()),
                                ),
                              StoriesLoaded() => StoriesContent(
                                  state: state,
                                  scrollController: _scrollController,
                                  onStoryTap: (story) =>
                                      _openViewer(story, state.stories),
                                  onStoryAction: (story, action) =>
                                      _handleAction(
                                    story,
                                    action,
                                    state.stories,
                                  ),
                                ),
                              StoriesState() => const SizedBox.shrink(),
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
        );
      },
    );
  }
}
