import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';

class UserDetailRoleChip extends StatelessWidget {
  const UserDetailRoleChip({super.key, required this.user});
  final UserEntity user;
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isAdmin = user.roles.contains(UserRole.admin);
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border.withValues(alpha: 0.3)),
      ),
      child: Text(
        isAdmin
            ? l10n.t('roleBadgeAdmin')
            : (isMod ? l10n.t('roleBadgeModerator') : l10n.t('roleBadgeUser')),
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class UserDetailActionButton extends StatelessWidget {
  const UserDetailActionButton({
    super.key,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

class UserDetailHeader extends StatelessWidget {
  const UserDetailHeader({super.key, required this.user});
  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 600;

        final avatar = Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [scheme.primary, scheme.primary.withValues(alpha: 0.5)],
                ),
              ),
              child: CircleAvatar(
                radius: isCompact ? 40 : 60,
                backgroundColor: scheme.surfaceContainerHighest,
                backgroundImage: user.avatarUrl != null
                    ? CachedNetworkImageProvider(user.avatarUrl!)
                    : null,
                child: user.avatarUrl == null
                    ? Icon(
                        Icons.person,
                        size: isCompact ? 40 : 60,
                        color: scheme.onSurfaceVariant,
                      )
                    : null,
              ),
            ),
            if (user.isVerified)
              Positioned(
                bottom: isCompact ? 2 : 4,
                right: isCompact ? 2 : 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: scheme.onPrimary,
                    size: isCompact ? 12 : 16,
                  ),
                ),
              ),
          ],
        );

        Widget contentColumn(CrossAxisAlignment align, WrapAlignment wrapAlign) {
          return Column(
            crossAxisAlignment: align,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 8,
                alignment: wrapAlign,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    user.fullName ?? user.username,
                    style: (isCompact
                            ? theme.textTheme.headlineSmall
                            : theme.textTheme.displaySmall)
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                  ),
                  UserDetailRoleChip(user: user),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '@${user.username}',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              if (user.bio != null)
                Text(
                  user.bio!,
                  textAlign:
                      isCompact ? TextAlign.center : TextAlign.start,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: wrapAlign,
                children: [
                  UserDetailActionButton(
                    label: user.isBanned
                        ? context.l10n.t('unban')
                        : context.l10n.t('ban'),
                    color: user.isBanned ? scheme.tertiary : scheme.error,
                    onTap: () => context
                        .read<UsersBloc>()
                        .add(ToggleBanUserEvent(user.id)),
                  ),
                  UserDetailActionButton(
                    label: user.roles.contains(UserRole.admin)
                        ? context.l10n.t('demote')
                        : context.l10n.t('promote'),
                    color: scheme.primary,
                    onTap: () => user.roles.contains(UserRole.admin)
                        ? context
                            .read<UsersBloc>()
                            .add(DemoteUserEvent(user.id))
                        : context
                            .read<UsersBloc>()
                            .add(PromoteUserEvent(user.id)),
                  ),
                ],
              ),
            ],
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: isCompact
              ? Column(
                  children: [
                    avatar,
                    const SizedBox(height: 16),
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
                    const SizedBox(width: 20),
                    Expanded(
                      child: contentColumn(
                        CrossAxisAlignment.start,
                        WrapAlignment.start,
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}
