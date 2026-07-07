import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/entities/sound_entities.dart';

Future<bool> confirmSoundDelete(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.t('soundConfirmDeleteTitle')),
      content: Text(l10n.t('soundConfirmDeleteMessage')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(ctx).colorScheme.error,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.t('delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> confirmSoundToggleActive(
  BuildContext context, {
  required bool activate,
}) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(
        activate
            ? l10n.t('soundConfirmActivateTitle')
            : l10n.t('soundConfirmDeactivateTitle'),
      ),
      content: Text(
        activate
            ? l10n.t('soundConfirmActivateMessage')
            : l10n.t('soundConfirmDeactivateMessage'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.t('confirmAction')),
        ),
      ],
    ),
  );
  return result ?? false;
}

Future<bool> confirmBulkSoundAction(
  BuildContext context, {
  required BulkSoundActionType action,
  required int count,
}) async {
  final l10n = context.l10n;
  final title = switch (action) {
    BulkSoundActionType.activate => l10n.t('soundBulkActivateTitle'),
    BulkSoundActionType.deactivate => l10n.t('soundBulkDeactivateTitle'),
    BulkSoundActionType.delete => l10n.t('soundBulkDeleteTitle'),
  };
  final message = context.tr('soundBulkConfirmMessage', {'count': '$count'});

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: action == BulkSoundActionType.delete
              ? FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                )
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.t('confirmAction')),
        ),
      ],
    ),
  );
  return result ?? false;
}
