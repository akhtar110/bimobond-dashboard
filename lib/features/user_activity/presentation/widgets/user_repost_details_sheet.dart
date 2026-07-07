import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../../post_management/data/mappers/managed_post_mapper.dart';
import '../../../post_management/domain/entities/activity_context.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../../users/domain/entities/user_post_entity.dart';
import '../../domain/entities/user_repost_entity.dart';
import '../utils/activity_navigation.dart';

Future<void> showUserRepostDetailsSheet(
  BuildContext context, {
  required UserRepostEntity repost,
  required bool isDark,
  UserEntity? sourceUser,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => UserRepostDetailsSheet(
      repost: repost,
      isDark: isDark,
      sourceUser: sourceUser,
      onViewOriginalPost: () async {
        Navigator.of(sheetContext).pop();
        await openOriginalRepostPost(
          context,
          repost: repost,
          sourceUser: sourceUser,
        );
      },
    ),
  );
}

Future<void> openOriginalRepostPost(
  BuildContext context, {
  required UserRepostEntity repost,
  UserEntity? sourceUser,
}) {
  final post = repost.post;
  return openPostInvestigation(
    context,
    postId: post.id,
    post: managedPostFromUserPost(
      post,
      author: resolveProfileUserAsPostOwner(post, sourceUser),
    ),
    sourceUser: sourceUser,
    activityContext: ActivityContext.post(
      activityDate: repost.repostedAt ?? post.createdAt,
    ),
  );
}

bool isLikelyUserId(String value) {
  if (value.isEmpty) return true;
  return RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  ).hasMatch(value);
}

RepostedByEntity? resolveReposter({
  required UserRepostEntity repost,
  UserEntity? sourceUser,
}) {
  final api = repost.repostedBy;
  if (sourceUser != null &&
      (api == null ||
          api.id.isEmpty ||
          api.id == sourceUser.id ||
          api.username.isEmpty ||
          isLikelyUserId(api.username) ||
          api.username == api.id)) {
    return RepostedByEntity(
      id: sourceUser.id,
      username: sourceUser.username,
      fullName: sourceUser.fullName,
      avatarUrl: sourceUser.avatarUrl,
      isVerified: sourceUser.isVerified,
      repostedAt: repost.repostedAt,
    );
  }

  if (api != null &&
      api.username.isNotEmpty &&
      !isLikelyUserId(api.username)) {
    return api;
  }

  return api;
}

