import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../users/domain/entities/user_entity.dart';
import '../../domain/entities/managed_post_entity.dart';
import 'investigation/investigation_theme.dart';

/// A card that shows the post author's profile and navigates to
/// [UserDetailScreen] when tapped.
///
/// All data is sourced from [ManagedPostEntity]'s user fields that are
/// populated in [ManagedPostModel.fromJson] — no separate API call is needed.
class PostAuthorCard extends StatefulWidget {
  const PostAuthorCard({
    super.key,
    required this.post,
    required this.isDark,
  });

  final ManagedPostEntity post;
  final bool isDark;

  @override
  State<PostAuthorCard> createState() => _PostAuthorCardState();
}

class _PostAuthorCardState extends State<PostAuthorCard> {
  bool _hovered = false;

  ManagedPostEntity get post => widget.post;
  bool get isDark => widget.isDark;

  void _navigate(BuildContext context) {
    if (post.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.t('errorOccurred')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final user = UserEntity(
      id: post.userId,
      username: post.userName ?? post.userId,
      fullName: post.userFullName,
      email: post.userEmail,
      avatarUrl: post.userProfileImage,
      isVerified: post.userIsVerified,
      isPrivate: false,
      allowComments: true,
      allowDirectMsgs: true,
      language: 'en',
      theme: 'light',
      followerCount: post.userFollowersCount,
      followingCount: post.userFollowingCount,
      postCount: post.userPostsCount,
      totalLikes: 0,
      isBanned: post.userIsBanned,
      roles: const [UserRole.user],
      createdAt: post.userJoinedAt,
    );
    Navigator.pushNamed(context, AppRoutes.userDetail, arguments: user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final primary = theme.colorScheme.primary;

    final cardColor = isDark ? const Color(0xFF1A1F2E) : Colors.white;
    final borderColor = _hovered
        ? primary.withValues(alpha: 0.4)
        : (isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0));

    return Tooltip(
      message: l10n.t('userProfile'),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => _navigate(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark
                        ? (_hovered ? 0.22 : 0.10)
                        : (_hovered ? 0.07 : 0.03),
                  ),
                  blurRadius: _hovered ? 16 : 8,
                  offset: Offset(0, _hovered ? 4 : 2),
                ),
                if (_hovered)
                  BoxShadow(
                    color: primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Card header ───────────────────────────────────────────
                Row(
                  children: [
                    Text(
                      l10n.t('postAuthor'),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    AnimatedOpacity(
                      opacity: _hovered ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 150),
                      child: Icon(
                        Icons.open_in_new_rounded,
                        size: 14,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Profile row ───────────────────────────────────────────
                LayoutBuilder(builder: (context, constraints) {
                  final compact = constraints.maxWidth < 340;
                  return compact
                      ? _CompactProfile(post: post, isDark: isDark)
                      : _WideProfile(post: post, isDark: isDark);
                }),

                const SizedBox(height: 14),

                // ── Stats row ─────────────────────────────────────────────
                _AuthorStatsRow(post: post, isDark: isDark),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF2E3440)
                      : const Color(0xFFE8ECF0),
                ),
                const SizedBox(height: 10),

                // ── Meta info ─────────────────────────────────────────────
                _MetaRow(
                  icon: Icons.fingerprint_rounded,
                  label: l10n.t('userId'),
                  value: post.userId,
                  isDark: isDark,
                  mono: true,
                ),
                if (post.userJoinedAt != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.calendar_today_outlined,
                    label: l10n.t('joined'),
                    value: DateFormat('MMM dd, yyyy')
                        .format(post.userJoinedAt!),
                    isDark: isDark,
                  ),
                ],
                if (post.userEmail != null) ...[
                  const SizedBox(height: 6),
                  _MetaRow(
                    icon: Icons.email_outlined,
                    label: l10n.t('emailAddress'),
                    value: post.userEmail!,
                    isDark: isDark,
                  ),
                ],
                const SizedBox(height: InvestigationTheme.s12),
                Wrap(
                  spacing: InvestigationTheme.s8,
                  runSpacing: InvestigationTheme.s8,
                  children: [
                    _AuthorActionButton(
                      icon: Icons.person_outline_rounded,
                      label: l10n.t('viewProfile'),
                      onTap: () => _navigate(context),
                      isDark: isDark,
                    ),
                    _AuthorActionButton(
                      icon: Icons.timeline_outlined,
                      label: l10n.t('userActivityNav'),
                      onTap: () => _navigate(context),
                      isDark: isDark,
                    ),
                    _AuthorActionButton(
                      icon: Icons.history_rounded,
                      label: l10n.t('moderationHistory'),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.t('banUserComingSoon')),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      isDark: isDark,
                      outlined: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Wide profile (avatar left, details right) ─────────────────────────────────

class _WideProfile extends StatelessWidget {
  const _WideProfile({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _AuthorAvatar(post: post, radius: 32),
        const SizedBox(width: 14),
        Expanded(child: _AuthorDetails(post: post, isDark: isDark)),
      ],
    );
  }
}

// ── Compact profile (avatar + details stacked) ────────────────────────────────

class _CompactProfile extends StatelessWidget {
  const _CompactProfile({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthorAvatar(post: post, radius: 24),
        const SizedBox(height: 10),
        _AuthorDetails(post: post, isDark: isDark),
      ],
    );
  }
}

// ── Avatar with initials fallback ─────────────────────────────────────────────

class _AuthorAvatar extends StatelessWidget {
  const _AuthorAvatar({required this.post, required this.radius});

  final ManagedPostEntity post;
  final double radius;

  String get _initials {
    final name = post.userFullName?.trim() ?? post.userName?.trim() ?? '';
    if (name.isEmpty) return '?';
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final imageUrl = post.userProfileImage;

    if (imageUrl != null && imageUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: primary.withValues(alpha: 0.1),
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: primary.withValues(alpha: 0.15),
      child: Text(
        _initials,
        style: TextStyle(
          color: primary,
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.65,
        ),
      ),
    );
  }
}

// ── Name / username / badges ──────────────────────────────────────────────────

class _AuthorDetails extends StatelessWidget {
  const _AuthorDetails({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    final displayName = post.userFullName?.isNotEmpty == true
        ? post.userFullName!
        : (post.userName ?? post.userId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                ),
              ),
            ),
            if (post.userIsVerified) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: l10n.t('verified'),
                child: const Icon(
                  Icons.verified_rounded,
                  size: 15,
                  color: Colors.blue,
                ),
              ),
            ],
          ],
        ),
        if (post.userName != null) ...[
          const SizedBox(height: 3),
          Text(
            '@${post.userName}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade400 : const Color(0xFF6B7280),
            ),
          ),
        ],
        const SizedBox(height: 6),
        _AccountStatusBadge(isBanned: post.userIsBanned),
      ],
    );
  }
}

