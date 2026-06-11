import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/localization/localization.dart';
import '../../../post_management/presentation/utils/moderation_confirm_dialog.dart';
import '../bloc/user_activity_bloc.dart';
import '../bloc/user_unified_activity_bloc.dart';

Future<bool> showDeleteRepostConfirmDialog(BuildContext context) {
  final l10n = context.l10n;
  return showModerationConfirmDialog(
    context,
    title: l10n.tOr('deleteRepostTitle', 'Delete Repost'),
    message: l10n.tOr(
      'deleteRepostMessage',
      'Remove this repost from the user profile?',
    ),
    confirmLabel: l10n.t('delete'),
    destructive: true,
  );
}

Future<void> confirmAndDeleteUserRepost(
  BuildContext context,
  String repostId,
) async {
  final id = repostId.trim();
  if (id.isEmpty) return;

  final confirmed = await showDeleteRepostConfirmDialog(context);
  if (!confirmed || !context.mounted) return;

  context.read<UserActivityBloc>().add(DeleteRepost(id));

  try {
    await context.read<UserActivityBloc>().stream.firstWhere(
          (state) => state.deletingRepostId != id,
        );
  } catch (_) {
    return;
  }

  if (!context.mounted) return;

  final activityState = context.read<UserActivityBloc>().state;
  if (activityState.repostsError != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(activityState.repostsError!),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return;
  }

  context.read<UserUnifiedActivityBloc>().add(RemoveRepostActivityItem(id));

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          context.l10n.tOr('repostDeleted', 'Repost deleted'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
