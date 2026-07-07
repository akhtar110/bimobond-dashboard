import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/user_repost_entity.dart';
import '../bloc/user_activity_bloc.dart';
import 'activity_empty_state.dart';
import 'user_activity_shimmer.dart';
import '../utils/user_repost_delete.dart';
import 'user_repost_details_sheet.dart';

class UserActivityRepostsTab extends StatefulWidget {
  const UserActivityRepostsTab({
    super.key,
    required this.userId,
    required this.isDark,
    this.sourceUser,
  });

  final String userId;
  final bool isDark;
  final UserEntity? sourceUser;

  @override
  State<UserActivityRepostsTab> createState() =>
      _UserActivityRepostsTabState();
}

class _UserActivityRepostsTabState extends State<UserActivityRepostsTab> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Lazy-load on first tab activation.
    final state = context.read<UserActivityBloc>().state;
    if (!state.repostsLoaded) {
      context.read<UserActivityBloc>().add(LoadReposts());
    }
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
    if (state.repostsHasReachedMax || state.repostsLoadingMore) return;
    bloc.add(LoadMoreReposts());
  }

  Future<void> _showRepostDetailsSheet(UserRepostEntity repost) async {
    await showUserRepostDetailsSheet(
      context,
      repost: repost,
      isDark: widget.isDark,
      sourceUser: widget.sourceUser,
    );
    if (!context.mounted) return;
    context.read<UserActivityBloc>().add(LoadReposts());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return BlocBuilder<UserActivityBloc, UserActivityState>(
      buildWhen: (a, b) =>
          a.reposts != b.reposts ||
          a.repostsLoading != b.repostsLoading ||
          a.repostsLoadingMore != b.repostsLoadingMore ||
          a.repostsHasReachedMax != b.repostsHasReachedMax ||
          a.repostsError != b.repostsError,
      builder: (context, state) {
        if (state.repostsLoading && state.reposts.isEmpty) {
          return UserActivityPostsGridShimmer(isDark: widget.isDark);
        }

        if (state.repostsError != null && state.reposts.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline_rounded,
                    size: 48,
                    color: theme.colorScheme.error.withValues(alpha: 0.6)),
                const SizedBox(height: 12),
                Text(
                  state.repostsError!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () =>
                      context.read<UserActivityBloc>().add(LoadReposts()),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (state.reposts.isEmpty) {
          return ActivityEmptyState(
            icon: Icons.repeat_rounded,
            message: context.l10n.t('noRepostsYet'),
            isDark: widget.isDark,
          );
        }

        final count = state.repostsTotal > 0
            ? state.repostsTotal
            : state.reposts.length;

        return CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Repost Activity',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                      ),
                    ),
                    Text(
                      '$count repost${count == 1 ? '' : 's'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List of repost cards
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                MediaQuery.sizeOf(context).width < 720 ? 8 : 12,
                0,
                MediaQuery.sizeOf(context).width < 720 ? 8 : 12,
                12,
              ),
              sliver: SliverList.separated(
                itemCount: state.reposts.length,
                separatorBuilder: (context, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final repost = state.reposts[index];
                  final repostId = repost.repostId ?? '';
                  return _RepostCard(
                    repost: repost,
                    isDark: widget.isDark,
                    sourceUser: widget.sourceUser,
                    isDeleting: state.deletingRepostId == repostId,
                    onDelete: repostId.isEmpty
                        ? null
                        : () => confirmAndDeleteUserRepost(context, repostId),
                    onTap: () => _showRepostDetailsSheet(repost),
                  );
                },
              ),
            ),

            if (state.repostsLoadingMore)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),

            if (state.repostsHasReachedMax && state.reposts.isNotEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'All reposts loaded',
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

// ──────────────────────────────────────────────────────────
// Repost card
// ──────────────────────────────────────────────────────────

class _RepostCard extends StatefulWidget {
  const _RepostCard({
    required this.repost,
    required this.isDark,
    this.sourceUser,
    required this.onTap,
    this.onDelete,
    this.isDeleting = false,
  });

  final UserRepostEntity repost;
  final bool isDark;
  final UserEntity? sourceUser;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final bool isDeleting;

  @override
  State<_RepostCard> createState() => _RepostCardState();
}

class _RepostCardState extends State<_RepostCard> {
  bool _hovered = false;

  String get _mediaUrl {
    final post = widget.repost.post;
    final mediaList = post.media;
    if (mediaList != null) {
      for (final item in mediaList) {
        final type = (item['mediaType'] as String? ?? '').toUpperCase();
        if (type == 'IMAGE') {
          final url = resolveMediaUrl(item['url']?.toString());
          if (url != null && url.isNotEmpty) return url;
        }
      }
    }
    final thumb = resolveMediaUrl(post.thumbnailUrl);
    if (thumb != null && thumb.isNotEmpty) return thumb;
    final animated = resolveMediaUrl(post.animatedCoverUrl);
    if (animated != null && animated.isNotEmpty) return animated;
    return resolveMediaUrl(post.videoUrl) ?? '';
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final post = widget.repost.post;
    final reposter = resolveReposter(
      repost: widget.repost,
      sourceUser: widget.sourceUser,
    );
    final mediaUrl = _mediaUrl;

    final cardBg = scheme.surface;
    final borderColor = scheme.outlineVariant;

    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < 720;
    final isNarrow = width < 520;
    final hasDelete = widget.onDelete != null;
    final cardPadding = isCompact ? 12.0 : 14.0;
    final actionInset = isCompact ? 10.0 : 14.0;
    final actionGap = isCompact ? 6.0 : 8.0;
    final topActionsReserve = hasDelete
        ? (isNarrow ? 118.0 : (isCompact ? 132.0 : 148.0))
        : (isNarrow ? 36.0 : (isCompact ? 96.0 : 112.0));
    final mediaSize = isNarrow
        ? const Size(double.infinity, 140.0)
        : Size(isCompact ? 72.0 : 80.0, isCompact ? 82.0 : 90.0);

    Widget mediaPreview;
    if (mediaUrl.isNotEmpty) {
      mediaPreview = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: mediaSize.width,
          height: mediaSize.height,
          child: CachedNetworkImage(
            imageUrl: mediaUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            errorWidget: (context, url, err) => ColoredBox(
              color: scheme.surfaceContainerHighest,
              child: Icon(
                Icons.broken_image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    } else {
      mediaPreview = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: mediaSize.width,
          height: mediaSize.height,
          color: scheme.surfaceContainerHighest,
          child: Icon(
            Icons.repeat_rounded,
            size: 32,
            color: scheme.primary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final contentColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.repeat_rounded, size: 14, color: scheme.primary),
            const SizedBox(width: 4),
            if (reposter != null) ...[
              RepostAvatar(
                url: reposter.avatarUrl,
                size: 16,
                fallback: reposter.username,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  reposter.fullName?.isNotEmpty == true
                      ? reposter.fullName!
                      : '@${reposter.username}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (reposter.isVerified) ...[
                const SizedBox(width: 3),
                Icon(Icons.verified_rounded, size: 11, color: scheme.primary),
              ],
              const SizedBox(width: 4),
              Text(
                'reposted',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ] else
              Text(
                'Reposted',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            const Spacer(),
            if (widget.repost.repostedAt != null)
              Text(
                _formatDate(widget.repost.repostedAt!),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
          ],
        ),
        if (widget.repost.quote?.isNotEmpty == true) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: scheme.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Text(
              '"${widget.repost.quote}"',
              style: theme.textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: scheme.onPrimaryContainer,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        const SizedBox(height: 8),
        if (post.description?.isNotEmpty == true)
          Text(
            post.description!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        const SizedBox(height: 8),
        if (post.status != 'PUBLISHED')
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.errorContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              post.status,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onErrorContainer,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        if (post.status != 'PUBLISHED') const SizedBox(height: 8),
        Wrap(
          spacing: isCompact ? 8 : 12,
          runSpacing: 4,
          children: [
            RepostStatBadge(
              icon: Icons.favorite_rounded,
              label: _fmt(post.likeCount),
              color: scheme.error,
            ),
            RepostStatBadge(
              icon: Icons.comment_rounded,
              label: _fmt(post.commentCount),
              color: scheme.primary,
            ),
            RepostStatBadge(
              icon: Icons.bookmark_rounded,
              label: _fmt(post.saveCount),
              color: scheme.secondary,
            ),
            RepostStatBadge(
              icon: Icons.repeat_rounded,
              label: _fmt(
                (post.counts?['reposts'] as num?)?.toInt() ?? 0,
              ),
              color: scheme.tertiary,
            ),
          ],
        ),
      ],
    );

    final deleteButton = widget.isDeleting
        ? SizedBox(
            width: 28,
            height: 28,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: scheme.error,
                ),
              ),
            ),
          )
        : Material(
            color: cardBg.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(8),
            child: IconButton(
              tooltip: context.l10n.t('delete'),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              icon: Icon(
                Icons.delete_outline_rounded,
                size: 18,
                color: scheme.error,
              ),
              onPressed: widget.onDelete,
            ),
          );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered
                  ? scheme.primary.withValues(alpha: 0.4)
                  : borderColor,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? scheme.primary.withValues(alpha: 0.08)
                    : scheme.shadow.withValues(alpha: 0.04),
                blurRadius: _hovered ? 16 : 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                  cardPadding,
                  cardPadding,
                  cardPadding + topActionsReserve,
                  cardPadding,
                ),
                child: isNarrow
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mediaPreview,
                          const SizedBox(height: 12),
                          contentColumn,
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          mediaPreview,
                          SizedBox(width: isCompact ? 12 : 14),
                          Expanded(child: contentColumn),
                        ],
                      ),
              ),
              Positioned(
                top: actionInset,
                right: actionInset,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IgnorePointer(
                      ignoring: !_hovered,
                      child: AnimatedOpacity(
                        opacity: _hovered ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: _ViewDetailsChip(
                          isDark: widget.isDark,
                          scheme: scheme,
                          theme: theme,
                          isCompact: isCompact,
                          isNarrow: isNarrow,
                        ),
                      ),
                    ),
                    if (hasDelete) ...[
                      SizedBox(width: actionGap),
                      deleteButton,
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return DateFormat.jm().format(dt);
    }
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }
}

class _ViewDetailsChip extends StatelessWidget {
  const _ViewDetailsChip({
    required this.isDark,
    required this.scheme,
    required this.theme,
    this.isCompact = false,
    this.isNarrow = false,
  });

  final bool isDark;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool isCompact;
  final bool isNarrow;

  @override
  Widget build(BuildContext context) {
    final label = context.l10n.t('viewDetails');
    final chip = Container(
      height: 28,
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 6 : (isCompact ? 8 : 10),
      ),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.visibility_outlined,
            size: isCompact ? 13 : 14,
            color: scheme.onPrimaryContainer,
          ),
          if (!isNarrow) ...[
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onPrimaryContainer,
                fontSize: isCompact ? 11 : null,
              ),
            ),
          ],
        ],
      ),
    );

    if (isNarrow) {
      return Tooltip(message: label, child: chip);
    }
    return chip;
  }
}
