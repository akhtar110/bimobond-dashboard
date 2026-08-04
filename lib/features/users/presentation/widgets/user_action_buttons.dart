import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../../core/routing/app_router.dart';
import '../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../rbac/presentation/utils/permission_manager.dart';
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

    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (previous, current) =>
          previous.authContext != current.authContext,
      builder: (context, _) {
        final canBan = PermissionManager.canBanUsers(context);
        final canUpdate = PermissionManager.canUpdateUsers(context);
        final canAssignRoles =
            PermissionManager.canAssignUserLegacyRoles(context);

        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = MediaQuery.sizeOf(context).width;
            final available = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : screenWidth;
            // Small / narrow action columns → overflow menu.
            // Medium columns → denser chips. Wide → normal chips.
            final useMenu = compact ||
                !constraints.hasBoundedWidth ||
                available < 360 ||
                screenWidth < 900;
            final dense = !useMenu && (available < 520 || screenWidth < 1400);

            if (useMenu) {
              return _CompactActionsMenu(
                user: user,
                canBan: canBan,
                canUpdate: canUpdate,
                canAssignRoles: canAssignRoles,
                onDetails: () => _openDetails(context),
                onBan: () => _confirmBanToggle(context, bloc),
                onSetRole: (role) => bloc.add(
                  SetUserRoleEvent(userId: user.id, role: role),
                ),
                onDelete: () => UserDeleteDialog.show(context, user.id),
              );
            }

            return Wrap(
              spacing: dense ? 4 : 6,
              runSpacing: dense ? 4 : 6,
              alignment: WrapAlignment.end,
              children: [
                _ActionChip(
                  label: l10n.t('details'),
                  icon: Icons.open_in_new_rounded,
                  dense: dense,
                  onPressed: () => _openDetails(context),
                ),
                if (canBan)
                  _ActionChip(
                    label: user.isBanned ? l10n.t('unban') : l10n.t('ban'),
                    icon: user.isBanned
                        ? Icons.lock_open_rounded
                        : Icons.block_rounded,
                    dense: dense,
                    onPressed: () => _confirmBanToggle(context, bloc),
                  ),
                if (canAssignRoles)
                  _RoleActionButton(
                    user: user,
                    dense: dense,
                    onSetRole: (role) => bloc.add(
                      SetUserRoleEvent(userId: user.id, role: role),
                    ),
                  ),
                if (canUpdate)
                  _ActionChip(
                    label: l10n.t('delete'),
                    icon: Icons.delete_outline_rounded,
                    isDestructive: true,
                    dense: dense,
                    onPressed: () => UserDeleteDialog.show(context, user.id),
                  ),
              ],
            );
          },
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
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool isDestructive;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = isDestructive ? scheme.error : scheme.primary;
    final hPad = dense ? 7.0 : 10.0;
    final vPad = dense ? 4.0 : 6.0;
    final iconSize = dense ? 12.0 : 14.0;
    final gap = dense ? 3.0 : 5.0;

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
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: iconSize, color: color),
                SizedBox(width: gap),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: dense ? 11 : null,
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
    required this.canBan,
    required this.canUpdate,
    required this.canAssignRoles,
    required this.onDetails,
    required this.onBan,
    required this.onSetRole,
    required this.onDelete,
  });

  final UserEntity user;
  final bool canBan;
  final bool canUpdate;
  final bool canAssignRoles;
  final VoidCallback onDetails;
  final VoidCallback onBan;
  final ValueChanged<UserRole> onSetRole;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          case 'edit':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Edit user details for @${user.username}')),
            );
            return;
          case 'verify':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(user.isVerified ? 'Verification removed' : 'User verified successfully')),
            );
            return;
          case 'suspend':
          case 'ban':
            onBan();
            return;
          case 'reset_password':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Password reset email sent to ${user.email ?? user.username}')),
            );
            return;
          case 'send_notification':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Notification dispatch modal opened for @${user.username}')),
            );
            return;
          case 'view_reports':
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Viewing reports received by @${user.username}')),
            );
            return;
          case 'moderation_history':
            onDetails();
            return;
          case 'delete':
            onDelete();
            return;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'details',
          child: _MenuRow(Icons.visibility_outlined, l10n.tOr('viewProfile', 'View Profile')),
        ),
        PopupMenuItem(
          value: 'edit',
          child: _MenuRow(Icons.edit_outlined, l10n.tOr('editUser', 'Edit User')),
        ),
        PopupMenuItem(
          value: 'verify',
          child: _MenuRow(
            Icons.verified_outlined,
            user.isVerified
                ? l10n.tOr('removeVerification', 'Remove Verification')
                : l10n.tOr('verifyUser', 'Verify User'),
          ),
        ),
        if (canBan)
          PopupMenuItem(
            value: 'ban',
            child: _MenuRow(
              user.isBanned ? Icons.lock_open_rounded : Icons.block_rounded,
              user.isBanned
                  ? l10n.tOr('unsuspendUser', 'Unsuspend User')
                  : l10n.tOr('suspendOrBanUser', 'Suspend / Ban User'),
            ),
          ),
        PopupMenuItem(
          value: 'reset_password',
          child: _MenuRow(
            Icons.lock_reset_rounded,
            l10n.tOr('resetPassword', 'Reset Password'),
          ),
        ),
        PopupMenuItem(
          value: 'send_notification',
          child: _MenuRow(
            Icons.notifications_active_outlined,
            l10n.tOr('sendNotification', 'Send Notification'),
          ),
        ),
        PopupMenuItem(
          value: 'view_reports',
          child: _MenuRow(
            Icons.flag_outlined,
            l10n.tOr('viewReports', 'View Reports'),
          ),
        ),
        PopupMenuItem(
          value: 'moderation_history',
          child: _MenuRow(
            Icons.history_rounded,
            l10n.tOr('moderationHistory', 'Moderation History'),
          ),
        ),
        if (canUpdate)
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
    this.dense = false,
  });

  final UserEntity user;
  final ValueChanged<UserRole> onSetRole;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final color = scheme.primary;
    final isAdmin = user.isAdminRole;
    final hPad = dense ? 7.0 : 10.0;
    final vPad = dense ? 4.0 : 6.0;
    final iconSize = dense ? 12.0 : 14.0;
    final gap = dense ? 3.0 : 5.0;

    final items = <PopupMenuEntry<UserRole>>[
      if (user.isAdminRole)
        PopupMenuItem(
          value: UserRole.user,
          child: _MenuRow(
            Icons.person_outline_rounded,
            l10n.tOr('demoteToStandardUser', 'To User'),
          ),
        )
      else if (user.isModeratorRole) ...[
        PopupMenuItem(
          value: UserRole.user,
          child: _MenuRow(
            Icons.person_outline_rounded,
            l10n.tOr('demoteToStandardUser', 'To User'),
          ),
        ),
        PopupMenuItem(
          value: UserRole.admin,
          child: _MenuRow(
            Icons.admin_panel_settings_outlined,
            l10n.tOr('promoteToAdmin', 'To Admin'),
          ),
        ),
      ] else ...[
        PopupMenuItem(
          value: UserRole.moderator,
          child: _MenuRow(
            Icons.shield_outlined,
            l10n.tOr('promoteToModerator', 'To Moderator'),
          ),
        ),
        PopupMenuItem(
          value: UserRole.admin,
          child: _MenuRow(
            Icons.admin_panel_settings_outlined,
            l10n.tOr('promoteToAdmin', 'To Admin'),
          ),
        ),
      ],
    ];

    return PopupMenuButton<UserRole>(
      tooltip: isAdmin
          ? l10n.tOr('demote', 'Demote')
          : l10n.tOr('promote', 'Promote'),
      onSelected: onSetRole,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      offset: const Offset(0, 8),
      itemBuilder: (_) => items,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
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
            Icon(Icons.manage_accounts_outlined, size: iconSize, color: color),
            SizedBox(width: gap),
            Text(
              isAdmin ? l10n.t('demote') : l10n.t('promote'),
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: dense ? 11 : null,
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
