import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import '../utils/user_detail_layout_metrics.dart';
import 'user_online_status_cell.dart';
import 'user_privacy_badges.dart';

class UserDetailRoleChip extends StatelessWidget {
  const UserDetailRoleChip({super.key, required this.user, this.compact = false});
  final UserEntity user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = user.roles.includesAdmin;
    final isMod = user.roles.contains(UserRole.moderator);
    final Color foreground;
    final Color background;
    final Color border;

    if (isAdmin) {
      foreground = scheme.onTertiaryContainer;
      background = scheme.tertiaryContainer;
      border = scheme.tertiary;
    } else if (isMod) {
      foreground = scheme.onSecondaryContainer;
      background = scheme.secondaryContainer;
      border = scheme.secondary;
    } else {
      foreground = scheme.onPrimaryContainer;
      background = scheme.primaryContainer;
      border = scheme.primary;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(compact ? 10 : 12),
        border: Border.all(color: border.withValues(alpha: 0.3)),
      ),
      child: Text(
        isAdmin
            ? l10n.t('roleBadgeAdmin')
            : (isMod ? l10n.t('roleBadgeModerator') : l10n.t('roleBadgeUser')),
        style: TextStyle(
          color: foreground,
          fontSize: compact ? 11 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class UserDetailHeader extends StatelessWidget {
  const UserDetailHeader({
    super.key,
    required this.user,
    this.adminActions,
    this.onAvatarTap,
  });

  final UserEntity user;
  final Widget? adminActions;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = userDetailLayoutMetrics(constraints.maxWidth);
        final isCompact = metrics.headerStacked;
        final avatarRadius = metrics.avatarRadius;
        final verifiedSize = metrics.verifiedBadgeSize;

        final avatar = Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onAvatarTap,
            customBorder: const CircleBorder(),
            child: Stack(
              children: [
                Container(
                  padding: EdgeInsets.all(isCompact ? 2.5 : 3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        scheme.primary,
                        scheme.primary.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: scheme.surfaceContainerHighest,
                    backgroundImage: user.avatarUrl != null
                        ? CachedNetworkImageProvider(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Icon(
                            Icons.person,
                            size: metrics.avatarIconSize,
                            color: scheme.onSurfaceVariant,
                          )
                        : null,
                  ),
                ),
                if (user.isVerified)
                  Positioned(
                    bottom: isCompact ? 1 : 2,
                    right: isCompact ? 1 : 2,
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 2.5 : 3),
                      decoration: BoxDecoration(
                        color: scheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check,
                        color: scheme.onPrimary,
                        size: verifiedSize,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );

        Widget contentColumn(CrossAxisAlignment align, WrapAlignment wrapAlign) {
          return Column(
            crossAxisAlignment: align,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 6,
                alignment: wrapAlign,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style: (isCompact
                            ? theme.textTheme.titleLarge
                            : theme.textTheme.headlineSmall)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                  UserDetailRoleChip(user: user, compact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '@${user.username}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (user.bio != null) ...[
                const SizedBox(height: 8),
                Text(
                  user.bio!,
                  textAlign: isCompact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                alignment: isCompact ? WrapAlignment.center : WrapAlignment.start,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  UserPrivacyBadge(user: user),
                  MessagePermissionBadge(permission: user.messagePermission),
                  UserLastSeenBadge(user: user),
                ],
              ),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(metrics.sectionPadding),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(metrics.headerRadius),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (adminActions != null)
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: adminActions!,
                ),
              if (adminActions != null) SizedBox(height: metrics.sectionSpacing * 0.5),
              isCompact
                  ? Column(
                      children: [
                        avatar,
                        SizedBox(height: metrics.sectionSpacing),
                        contentColumn(
                          CrossAxisAlignment.center,
                          WrapAlignment.center,
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        avatar,
                        SizedBox(width: metrics.sectionSpacing + 4),
                        Expanded(
                          child: contentColumn(
                            CrossAxisAlignment.start,
                            WrapAlignment.start,
                          ),
                        ),
                      ],
                    ),
            ],
          ),
        );
      },
    );
  }
}
