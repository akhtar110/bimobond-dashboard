import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../domain/enums/promotion_enums.dart';

Future<bool> confirmCampaignStatusChange(
  BuildContext context, {
  required String status,
}) async {
  final l10n = context.l10n;
  final label = _statusLabel(l10n, status);

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.t('promoConfirmStatusTitle')),
      content: Text(
        context.tr('promoConfirmStatusMessage', {'status': label}),
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

Future<bool> confirmCampaignDelete(BuildContext context) async {
  final l10n = context.l10n;
  final scheme = Theme.of(context).colorScheme;

  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.t('promoConfirmDeleteTitle')),
      content: Text(l10n.t('promoConfirmDeleteMessage')),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(l10n.t('cancel')),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(l10n.t('delete')),
        ),
      ],
    ),
  );
  return result ?? false;
}

String _statusLabel(dynamic l10n, String status) {
  return switch (CampaignStatus.tryParse(status)) {
    CampaignStatus.pendingPayment => l10n.t('promoStatusPendingPayment'),
    CampaignStatus.active => l10n.t('promoStatusActive'),
    CampaignStatus.paused => l10n.t('promoStatusPaused'),
    CampaignStatus.completed => l10n.t('promoStatusCompleted'),
    CampaignStatus.cancelled => l10n.t('promoStatusCancelled'),
    CampaignStatus.rejected => l10n.t('promoStatusRejected'),
    _ => status,
  };
}
