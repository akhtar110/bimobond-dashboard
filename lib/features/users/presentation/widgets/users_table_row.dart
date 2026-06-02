import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/user_entity.dart';
import 'user_action_buttons.dart';
import 'user_engagement_bar.dart';
import 'user_status_badge.dart';
import 'users_table_config.dart';

class UsersTableRow extends StatelessWidget {
  const UsersTableRow({
    super.key,
    required this.user,
    required this.config,
  });

  final UserEntity user;
  final UsersTableConfig config;

  String _roleLabel(BuildContext context) {
    final l10n = context.l10n;
    if (user.roles.contains(UserRole.admin)) return l10n.t('roleAdmin');
    if (user.roles.contains(UserRole.moderator)) return l10n.t('roleModerator');
    return l10n.t('roleUser');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final mutedColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);
    final isAdmin = user.roles.contains(UserRole.admin);

    return _HoverableRow(
      onTap: () => Navigator.pushNamed(
        context,
        AppRoutes.userDetail,
        arguments: user,
      ),
      hoverColor: primary.withValues(alpha: isDark ? 0.06 : 0.04),
      accentColor: primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Expanded(
              flex: config.showAccount ? 28 : 36,
              child: Row(
                children: [
                  _UserAvatar(user: user, isAdmin: isAdmin, primary: primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          user.fullName ?? user.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '@${user.username}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: mutedColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (config.showAccount)
              Expanded(
                flex: 22,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _roleLabel(context),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              flex: 14,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: UserStatusBadge(user: user),
              ),
            ),
            if (config.showEngagement) ...[
              const SizedBox(width: 12),
              Expanded(
                flex: 16,
                child: UserEngagementBar(user: user),
              ),
            ],
            Expanded(
              flex: config.showAccount ? 28 : 34,
              child: Align(
                alignment: AlignmentDirectional.centerEnd,
                child: UserActionButtons(
                  user: user,
                  compact: config.compactActions,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
    required this.user,
    required this.isAdmin,
    required this.primary,
  });

  final UserEntity user;
  final bool isAdmin;
  final Color primary;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColors = isAdmin
        ? [const Color(0xFFF59E0B), const Color(0xFFFBBF24)]
        : user.isVerified
            ? [primary, primary.withValues(alpha: 0.5)]
            : [Colors.transparent, Colors.transparent];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: ringColors),
      ),
      child: CircleAvatar(
        radius: 18,
        backgroundColor: isDark ? const Color(0xFF1E2433) : const Color(0xFFF1F5F9),
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Icon(
                Icons.person_rounded,
                size: 20,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
              )
            : null,
      ),
    );
  }
}

class _HoverableRow extends StatefulWidget {
  const _HoverableRow({
    required this.child,
    required this.onTap,
    required this.hoverColor,
    required this.accentColor,
  });

  final Widget child;
  final VoidCallback onTap;
  final Color hoverColor;
  final Color accentColor;

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : const Color(0xFFE8ECF1),
              ),
              left: BorderSide(
                color: _hovered
                    ? widget.accentColor
                    : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
