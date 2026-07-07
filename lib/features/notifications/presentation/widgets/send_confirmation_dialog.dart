import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';

class SendConfirmationDialog extends StatelessWidget {
  const SendConfirmationDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Confirm & Send',
    this.isDanger = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool isDanger;

  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm & Send',
    bool isDanger = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => SendConfirmationDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        isDanger: isDanger,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: CircleAvatar(
        radius: 24,
        backgroundColor:
            isDanger ? scheme.errorContainer : scheme.primaryContainer,
        child: Icon(
          isDanger ? Icons.warning_amber_rounded : Icons.send_rounded,
          color: isDanger ? scheme.onErrorContainer : scheme.onPrimaryContainer,
        ),
      ),
      title: Text(title, textAlign: TextAlign.center),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.t('notificationCancelButton')),
        ),
        const SizedBox(width: 8),
        FilledButton(
          style: isDanger
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                )
              : null,
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
