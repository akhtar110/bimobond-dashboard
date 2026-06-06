import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

/// Compact moderation-style confirmation dialog shared across post actions.
Future<bool> showModerationConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  bool destructive = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final l10n = context.l10n;

  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: scheme.onSurface.withValues(alpha: 0.75)),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(ctx, false),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(
            backgroundColor: destructive ? scheme.error : null,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  ).then((value) => value ?? false);
}

Future<bool> showDeletePostConfirmDialog(BuildContext context) {
  final l10n = context.l10n;
  return showModerationConfirmDialog(
    context,
    title: l10n.t('deletePostTitle'),
    message: l10n.t('deletePostMessage'),
    confirmLabel: l10n.t('delete'),
    destructive: true,
  );
}

Future<bool> showDeleteCommentConfirmDialog(BuildContext context) {
  final l10n = context.l10n;
  return showModerationConfirmDialog(
    context,
    title: l10n.t('deleteCommentTitle'),
    message: l10n.t('deleteCommentMessage'),
    confirmLabel: l10n.t('delete'),
    destructive: true,
  );
}