String repostMediaUrl(UserPostEntity post) {
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

String formatRepostEngagement(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
  return '$n';
}

class UserRepostDetailsSheet extends StatelessWidget {
  const UserRepostDetailsSheet({
    super.key,
    required this.repost,
    required this.isDark,
    required this.sourceUser,
    required this.onViewOriginalPost,
  });

  final UserRepostEntity repost;
  final bool isDark;
  final UserEntity? sourceUser;
  final VoidCallback onViewOriginalPost;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final post = repost.post;
    final reposter = resolveReposter(repost: repost, sourceUser: sourceUser);
    final mediaUrl = repostMediaUrl(post);
    final postUser = post.user;
    final authorUsername = postUser?['username']?.toString();
    final authorFullName = postUser?['fullName']?.toString();
    final authorAvatar = postUser?['avatarUrl']?.toString();

    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(Icons.repeat_rounded, color: scheme.primary, size: 22),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.tOr('repostDetails', 'Repost Details'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    if (reposter != null)
                      ReposterProfileCard(
                        reposter: reposter,
                        profileUser: sourceUser?.id == reposter.id
                            ? sourceUser
                            : null,
                        repostedAt: repost.repostedAt,
                        isDark: isDark,
                      ),
                    if (repost.quote?.isNotEmpty == true) ...[
                      const SizedBox(height: 16),
                      Text(
                        l10n.tOr('repostQuote', 'Quote'),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          '"${repost.quote}"',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      l10n.tOr('originalPost', 'Original Post'),
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (mediaUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 88,
                                height: 100,
                                child: CachedNetworkImage(
                                  imageUrl: mediaUrl,
                                  fit: BoxFit.cover,
                                  errorWidget: (_, __, ___) => ColoredBox(
                                    color: scheme.surfaceContainerHighest,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              width: 88,
                              height: 100,
                              decoration: BoxDecoration(
                                color: scheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.videocam_outlined,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (authorUsername != null) ...[
                                  Row(
                                    children: [
                                      RepostAvatar(
                                        url: authorAvatar,
                                        size: 14,
                                        fallback: authorUsername,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          authorFullName ?? '@$authorUsername',
                                          style: theme.textTheme.labelMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                ],
                                if (post.description?.isNotEmpty == true)
                                  Text(
                                    post.description!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      height: 1.35,
                                    ),
                                  ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 10,
                                  runSpacing: 6,
                                  children: [
                                    RepostStatBadge(
                                      icon: Icons.favorite_rounded,
                                      label: formatRepostEngagement(
                                        post.likeCount,
                                      ),
                                      color: scheme.error,
                                    ),
                                    RepostStatBadge(
                                      icon: Icons.comment_rounded,
                                      label: formatRepostEngagement(
                                        post.commentCount,
                                      ),
                                      color: scheme.primary,
                                    ),
                                    RepostStatBadge(
                                      icon: Icons.visibility_outlined,
                                      label: formatRepostEngagement(
                                        post.viewCount,
                                      ),
                                      color: scheme.secondary,
                                    ),
                                  ],
                                ),
                                if (post.status != 'PUBLISHED') ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: scheme.errorContainer,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      post.status,
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: scheme.onErrorContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: onViewOriginalPost,
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        l10n.tOr('viewOriginalPost', 'View Original Post'),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ReposterProfileCard extends StatelessWidget {
  const ReposterProfileCard({
    super.key,
    required this.reposter,
    required this.isDark,
    this.profileUser,
    this.repostedAt,
  });

  final RepostedByEntity reposter;
  final UserEntity? profileUser;
  final DateTime? repostedAt;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final displayName = reposter.fullName?.isNotEmpty == true
        ? reposter.fullName!
        : reposter.username;
    final statsUser = profileUser;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.tOr('repostedByUser', 'Reposted by'),
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RepostAvatar(
                url: reposter.avatarUrl,
                size: 24,
                fallback: reposter.username,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: scheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (reposter.isVerified)
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: scheme.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '@${reposter.username}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (profileUser?.email?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        profileUser!.email!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (profileUser?.bio?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        profileUser!.bio!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                        ),
                      ),
                    ],
                    if (statsUser != null) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          RepostStatBadge(
                            icon: Icons.people_outline_rounded,
                            label: formatRepostEngagement(
                              statsUser.followerCount,
                            ),
                            color: scheme.primary,
                          ),
                          RepostStatBadge(
                            icon: Icons.person_add_outlined,
                            label: formatRepostEngagement(
                              statsUser.followingCount,
                            ),
                            color: scheme.tertiary,
                          ),
                          RepostStatBadge(
                            icon: Icons.grid_view_rounded,
                            label: formatRepostEngagement(statsUser.postCount),
                            color: scheme.secondary,
                          ),
                        ],
                      ),
                    ],
                    if (repostedAt != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        '${l10n.tOr('repostedOn', 'Reposted on')} '
                        '${DateFormat('MMM d, yyyy · HH:mm').format(repostedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RepostAvatar extends StatelessWidget {
  const RepostAvatar({
    super.key,
    required this.url,
    required this.size,
    required this.fallback,
  });

  final String? url;
  final double size;
  final String fallback;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final resolved = resolveMediaUrl(url);
    return CircleAvatar(
      radius: size,
      backgroundColor: scheme.primaryContainer,
      backgroundImage: resolved != null ? NetworkImage(resolved) : null,
      child: resolved == null
          ? Text(
              fallback.isNotEmpty ? fallback[0].toUpperCase() : '?',
              style: TextStyle(fontSize: size * 0.7),
            )
          : null,
    );
  }
}

class RepostStatBadge extends StatelessWidget {
  const RepostStatBadge({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withValues(alpha: 0.7)),
        const SizedBox(width: 3),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}
