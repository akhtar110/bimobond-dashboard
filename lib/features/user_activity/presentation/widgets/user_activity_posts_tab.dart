import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../categories/presentation/bloc/categories_bloc.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../bloc/user_activity_bloc.dart';
import '../utils/activity_navigation.dart';
import 'activity_empty_state.dart';
import 'user_activity_shimmer.dart';

class UserActivityPostsTab extends StatefulWidget {
  const UserActivityPostsTab({
    super.key,
    required this.userId,
    required this.isDark,
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityPostsTab> createState() => _UserActivityPostsTabState();
}

class _UserActivityPostsTabState extends State<UserActivityPostsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CategoriesBloc>().add(LoadCategoriesEvent(forCatalog: true));
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;

    final bloc = context.read<UserActivityBloc>();
    final state = bloc.state;
    if (state.postsHasReachedMax || state.postsLoadingMore) return;
    bloc.add(LoadMorePosts());
  }

  Future<void> _openPost(UserPostEntity post) async {
    await openPostInvestigation(
      context,
      postId: post.id,
      post: managedPostFromUserPost(
        post,
        author: resolveProfileUserAsPostOwner(post, widget.sourceUser),
      ),
      sourceUser: widget.sourceUser,
      activityContext: ActivityContext.post(activityDate: post.createdAt),
    );
    if (!context.mounted) return;
    context.read<UserActivityBloc>().add(LoadPosts());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;

    return BlocBuilder<UserActivityBloc, UserActivityState>(
      builder: (context, state) {
        if (state.postsLoading && state.posts.isEmpty) {
          return UserActivityPostsGridShimmer(isDark: widget.isDark);
        }

        if (state.postsError != null && state.posts.isEmpty) {
          return Center(child: Text(state.postsError!));
        }

        if (state.posts.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.video_library_outlined,
            message: l10n.t('noPostsYet'),
            isDark: widget.isDark,
          );
        }

        final postCount =
            state.postsTotal > 0 ? state.postsTotal : state.posts.length;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.t('publishedPosts'),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                        Text(
                          context.tr('postsCountSummary', {
                            'count': '$postCount',
                          }),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.t('tapPostAdminHint'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              sliver: SliverLayoutBuilder(
                builder: (context, constraints) {
                  var crossAxisCount = 4;
                  final width = constraints.crossAxisExtent;
                  if (width < 400) {
                    crossAxisCount = 2;
                  } else if (width < 700) {
                    crossAxisCount = 3;
                  }

                  return SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final post = state.posts[index];
                        return _PostGridTile(
                          post: post,
                          isDark: widget.isDark,
                          onTap: () => _openPost(post),
                        );
                      },
                      childCount: state.posts.length,
                    ),
                  );
                },
              ),
            ),
            if (state.postsLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
            if (state.postsHasReachedMax && state.posts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      l10n.t('allPostsLoaded'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PostGridTile extends StatefulWidget {
  const _PostGridTile({
    required this.post,
    required this.isDark,
    required this.onTap,
  });

  final UserPostEntity post;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<_PostGridTile> createState() => _PostGridTileState();
}

class _PostGridTileState extends State<_PostGridTile> {
  bool _hovered = false;

  String get _mediaUrl {
    // 1. Check the media list for the first IMAGE item (covers IMAGE/CAROUSEL posts).
    final mediaList = widget.post.media;
    if (mediaList != null) {
      for (final item in mediaList) {
        final type = (item['mediaType'] as String? ?? '').toUpperCase();
        if (type == 'IMAGE') {
          final url = resolveMediaUrl(item['url']?.toString());
          if (url != null && url.isNotEmpty) return url;
        }
      }
    }

    // 2. Fall back to thumbnailUrl → animatedCoverUrl → videoUrl.
    final thumb = resolveMediaUrl(widget.post.thumbnailUrl);
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final animated = resolveMediaUrl(widget.post.animatedCoverUrl);
    if (animated != null && animated.isNotEmpty) return animated;
    return resolveMediaUrl(widget.post.videoUrl) ?? '';
  }

  String _formatCount(int value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}k';
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final post = widget.post;
    final mediaUrl = _mediaUrl;
    final resolvedVideoUrl = resolveMediaUrl(post.videoUrl);
    final useVideoPlayer =
        (post.thumbnailUrl == null || post.thumbnailUrl!.isEmpty) &&
        resolvedVideoUrl != null &&
        resolvedVideoUrl.isNotEmpty;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned.fill(
                child: useVideoPlayer
                    ? _VideoThumbnailWidget(videoUrl: resolvedVideoUrl!)
                    : (mediaUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: mediaUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => ColoredBox(
                                color: scheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image_outlined,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : ColoredBox(
                              color: scheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.videocam_off_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            )),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      scheme.scrim.withValues(alpha: 0.65),
                    ],
                  ),
                ),
              ),
              if (post.status != 'PUBLISHED')
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.inverseSurface.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.status,
                      style: TextStyle(
                        color: scheme.onInverseSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: scheme.onInverseSurface,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(post.viewCount),
                      style: TextStyle(
                        color: scheme.onInverseSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hovered)
                Container(
                  color: scheme.scrim.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surface.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: scheme.onSurface,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.t('manage'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
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

class _VideoThumbnailWidget extends StatefulWidget {
  const _VideoThumbnailWidget({required this.videoUrl});

  final String videoUrl;

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller.setLooping(true);
        _controller.setVolume(0);
        _controller.play();
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<VideoPlayerValue>(
      valueListenable: _controller,
      builder: (context, value, _) {
        if (!value.isInitialized) {
          final scheme = Theme.of(context).colorScheme;
          return ColoredBox(
            color: scheme.surfaceContainerHighest,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        return FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: value.size.width,
            height: value.size.height,
            child: VideoPlayer(_controller),
          ),
        );
      },
    );
  }
}
