import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../../rbac/presentation/bloc/rbac_bloc.dart';
import '../../../../rbac/presentation/utils/permission_manager.dart';
import '../../../domain/entities/user_admin_action_type.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/user_detail_bloc.dart';
import '../../bloc/user_detail_event.dart';
import '../../utils/user_admin_action_presentation.dart';
import '../reset_password_dialog.dart';
import '../user_privacy_settings_sheet.dart';
import 'admin_action_confirmation_dialog.dart';

class UserAdminActionsSection extends StatelessWidget {
  const UserAdminActionsSection({
    super.key,
    required this.user,
    required this.executingAction,
    required this.isBusy,
  });

  final UserEntity user;
  final UserAdminActionType? executingAction;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final actions = visibleUserAdminActions(user);
    final isLoading = executingAction != null;

    return BlocBuilder<RbacBloc, RbacState>(
      buildWhen: (previous, current) =>
          previous.authContext != current.authContext,
      builder: (context, rbacState) {
        final canResetPassword =
            PermissionManager.canResetUserPassword(context);
        final canBan = PermissionManager.canBanUsers(context);
        final canUpdate = PermissionManager.canUpdateUsers(context);
        final canAssignRoles =
            PermissionManager.canAssignUserLegacyRoles(context);

        // Ban / unban / delete only — role changes use targeted items below.
        final gatedActions = actions.where((action) {
          return switch (action) {
            UserAdminActionType.ban || UserAdminActionType.unban => canBan,
            UserAdminActionType.promote || UserAdminActionType.demote => false,
            UserAdminActionType.delete => canUpdate,
          };
        }).toList(growable: false);

        final roleItems = <_RoleMenuTarget>[
          if (canAssignRoles && user.isStandardRole) ...[
            const _RoleMenuTarget(
              role: UserRole.moderator,
              labelKey: 'promoteToModerator',
              fallbackLabel: 'To Moderator',
              icon: Icons.shield_outlined,
              confirmAs: UserAdminActionType.promote,
            ),
            const _RoleMenuTarget(
              role: UserRole.admin,
              labelKey: 'promoteToAdmin',
              fallbackLabel: 'To Admin',
              icon: Icons.admin_panel_settings_outlined,
              confirmAs: UserAdminActionType.promote,
            ),
          ],
          if (canAssignRoles && user.isModeratorRole) ...[
            const _RoleMenuTarget(
              role: UserRole.admin,
              labelKey: 'promoteToAdmin',
              fallbackLabel: 'To Admin',
              icon: Icons.admin_panel_settings_outlined,
              confirmAs: UserAdminActionType.promote,
            ),
            const _RoleMenuTarget(
              role: UserRole.user,
              labelKey: 'demoteToStandardUser',
              fallbackLabel: 'To User',
              icon: Icons.person_outline_rounded,
              confirmAs: UserAdminActionType.demote,
            ),
          ],
          if (canAssignRoles && user.isAdminRole)
            const _RoleMenuTarget(
              role: UserRole.user,
              labelKey: 'demoteToStandardUser',
              fallbackLabel: 'To User',
              icon: Icons.person_outline_rounded,
              confirmAs: UserAdminActionType.demote,
            ),
        ];

        return MenuAnchor(
          style: MenuStyle(
            visualDensity: VisualDensity.compact,
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(vertical: 4),
            ),
            maximumSize: WidgetStateProperty.all(const Size(280, 420)),
            shape: WidgetStateProperty.all(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          builder: (context, controller, child) {
            return TextButton.icon(
              onPressed: isBusy && !isLoading
                  ? null
                  : () {
                      if (controller.isOpen) {
                        controller.close();
                      } else {
                        controller.open();
                      }
                    },
              icon: isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: scheme.primary,
                      ),
                    )
                  : Icon(
                      Icons.admin_panel_settings_outlined,
                      size: 18,
                      color: scheme.primary,
                    ),
              label: Text(
                l10n.t('adminActions'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: scheme.primary,
                ),
              ),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                backgroundColor:
                    scheme.primaryContainer.withValues(alpha: 0.45),
                foregroundColor: scheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          menuChildren: [
            for (final action in gatedActions)
              _AdminActionMenuItem(
                action: action,
                user: user,
                isLoading: executingAction == action,
                isDisabled: isBusy && executingAction != action,
                onSelected: () => _onActionTap(context, action),
              ),
            for (final item in roleItems)
              _RoleActionMenuItem(
                target: item,
                isLoading: executingAction == item.confirmAs,
                isDisabled: isBusy && executingAction != item.confirmAs,
                onSelected: () => _onRoleTap(context, item),
              ),
            if (canUpdate)
              MenuItemButton(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                onPressed: isBusy
                    ? null
                    : () => UserPrivacySettingsSheet.show(context, user: user),
                leadingIcon: Icon(
                  Icons.lock_outline_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                child: Text(
                  l10n.t('editPrivacySettings'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isBusy ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ),
            if (canResetPassword)
              MenuItemButton(
                style: ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  padding: WidgetStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                onPressed: isBusy
                    ? null
                    : () => ResetPasswordDialog.show(
                          context,
                          userId: user.id,
                          displayName: user.fullName ?? user.username,
                        ),
                leadingIcon: Icon(
                  Icons.lock_reset_rounded,
                  size: 18,
                  color: scheme.onSurfaceVariant,
                ),
                child: Text(
                  l10n.t('resetPassword'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        isBusy ? scheme.onSurfaceVariant : scheme.onSurface,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _onActionTap(
    BuildContext context,
    UserAdminActionType action,
  ) async {
    final confirmed = await AdminActionConfirmationDialog.show(
      context,
      action: action,
      user: user,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<UserDetailBloc>().add(userDetailAdminActionEventFor(action));
  }

  Future<void> _onRoleTap(
    BuildContext context,
    _RoleMenuTarget target,
  ) async {
    final confirmed = await AdminActionConfirmationDialog.show(
      context,
      action: target.confirmAs,
      user: user,
    );
    if (confirmed != true || !context.mounted) return;

    context.read<UserDetailBloc>().add(SetUserDetailRoleEvent(target.role));
  }
}

class _RoleMenuTarget {
  const _RoleMenuTarget({
    required this.role,
    required this.labelKey,
    required this.fallbackLabel,
    required this.icon,
    required this.confirmAs,
  });

  final UserRole role;
  final String labelKey;
  final String fallbackLabel;
  final IconData icon;
  final UserAdminActionType confirmAs;
}

class _RoleActionMenuItem extends StatelessWidget {
  const _RoleActionMenuItem({
    required this.target,
    required this.isLoading,
    required this.isDisabled,
    required this.onSelected,
  });

  final _RoleMenuTarget target;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDestructive = target.confirmAs == UserAdminActionType.demote;
    final accent = isDestructive ? scheme.error : scheme.onSurfaceVariant;

    return MenuItemButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      onPressed: isDisabled ? null : onSelected,
      leadingIcon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            )
          : Icon(target.icon, size: 18, color: accent),
      child: Text(
        l10n.tOr(target.labelKey, target.fallbackLabel),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDisabled ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }
}

class _AdminActionMenuItem extends StatelessWidget {
  const _AdminActionMenuItem({
    required this.action,
    required this.user,
    required this.isLoading,
    required this.isDisabled,
    required this.onSelected,
  });

  final UserAdminActionType action;
  final UserEntity user;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDestructive = action.isDestructive(user);
    final accent = isDestructive ? scheme.error : scheme.onSurfaceVariant;
    final label = l10n.tOr(action.labelKey(user), _fallbackLabel(action));

    return MenuItemButton(
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        ),
      ),
      onPressed: isDisabled ? null : onSelected,
      leadingIcon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            )
          : Icon(action.icon, size: 18, color: accent),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDisabled ? scheme.onSurfaceVariant : scheme.onSurface,
        ),
      ),
    );
  }

  String _fallbackLabel(UserAdminActionType action) {
    return switch (action) {
      UserAdminActionType.ban => 'Ban',
      UserAdminActionType.unban => 'Unban',
      UserAdminActionType.promote => 'To Admin',
      UserAdminActionType.demote => 'To User',
      UserAdminActionType.delete => 'Delete',
    };
  }
}
