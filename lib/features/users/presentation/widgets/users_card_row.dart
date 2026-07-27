import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';
import 'user_action_buttons.dart';
import 'user_engagement_bar.dart';
import 'user_privacy_badges.dart';
import 'user_status_badge.dart';

/// Compact card row for mobile layouts (location-style).
class UsersCardRow extends StatelessWidget {
  const UsersCardRow({
    super.key,
    required this.user,
    required this.isSelected,
    required this.selectionEnabled,
    required this.onUserTap,
  });

  final UserEntity user;
  final bool isSelected;
  final bool selectionEnabled;
  final VoidCallback onUserTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAdmin = user.roles.contains(UserRole.admin);
    final subtitle = user.email ?? '@${user.username}';

    return Material(
      color: isSelected
          ? scheme.primaryContainer.withValues(alpha: 0.12)
          : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isSelected
              ? scheme.primary.withValues(alpha: 0.45)
              : scheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onUserTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 10, 10, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isSelected,
                onChanged: selectionEnabled
                    ? (_) => context
                        .read<UsersBloc>()
                        .add(ToggleUserSelectionEvent(user.id))
                    : null,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              _CardAvatar(user: user, isAdmin: isAdmin),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? user.username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        UserStatusBadge(user: user),
                        UserPrivacyBadge(user: user),
                        MessagePermissionBadge(
                          permission: user.messagePermission,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    UserEngagementBar(user: user, compact: true),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              UserActionButtons(user: user, compact: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardAvatar extends StatelessWidget {
  const _CardAvatar({
    required this.user,
    required this.isAdmin,
  });

  final UserEntity user;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final ringColors = isAdmin
        ? [scheme.tertiary, scheme.tertiaryContainer]
        : user.isVerified
            ? [scheme.primary, scheme.primary.withValues(alpha: 0.5)]
            : [Colors.transparent, Colors.transparent];

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(colors: ringColors),
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Icon(
                Icons.person_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }
}
