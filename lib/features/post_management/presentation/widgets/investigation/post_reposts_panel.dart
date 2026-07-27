import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../users/domain/entities/user_entity.dart';
import '../../../domain/entities/post_engagement_user_item.dart';
import '../../bloc/post_management_bloc.dart';
import 'investigation_theme.dart';

/// Displays reposters from the post engagement API (with seed from recentReposts).
class PostRepostsPanel extends StatefulWidget {
  const PostRepostsPanel({
    super.key,
    required this.totalCount,
  });

  final int totalCount;

  @override
  State<PostRepostsPanel> createState() => _PostRepostsPanelState();
}

class _PostRepostsPanelState extends State<PostRepostsPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _reload() {
    context.read<PostManagementBloc>().add(
          LoadPostEngagementUsersEvent(PostEngagementKind.reposts),
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return BlocSelector<PostManagementBloc, PostManagementState,
        PostEngagementListState?>(
      selector: (s) =>
          s is PostManagementLoaded ? s.engagementFor(PostEngagementKind.reposts) : null,
      builder: (context, engagement) {
        if (engagement == null) return const SizedBox.shrink();

        if (engagement.isLoading && engagement.items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final reposts = engagement.items;
        final total =
            widget.totalCount > 0 ? widget.totalCount : reposts.length;

        if (reposts.isEmpty) {
          return _EmptyState(
            icon: Icons.repeat_rounded,
            message: engagement.error ??
                l10n.tOr(
                  'noPostRepostsYet',
                  "This post hasn't been reposted yet",
                ),
            subtitle: total > 0
                ? context.tr('repostsCountSummary', {'count': '$total'})
                : null,
            onRetry: engagement.error != null ? _reload : null,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: InvestigationTheme.s12),
              child: Row(
                children: [
                  Text(
                    l10n.t('reposts'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    context.tr('repostsCountSummary', {
                      'count':
                          '${reposts.length}${total > reposts.length ? ' / $total' : ''}',
                    }),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            ...reposts.map((item) {
              final username = item.username ?? '—';
              final display = item.fullName?.isNotEmpty == true
                  ? item.fullName!
                  : '@$username';

              return Padding(
                padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
                child: _RepostRow(
                  username: username,
                  fullName: item.fullName,
                  displayName: display,
                  avatarUrl: item.avatarUrl,
                  isBanned: item.isBanned,
                  isVerified: item.isVerified,
                  repostedAt: dateFormat.format(item.createdAt),
                  onViewProfile: item.userId.isNotEmpty
                      ? () => Navigator.pushNamed(
                            context,
                            AppRoutes.userDetail,
                            arguments: UserEntity(
                              id: item.userId,
                              username: username,
                              fullName: item.fullName,
                              avatarUrl: item.avatarUrl,
                              isVerified: item.isVerified,
                              isPrivate: false,
                              allowComments: true,
                              allowDirectMsgs: true,
                              language: 'en',
                              theme: 'light',
                              followerCount: 0,
                              followingCount: 0,
                              postCount: 0,
                              totalLikes: 0,
                              isBanned: item.isBanned,
                              roles: const [],
                            ),
                          )
                      : null,
                ),
              );
            }),
            if (engagement.error != null) ...[
              const SizedBox(height: InvestigationTheme.s8),
              Text(
                engagement.error!,
                style: TextStyle(fontSize: 12, color: scheme.error),
              ),
            ],
            if (engagement.hasMore) ...[
              const SizedBox(height: InvestigationTheme.s8),
              OutlinedButton.icon(
                onPressed: engagement.isLoadingMore
                    ? null
                    : () => context.read<PostManagementBloc>().add(
                          LoadMorePostEngagementUsersEvent(
                            PostEngagementKind.reposts,
                          ),
                        ),
                icon: engagement.isLoadingMore
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.expand_more_rounded, size: 18),
                label: Text(l10n.t('loadMoreComments')),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RepostRow extends StatefulWidget {
  const _RepostRow({
    required this.username,
    this.fullName,
    required this.displayName,
    this.avatarUrl,
    required this.isBanned,
    required this.isVerified,
    required this.repostedAt,
    this.onViewProfile,
  });

  final String username;
  final String? fullName;
  final String displayName;
  final String? avatarUrl;
  final bool isBanned;
  final bool isVerified;
  final String repostedAt;
  final VoidCallback? onViewProfile;

  @override
  State<_RepostRow> createState() => _RepostRowState();
}

class _RepostRowState extends State<_RepostRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final display = widget.displayName;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: InvestigationTheme.animMs),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _hovered
              ? scheme.primaryContainer.withValues(alpha: 0.25)
              : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          border: Border.all(
            color: _hovered ? scheme.primary.withValues(alpha: 0.3) : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.surfaceContainerHighest,
              backgroundImage: widget.avatarUrl != null &&
                      widget.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Text(
                      display.isNotEmpty ? display[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          display,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                      if (widget.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded, size: 13, color: scheme.primary),
                      ],
                    ],
                  ),
                  Text(
                    widget.repostedAt,
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (widget.isBanned)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: scheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  l10n.t('banned'),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: scheme.onErrorContainer,
                  ),
                ),
              ),
            if (widget.onViewProfile != null)
              IconButton(
                tooltip: l10n.t('viewProfile'),
                visualDensity: VisualDensity.compact,
                onPressed: widget.onViewProfile,
                icon: Icon(Icons.person_outline_rounded, color: scheme.primary),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.message,
    this.subtitle,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: scheme.onSurfaceVariant,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 12, color: scheme.primary),
            ),
          ],
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonal(
              onPressed: onRetry,
              child: Text(context.l10n.t('tryAgain')),
            ),
          ],
        ],
      ),
    );
  }
}
