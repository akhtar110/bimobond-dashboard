import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/utils/media_url_resolver.dart';
import '../../domain/entities/profile_entity.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
    this.onRefresh,
  });

  final ProfileEntity profile;
  final VoidCallback onEdit;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final avatarUrl = resolveMediaUrl(profile.avatarUrl) ?? profile.avatarUrl;
    final initial = profile.username.isNotEmpty
        ? profile.username[0].toUpperCase()
        : '?';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner background gradient
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withValues(alpha: 0.85),
                  scheme.tertiary.withValues(alpha: 0.70),
                  scheme.secondary.withValues(alpha: 0.85),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _HeaderPatternPainter(
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (onRefresh != null)
                        IconButton.filledTonal(
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.black.withValues(alpha: 0.25),
                            foregroundColor: Colors.white,
                          ),
                          tooltip: l10n.tOr('refresh', 'Refresh'),
                          onPressed: onRefresh,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                        ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: scheme.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: Text(
                          l10n.tOr('edit_profile', 'Edit Profile'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile content body
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Avatar positioned over banner overlap
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerLow,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: scheme.shadow.withValues(alpha: 0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: scheme.primaryContainer,
                          backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                              ? NetworkImage(avatarUrl)
                              : null,
                          child: avatarUrl == null || avatarUrl.isEmpty
                              ? Text(
                                  initial,
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    color: scheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w800,
                                  ),
                                )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              // Status pill (Active vs Banned)
                              if (profile.isBanned)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scheme.errorContainer,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.block_rounded,
                                          size: 14, color: scheme.onErrorContainer),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.tOr('banned', 'Banned'),
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: scheme.onErrorContainer,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF10B981),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        l10n.tOr('active', 'Active'),
                                        style: theme.textTheme.labelMedium?.copyWith(
                                          color: const Color(0xFF059669),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Role Badges
                              ...profile.roles.map(
                                (r) => _RoleBadge(role: r),
                              ),

                              // Account Type badge
                              if (profile.isPrivate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.lock_rounded,
                                          size: 13, color: scheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        l10n.tOr('private', 'Private Account'),
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Name and Handle
                Transform.translate(
                  offset: const Offset(0, -28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              profile.displayName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          if (profile.isVerified) ...[
                            const SizedBox(width: 6),
                            Tooltip(
                              message: l10n.tOr('verified_user', 'Verified Account'),
                              child: Icon(
                                Icons.verified_rounded,
                                size: 22,
                                color: scheme.primary,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Text(
                            '@${profile.username}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (profile.email != null && profile.email!.isNotEmpty) ...[
                            Text(
                              ' • ',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: scheme.outline,
                              ),
                            ),
                            Icon(Icons.email_outlined,
                                size: 14, color: scheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                profile.email!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              tooltip: l10n.tOr('copy_email', 'Copy Email'),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                minWidth: 24,
                                minHeight: 24,
                              ),
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: profile.email!),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      l10n.tOr('copied_to_clipboard',
                                          'Copied to clipboard'),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      if (profile.bio != null && profile.bio!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          profile.bio!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.45,
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
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final (color, icon, label) = switch (role.toUpperCase()) {
      'SUPER_ADMIN' => (
          Colors.amber.shade700,
          Icons.workspace_premium_rounded,
          'SUPER ADMIN'
        ),
      'ADMIN' => (
          scheme.primary,
          Icons.admin_panel_settings_rounded,
          'ADMIN'
        ),
      'MODERATOR' => (
          Colors.teal,
          Icons.security_rounded,
          'MODERATOR'
        ),
      _ => (
          scheme.onSurfaceVariant,
          Icons.person_rounded,
          role.toUpperCase(),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderPatternPainter extends CustomPainter {
  const _HeaderPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    for (double i = -size.height; i < size.width; i += 32) {
      path.moveTo(i, 0);
      path.lineTo(i + size.height, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
