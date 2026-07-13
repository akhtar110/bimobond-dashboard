import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/user_admin_action_type.dart';
import '../../../domain/entities/user_entity.dart';
import '../../utils/user_admin_action_presentation.dart';

class AdminActionConfirmationDialog extends StatelessWidget {
  const AdminActionConfirmationDialog({
    super.key,
    required this.action,
    required this.user,
  });

  final UserAdminActionType action;
  final UserEntity user;

  static Future<bool?> show(
    BuildContext context, {
    required UserAdminActionType action,
    required UserEntity user,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AdminActionConfirmationDialog(
        action: action,
        user: user,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final isDestructive = action.isDestructive(user);

    final title = l10n.tOr(action.confirmTitleKey(user), _fallbackTitle(action));
    final message = l10n.tOr(
      action.confirmMessageKey(user),
      _fallbackMessage(action, user.username),
    );

    return AlertDialog(
      icon: Icon(
        action.icon,
        color: isDestructive ? scheme.error : scheme.primary,
      ),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: isDestructive
              ? FilledButton.styleFrom(backgroundColor: scheme.error)
              : null,
          child: Text(l10n.t('confirmAction')),
        ),
      ],
    );
  }

  String _fallbackTitle(UserAdminActionType action) {
    return switch (action) {
      UserAdminActionType.ban => 'Ban User',
      UserAdminActionType.unban => 'Unban User',
      UserAdminActionType.promote => 'Promote User',
      UserAdminActionType.demote => 'Demote User',
      UserAdminActionType.delete => 'Delete Account',
    };
  }

  String _fallbackMessage(UserAdminActionType action, String username) {
    return 'Are you sure you want to perform this action on @$username? '
        'This may take effect immediately.';
  }
}
