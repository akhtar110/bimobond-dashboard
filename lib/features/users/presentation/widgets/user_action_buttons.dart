import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/entities/user_entity.dart';
import '../bloc/users_bloc.dart';

class UserActionButtons extends StatelessWidget {
  const UserActionButtons({
    super.key,
    required this.user,
    this.compact = false,
  });

  final UserEntity user;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bloc = context.read<UsersBloc>();

    return LayoutBuilder(
      builder: (context, constraints) {
        // Fall back to overflow menu when the actions cell is too narrow for
        // Details / Ban / Promote / Delete chips (common on laptop widths).
        final useCompact = compact ||
            !constraints.hasBoundedWidth ||
            constraints.maxWidth < 300;

        if (useCompact) {
          return _CompactActionsMenu(
            user: user,
            onDetails: () => _openDetails(context),
            onBan: () => _confirmBanToggle(context, bloc),
            onSetRole: (role) => bloc.add(
              SetUserRoleEvent(userId: user.id, role: role),
            ),
            onDelete: () => UserDeleteDialog.show(context, user.id),
          );
        }

        return Wrap(
          spacing: 6,
          runSpacing: 6,
          alignment: WrapAlignment.end,
          children: [
            _ActionChip(
              label: l10n.t('details'),
              icon: Icons.open_in_new_rounded,
              onPressed: () => _openDetails(context),
            ),
            _ActionChip(
              label: user.isBanned ? l10n.t('unban') : l10n.t('ban'),
              icon:
                  user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
              onPressed: () => _confirmBanToggle(context, bloc),
            ),
            _RoleActionButton(
              user: user,
              onSetRole: (role) => bloc.add(
                SetUserRoleEvent(userId: user.id, role: role),
              ),
            ),
            _ActionChip(
              label: l10n.t('delete'),
              icon: Icons.delete_outline_rounded,
              isDestructive: true,
              onPressed: () => UserDeleteDialog.show(context, user.id),
            ),
          ],
        );
      },
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.userDetail, arguments: user);
  }

  Future<void> _confirmBanToggle(BuildContext context, UsersBloc bloc) async {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final banning = !user.isBanned;
    final title = banning ? l10n.t('ban') : l10n.t('unban');
    final fallbackMessage = banning
        ? 'Are you sure you want to ban this user?'
        : 'Are you sure you want to unban this user?';
    final message = l10n.tOr(
      banning ? 'confirmBanUserMessage' : 'confirmUnbanUserMessage',
      fallbackMessage,
    );

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: banning
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            child: Text(l10n.t('confirmAction')),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      bloc.add(ToggleBanUserEvent(user.id));
    }
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.isDestructive = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        hoverColor: color.withValues(alpha: 0.08),
        splashColor: color.withValues(alpha: 0.12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.35),
            ),
            color: color.withValues(alpha: 0.06),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactActionsMenu extends StatelessWidget {
  const _CompactActionsMenu({
    required this.user,
    required this.onDetails,
    required this.onBan,
    required this.onSetRole,
    required this.onDelete,
  });

  final UserEntity user;
  final VoidCallback onDetails;
  final VoidCallback onBan;
  final ValueChanged<UserRole> onSetRole;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAdmin = user.roles.contains(UserRole.admin);

    return PopupMenuButton<String>(
      tooltip: l10n.t('actions'),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 8),
      icon: Icon(
        Icons.more_horiz_rounded,
        color: Theme.of(context).colorScheme.primary,
      ),
      onSelected: (value) {
        switch (value) {
          case 'details':
            onDetails();
            return;
          case 'ban':
            onBan();
            return;
          case 'set_role_user':
            onSetRole(UserRole.user);
            return;
          case 'set_role_moderator':
            onSetRole(UserRole.moderator);
            return;
          case 'set_role_admin':
            onSetRole(UserRole.admin);
            return;
          case 'delete':
            onDelete();
            return;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'details',
          child: _MenuRow(Icons.open_in_new_rounded, l10n.t('details')),
        ),
        PopupMenuItem(
          value: 'ban',
          child: _MenuRow(
            user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
            user.isBanned ? l10n.t('unban') : l10n.t('ban'),
          ),
        ),
        if (isAdmin) ...[
          PopupMenuItem(
            value: 'set_role_user',
            child: _MenuRow(
              Icons.person_outline_rounded,
              l10n.t('roleUser'),
            ),
          ),
          PopupMenuItem(
            value: 'set_role_moderator',
            child: _MenuRow(
              Icons.shield_outlined,
              l10n.t('roleModerator'),
            ),
          ),
        ] else ...[
          PopupMenuItem(
            value: 'set_role_user',
            child: _MenuRow(
              Icons.person_outline_rounded,
              l10n.t('roleUser'),
            ),
          ),
          PopupMenuItem(
            value: 'set_role_moderator',
            child: _MenuRow(
              Icons.shield_outlined,
              l10n.t('roleModerator'),
            ),
          ),
          PopupMenuItem(
            value: 'set_role_admin',
            child: _MenuRow(
              Icons.admin_panel_settings_outlined,
              l10n.t('roleAdmin'),
            ),
          ),
        ],
        PopupMenuItem(
          value: 'delete',
          child: _MenuRow(
            Icons.delete_outline_rounded,
            l10n.t('delete'),
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ],
    );
  }
}

class _RoleActionButton extends StatelessWidget {
  const _RoleActionButton({
    required this.user,
    required this.onSetRole,
  });

  final UserEntity user;
  final ValueChanged<UserRole> onSetRole;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.primary;
    final isAdmin = user.roles.contains(UserRole.admin);

    return PopupMenuButton<UserRole>(
      tooltip: isAdmin
          ? l10n.tOr('demote', 'Demote')
          : l10n.tOr('promote', 'Promote'),
      onSelected: onSetRole,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 8),
      itemBuilder: (_) => isAdmin
          ? [
              PopupMenuItem(
                value: UserRole.user,
                child: _MenuRow(
                  Icons.person_outline_rounded,
                  l10n.t('roleUser'),
                ),
              ),
              PopupMenuItem(
                value: UserRole.moderator,
                child: _MenuRow(
                  Icons.shield_outlined,
                  l10n.t('roleModerator'),
                ),
              ),
            ]
          : [
              PopupMenuItem(
                value: UserRole.user,
                child: _MenuRow(
                  Icons.person_outline_rounded,
                  l10n.t('roleUser'),
                ),
              ),
              PopupMenuItem(
                value: UserRole.moderator,
                child: _MenuRow(
                  Icons.shield_outlined,
                  l10n.t('roleModerator'),
                ),
              ),
              PopupMenuItem(
                value: UserRole.admin,
                child: _MenuRow(
                  Icons.admin_panel_settings_outlined,
                  l10n.t('roleAdmin'),
                ),
              ),
            ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withValues(alpha: 0.35),
            width: 1,
          ),
          color: color.withValues(alpha: 0.06),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.manage_accounts_outlined, size: 14, color: color),
            const SizedBox(width: 5),
            Text(
              isAdmin ? l10n.t('demote') : l10n.t('promote'),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow(this.icon, this.label, {this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}

class UserDeleteDialog {
  static void show(BuildContext context, String userId) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: scheme.surface,
        icon: Icon(Icons.warning_amber_rounded, color: scheme.error, size: 32),
        title: Text(
          l10n.t('deleteUserTitle'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        content: Text(
          l10n.t('deleteUserMessage'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.error,
              foregroundColor: scheme.onError,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UsersBloc>().add(DeleteUserEvent(userId));
            },
            child: Text(l10n.t('delete')),
          ),
        ],
      ),
    );
  }
}
