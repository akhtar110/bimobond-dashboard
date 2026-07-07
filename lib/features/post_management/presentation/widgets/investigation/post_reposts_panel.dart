import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../../core/routing/app_router.dart';
import '../../../../users/domain/entities/user_entity.dart';
import '../../../domain/entities/managed_post_entity.dart';
import 'investigation_theme.dart';

/// Displays reposters from [ManagedPostEntity.recentReposts] when available.
class PostRepostsPanel extends StatelessWidget {
  const PostRepostsPanel({super.key, required this.post});

  final ManagedPostEntity post;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reposts = post.recentReposts;
    final total = post.repostCount > 0 ? post.repostCount : reposts.length;

    if (reposts.isEmpty) {
      return _EmptyState(
        icon: Icons.repeat_rounded,
        message: l10n.t('noRepostsYet'),
        subtitle: total > 0
            ? context.tr('repostsCountSummary', {'count': '$total'})
            : null,
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy · HH:mm');

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
                context.tr('repostsCountSummary', {'count': '$total'}),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        ...reposts.map((raw) {
          final user = raw['user'] as Map<String, dynamic>? ?? {};
          final username = user['username']?.toString() ?? '—';
          final fullName = user['fullName']?.toString();
          final avatarUrl = user['avatarUrl']?.toString();
          final isBanned = user['isBanned'] as bool? ?? false;
          final isVerified = user['isVerified'] as bool? ?? false;
          final createdAt = DateTime.tryParse(raw['createdAt']?.toString() ?? '') ??
              DateTime.now();
          final userId = user['id']?.toString() ?? '';

          return Padding(
            padding: const EdgeInsets.only(bottom: InvestigationTheme.s8),
            child: _RepostRow(
              username: username,
              fullName: fullName,
              avatarUrl: avatarUrl,
              isBanned: isBanned,
              isVerified: isVerified,
              repostedAt: dateFormat.format(createdAt),
              onViewProfile: userId.isNotEmpty
                  ? () => Navigator.pushNamed(
                        context,
                        AppRoutes.userDetail,
                        arguments: UserEntity(
                          id: userId,
                          username: username,
                          fullName: fullName,
                          avatarUrl: avatarUrl,
                          isVerified: isVerified,
                          isPrivate: false,
                          allowComments: true,
                          allowDirectMsgs: true,
                          language: 'en',
                          theme: 'light',
                          followerCount: 0,
                          followingCount: 0,
                          postCount: 0,
                          totalLikes: 0,
                          isBanned: isBanned,
                          roles: const [],
                        ),
                      )
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

class _RepostRow extends StatefulWidget {
  const _RepostRow({
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.isBanned,
    required this.isVerified,
    required this.repostedAt,
    this.onViewProfile,
  });

  final String username;
  final String? fullName;
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
    final display = widget.fullName?.isNotEmpty == true
        ? widget.fullName!
        : '@${widget.username}';

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
  });

  final IconData icon;
  final String message;
  final String? subtitle;

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
        ],
      ),
    );
  }
}
