import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

Future<void> showFeConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required VoidCallback onConfirm,
}) {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;

  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: scheme.error),
          const SizedBox(width: 10),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message, textAlign: TextAlign.start),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () {
            Navigator.of(ctx).pop();
            onConfirm();
          },
          child: Text(l10n.tOr('feConfirm', 'Confirm')),
        ),
      ],
    ),
  );
}
