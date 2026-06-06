import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../bloc/post_management_bloc.dart';
import 'moderation_confirm_dialog.dart';
import 'post_detail_labels.dart';

typedef _StatusConfirmCopy = ({
  String title,
  String message,
  String confirmLabel,
  bool destructive,
});

_StatusConfirmCopy _statusChangeConfirmCopy(
  AppLocalizations l10n,
  String newStatus,
  String currentStatus,
) {
  final to = newStatus.toUpperCase();
  final from = currentStatus.toUpperCase();
  final statusLabel = postStatusLabel(l10n, to);

  switch (to) {
    case 'HIDDEN':
      return (
        title: l10n.t('hidePost'),
        message: l10n.t('moderationConfirmHidePost'),
        confirmLabel: l10n.t('hide'),
        destructive: false,
      );
    case 'ARCHIVED':
      return (
        title: l10n.t('archivePost'),
        message: l10n.t('moderationConfirmArchivePost'),
        confirmLabel: l10n.t('archive'),
        destructive: false,
      );
    case 'PUBLISHED'
        when from == 'HIDDEN' || from == 'ARCHIVED' || from == 'BANNED':
      return (
        title: l10n.t('restorePost'),
        message: l10n.t('moderationConfirmRestorePost'),
        confirmLabel: l10n.t('restore'),
        destructive: false,
      );
    default:
      return (
        title: l10n.t('changeStatus'),
        message: l10n.tArgs('moderationConfirmChangeStatusTo', {
          'status': statusLabel,
        }),
        confirmLabel: l10n.t('changeStatus'),
        destructive: to == 'BANNED',
      );
  }
}

/// Shows a confirmation dialog before applying a post status change.
Future<bool> showPostStatusChangeConfirmDialog(
  BuildContext context, {
  required String currentStatus,
  required String newStatus,
}) {
  final l10n = context.l10n;
  final copy = _statusChangeConfirmCopy(l10n, newStatus, currentStatus);

  return showModerationConfirmDialog(
    context,
    title: copy.title,
    message: copy.message,
    confirmLabel: copy.confirmLabel,
    destructive: copy.destructive,
  );
}

/// Confirms then dispatches [UpdatePostStatusEvent] when the admin accepts.
Future<void> requestPostStatusChange(
  BuildContext context, {
  required String currentStatus,
  required String newStatus,
}) async {
  final next = newStatus.toUpperCase();
  if (currentStatus.toUpperCase() == next) return;

  final confirmed = await showPostStatusChangeConfirmDialog(
    context,
    currentStatus: currentStatus,
    newStatus: next,
  );
  if (confirmed && context.mounted) {
    context.read<PostManagementBloc>().add(UpdatePostStatusEvent(next));
  }
}
