import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/users_bloc.dart';

String usersPromoteConfirmMessage(AppLocalizations l10n, int count) {
  return contextFreeTr(l10n, 'bulkConfirmPromoteUsers', count);
}

String usersDemoteConfirmMessage(AppLocalizations l10n, int count) {
  return contextFreeTr(l10n, 'bulkConfirmDemoteUsers', count);
}

String usersDeleteConfirmMessage(AppLocalizations l10n, int count) {
  return contextFreeTr(l10n, 'bulkConfirmDeleteUsers', count);
}

String usersBanConfirmMessage(AppLocalizations l10n, int count) {
  return contextFreeTr(l10n, 'bulkConfirmSuspendUsers', count);
}

String usersUnbanConfirmMessage(AppLocalizations l10n, int count) {
  return contextFreeTr(l10n, 'bulkConfirmActivateUsers', count);
}

String contextFreeTr(AppLocalizations l10n, String key, int count) {
  final template = l10n.t(key);
  return template.replaceAll('{count}', '$count');
}

Future<bool> confirmUsersBulkAction(
  BuildContext context, {
  required String title,
  required String message,
  bool destructive = false,
}) async {
  final scheme = Theme.of(context).colorScheme;

  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      final l10n = dialogContext.l10n;
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: scheme.error)
                : null,
            child: Text(l10n.t('confirmAction')),
          ),
        ],
      );
    },
  );

  return result == true;
}

int selectedUsersCount(BuildContext context) {
  final state = context.read<UsersBloc>().state;
  if (state is UsersLoaded) return state.selectedCount;
  return 0;
}
