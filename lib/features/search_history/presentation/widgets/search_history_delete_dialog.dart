import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

Future<bool?> showSearchHistoryDeleteDialog(
  BuildContext context, {
  String? title,
  String? message,
  String? confirmLabel,
}) {
  final l10n = context.l10n;
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      icon: Icon(
        Icons.delete_outline_rounded,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        title ?? l10n.tOr('searchHistoryDeleteTitle', 'Delete search history?'),
      ),
      content: Text(
        message ??
            l10n.tOr(
              'searchHistoryDeleteMessage',
              'This action cannot be undone.',
            ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel ?? l10n.t('delete')),
        ),
      ],
    ),
  );
}
