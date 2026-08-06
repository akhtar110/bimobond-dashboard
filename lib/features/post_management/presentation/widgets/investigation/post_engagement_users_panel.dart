import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../reports/presentation/utils/report_detail_labels.dart';
import '../../../../users/domain/entities/user_entity.dart';
import '../../../domain/entities/post_engagement_user_item.dart';
import '../../bloc/post_management_bloc.dart';
import 'investigation_theme.dart';

class PostEngagementUsersPanel extends StatefulWidget {
  const PostEngagementUsersPanel({
    super.key,
    required this.kind,
    required this.totalCount,
    required this.emptyMessage,
    this.subtitleLabel,
  });

  final PostEngagementKind kind;
  final int totalCount;
  final String emptyMessage;
  final String? subtitleLabel;

  @override
  State<PostEngagementUsersPanel> createState() =>
      _PostEngagementUsersPanelState();
}

class _PostEngagementUsersPanelState extends State<PostEngagementUsersPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  void _reload() {
    context.read<PostManagementBloc>().add(
          LoadPostEngagementUsersEvent(widget.kind),
        );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

    return BlocSelector<PostManagementBloc, PostManagementState,
        PostEngagementListState?>(
      selector: (s) =>
          s is PostManagementLoaded ? s.engagementFor(widget.kind) : null,
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

        if (engagement.items.isEmpty) {
          return _EmptyState(
            message: engagement.error ?? widget.emptyMessage,
            subtitle: widget.totalCount > 0 ? '${widget.totalCount}' : null,
            onRetry: _reload,
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
                    _titleFor(l10n),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '${engagement.items.length}${widget.totalCount > engagement.items.length ? ' / ${widget.totalCount}' : ''}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            ...engagement.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
                child: _UserRow(
                  item: item,
                  dateFormat: dateFormat,
                  subtitleLabel: widget.subtitleLabel,
                  showTrafficSource:
                      widget.kind == PostEngagementKind.views,
                ),
              ),
            ),
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
                          LoadMorePostEngagementUsersEvent(widget.kind),
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

  String _titleFor(AppLocalizations l10n) {
    return switch (widget.kind) {
      PostEngagementKind.likes => l10n.t('likes'),
      PostEngagementKind.views => l10n.tOr('postViews', 'Post Views'),
      PostEngagementKind.mentions => l10n.t('mentions'),
      PostEngagementKind.reposts => l10n.t('reposts'),
    };
  }
}

class _UserRow extends StatefulWidget {
  const _UserRow({
    required this.item,
    required this.dateFormat,
    this.subtitleLabel,
    this.showTrafficSource = false,
  });

  final PostEngagementUserItem item;
  final DateFormat dateFormat;
  final String? subtitleLabel;
  final bool showTrafficSource;

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  // ── Traffic source colours & icons (mirrors _TrafficBreakdownCard) ──────────
  static Color _sourceAccent(String key, ColorScheme scheme) => switch (key) {
        'FOR_YOU' => const Color(0xFF2563EB),
        'FOLLOWING' => const Color(0xFF7C3AED),
        'PROFILE' => const Color(0xFF0891B2),
        'SEARCH' => const Color(0xFFD97706),
        'HASHTAGS' => const Color(0xFF059669),
        'SHARES' => const Color(0xFFDB2777),
        'SOUND' => const Color(0xFF9333EA),
        'LIVE' => const Color(0xFFDC2626),
        'NOTIFICATION' => const Color(0xFFF59E0B),
        'SAVED' => const Color(0xFF0284C7),
        'LIKED' => const Color(0xFFE11D48),
        'REPOST' => const Color(0xFF16A34A),
        'CHAT' => const Color(0xFF0EA5E9),
        'EXPLORE' => const Color(0xFF0D9488),
        'STORY' => const Color(0xFFC026D3),
        'RECOMMENDED' => const Color(0xFF6D28D9),
        'PROMOTION' => const Color(0xFFEA580C),
        'EXTERNAL' => const Color(0xFF475569),
        'OTHER' => scheme.outline,
        _ => scheme.primary,
      };

  static IconData _sourceIcon(String key) => switch (key) {
        'FOR_YOU' => Icons.home_outlined,
        'FOLLOWING' => Icons.people_outline_rounded,
        'PROFILE' => Icons.person_outline_rounded,
        'SEARCH' => Icons.search_rounded,
        'HASHTAGS' => Icons.tag_rounded,
        'SHARES' => Icons.share_outlined,
        'SOUND' => Icons.music_note_outlined,
        'LIVE' => Icons.videocam_outlined,
        'NOTIFICATION' => Icons.notifications_none_rounded,
        'SAVED' => Icons.bookmark_border_rounded,
        'LIKED' => Icons.favorite_border_rounded,
        'REPOST' => Icons.repeat_rounded,
        'CHAT' => Icons.chat_bubble_outline_rounded,
        'EXPLORE' => Icons.explore_outlined,
        'STORY' => Icons.auto_stories_outlined,
        'RECOMMENDED' => Icons.auto_awesome_outlined,
        'PROMOTION' => Icons.campaign_outlined,
        'EXTERNAL' => Icons.open_in_new_rounded,
        'OTHER' => Icons.more_horiz_rounded,
        _ => Icons.alt_route_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final item = widget.item;
    final display = item.fullName?.isNotEmpty == true
        ? item.fullName!
        : (item.username != null ? '@${item.username}' : item.userId);

    final source = widget.showTrafficSource ? item.trafficSource : null;
    final sourceAccent = source != null ? _sourceAccent(source, scheme) : null;
    final sourceIcon = source != null ? _sourceIcon(source) : null;
    final sourceLabel = source != null
        ? ReportDetailLabels.trafficSourceLabel(l10n, source)
        : null;

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
            color: _hovered
                ? scheme.primary.withValues(alpha: 0.3)
                : scheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primaryContainer,
              backgroundImage: item.avatarUrl != null && item.avatarUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(item.avatarUrl!)
                  : null,
              child: item.avatarUrl == null || item.avatarUrl!.isEmpty
                  ? Text(
                      display.isNotEmpty ? display[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: scheme.onPrimaryContainer,
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
                      if (item.isVerified) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.verified_rounded,
                            size: 13, color: scheme.primary),
                      ],
                    ],
                  ),
                  Text(
                    widget.dateFormat.format(item.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitleLabel != null
                          ? '${widget.subtitleLabel}: ${item.subtitle}'
                          : item.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  // ── Traffic source chip ──────────────────────────────────
                  if (source != null && sourceAccent != null) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: sourceAccent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: sourceAccent.withValues(alpha: 0.30),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(sourceIcon, size: 10, color: sourceAccent),
                          const SizedBox(width: 3),
                          Text(
                            sourceLabel ?? source,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: sourceAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (item.isBanned)
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
            if (item.userId.isNotEmpty)
              IconButton(
                tooltip: l10n.t('viewProfile'),
                visualDensity: VisualDensity.compact,
                onPressed: () => Navigator.pushNamed(
                  context,
                  AppRoutes.userDetail,
                  arguments: UserEntity(
                    id: item.userId,
                    username: item.username ?? item.userId,
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
                ),
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
    required this.message,
    this.subtitle,
    this.onRetry,
  });

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
          Icon(Icons.people_outline_rounded,
              size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.45)),
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
