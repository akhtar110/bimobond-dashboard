import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/user_admin_action_type.dart';
import '../../../domain/entities/user_entity.dart';
import '../../bloc/user_detail_bloc.dart';
import '../../bloc/user_detail_event.dart';
import '../../utils/user_admin_action_presentation.dart';
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: scheme.primaryContainer.withValues(alpha: 0.45),
            foregroundColor: scheme.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      menuChildren: [
        for (final action in actions)
          _AdminActionMenuItem(
            action: action,
            user: user,
            isLoading: executingAction == action,
            isDisabled: isBusy && executingAction != action,
            onSelected: () => _onActionTap(context, action),
          ),
      ],
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
      UserAdminActionType.promote => 'Promote',
      UserAdminActionType.demote => 'Demote',
      UserAdminActionType.delete => 'Delete',
    };
  }
}
