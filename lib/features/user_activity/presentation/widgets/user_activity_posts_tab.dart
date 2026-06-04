import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/localization/localization.dart';
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
      post: managedPostFromUserPost(post),
      sourceUser: widget.sourceUser,
      activityContext: ActivityContext.post(activityDate: post.createdAt),
    );
    if (!context.mounted) return;
    context.read<UserActivityBloc>().add(LoadPosts());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
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
                        color: widget.isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
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
                        color: widget.isDark
                            ? Colors.grey.shade500
                            : Colors.grey.shade600,
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
    final thumb = widget.post.thumbnailUrl;
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final animated = widget.post.animatedCoverUrl;
    if (animated != null && animated.isNotEmpty) return animated;
    return widget.post.videoUrl ?? '';
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
    final l10n = context.l10n;
    final post = widget.post;
    final mediaUrl = _mediaUrl;
    final useVideoPlayer =
        (post.thumbnailUrl == null || post.thumbnailUrl!.isEmpty) &&
        post.videoUrl != null &&
        post.videoUrl!.isNotEmpty;

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
                    ? _VideoThumbnailWidget(videoUrl: post.videoUrl!)
                    : (mediaUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: mediaUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => ColoredBox(
                                color: Colors.grey.shade200,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const ColoredBox(
                                color: Color(0xFFE2E8F0),
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            )
                          : const ColoredBox(
                              color: Color(0xFFE2E8F0),
                              child: Icon(Icons.videocam_off_outlined),
                            )),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.65),
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
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      post.status,
                      style: const TextStyle(
                        color: Colors.white,
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
                    const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatCount(post.viewCount),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hovered)
                Container(
                  color: Colors.black.withValues(alpha: 0.35),
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.isDark
                          ? const Color(0xFF1E293B)
                          : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: widget.isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 16,
                          color: widget.isDark
                              ? Colors.white
                              : const Color(0xFF111827),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          l10n.t('manage'),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: widget.isDark
                                ? Colors.white
                                : const Color(0xFF111827),
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
          return ColoredBox(
            color: Colors.grey.shade200,
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