// ── Followers / following / posts stats ──────────────────────────────────────

class _AuthorStatsRow extends StatelessWidget {
  const _AuthorStatsRow({required this.post, required this.isDark});

  final ManagedPostEntity post;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: _compact(post.userFollowersCount),
            label: l10n.t('followers'),
            isDark: isDark,
          ),
        ),
        _VertDivider(isDark: isDark),
        Expanded(
          child: _StatTile(
            value: _compact(post.userFollowingCount),
            label: l10n.t('following'),
            isDark: isDark,
          ),
        ),
        _VertDivider(isDark: isDark),
        Expanded(
          child: _StatTile(
            value: _compact(post.userPostsCount),
            label: l10n.t('posts'),
            isDark: isDark,
          ),
        ),
      ],
    );
  }

  static String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.value,
    required this.label,
    required this.isDark,
  });

  final String value;
  final String label;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}

class _VertDivider extends StatelessWidget {
  const _VertDivider({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 32,
      color: isDark ? const Color(0xFF2E3440) : const Color(0xFFE8ECF0),
    );
  }
}

// ── Account status badge ──────────────────────────────────────────────────────

class _AccountStatusBadge extends StatelessWidget {
  const _AccountStatusBadge({required this.isBanned});
  final bool isBanned;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final label = isBanned ? l10n.t('banned') : l10n.t('active');
    final fg = isBanned
        ? (isDark ? const Color(0xFFFCA5A5) : Colors.red.shade700)
        : (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D));
    final bg = isBanned
        ? (isDark ? const Color(0xFF3B1D1D) : Colors.red.shade50)
        : (isDark ? const Color(0xFF14532D) : const Color(0xFFDCFCE7));
    final dot = isBanned ? Colors.red.shade400 : const Color(0xFF22C55E);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ]),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = isDark ? Colors.grey.shade500 : const Color(0xFF9CA3AF);

    return Row(
      children: [
        Icon(icon, size: 14, color: muted),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: theme.textTheme.bodySmall?.copyWith(
            color: muted,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? Colors.grey.shade300 : const Color(0xFF374151),
              fontWeight: FontWeight.w600,
              fontFamily: mono ? 'monospace' : null,
              fontSize: mono ? 11 : null,
            ),
          ),
        ),
      ],
    );
  }
}

class _AuthorActionButton extends StatelessWidget {
  const _AuthorActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
    this.outlined = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    if (outlined) {
      return OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 14),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
          ),
        ),
      );
    }
    return FilledButton.tonalIcon(
      onPressed: onTap,
      icon: Icon(icon, size: 14),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: primary.withValues(alpha: isDark ? 0.15 : 0.08),
        foregroundColor: primary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(InvestigationTheme.radiusSm),
        ),
      ),
    );
  }
}
