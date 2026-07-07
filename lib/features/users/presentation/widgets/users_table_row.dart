import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/user_entity.dart';
import 'user_action_buttons.dart';
import 'user_engagement_bar.dart';
import 'user_status_badge.dart';
import 'users_table_config.dart';

const double kUsersTableRowHeight = 56;

class UsersTableRow extends StatelessWidget {
  const UsersTableRow({
    super.key,
    required this.user,
    required this.config,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onUserTap,
    this.selectionEnabled = true,
    this.striped = false,
  });

  final UserEntity user;
  final UsersTableConfig config;
  final bool isSelected;
  final ValueChanged<String> onToggleSelection;
  final VoidCallback onUserTap;
  final bool selectionEnabled;
  final bool striped;

  String _roleLabel(BuildContext context) {
    final l10n = context.l10n;
    if (user.roles.contains(UserRole.admin)) return l10n.t('roleAdmin');
    if (user.roles.contains(UserRole.moderator)) return l10n.t('roleModerator');
    return l10n.t('roleUser');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isAdmin = user.roles.contains(UserRole.admin);
    final cellStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 11.5,
      height: 1.25,
    );

    return _HoverableRow(
      isSelected: isSelected,
      striped: striped,
      onTap: onUserTap,
      child: SizedBox(
        height: kUsersTableRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              SizedBox(
                width: config.checkboxWidth,
                child: Checkbox(
                  value: isSelected,
                  tristate: false,
                  onChanged: selectionEnabled
                      ? (_) => onToggleSelection(user.id)
                      : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
              ),
              Expanded(
                flex: config.showAccount ? 28 : 36,
                child: Row(
                  children: [
                    _UserAvatar(user: user, isAdmin: isAdmin),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.fullName ?? user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: cellStyle?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '@${user.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontSize: 10.5,
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
                          style: cellStyle?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: cellStyle?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                flex: 14,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: UserStatusBadge(user: user),
                ),
              ),
              if (config.showEngagement) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 16,
                  child: UserEngagementBar(
                    user: user,
                    compact: config.compactActions,
                  ),
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
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({
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
        radius: 16,
        backgroundColor: scheme.surfaceContainerHighest,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Icon(
                Icons.person_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
    );
  }
}

class _HoverableRow extends StatefulWidget {
  const _HoverableRow({
    required this.child,
    required this.isSelected,
    required this.striped,
    required this.onTap,
  });

  final Widget child;
  final bool isSelected;
  final bool striped;
  final VoidCallback onTap;

  @override
  State<_HoverableRow> createState() => _HoverableRowState();
}

class _HoverableRowState extends State<_HoverableRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    Color rowColor;
    if (widget.isSelected) {
      rowColor = scheme.primaryContainer.withValues(alpha: 0.18);
    } else if (_hovered) {
      rowColor = scheme.surfaceContainerHighest;
    } else if (widget.striped) {
      rowColor = scheme.surfaceContainerHighest.withValues(alpha: 0.35);
    } else {
      rowColor = scheme.surface;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Material(
        color: rowColor,
        child: InkWell(
          onTap: widget.onTap,
          child: widget.child,
        ),
      ),
    );
  }
}
