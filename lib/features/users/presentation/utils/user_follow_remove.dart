import 'package:flutter/material.dart';

import '../../../../core/localization/localization.dart';
import '../../../post_management/presentation/utils/moderation_confirm_dialog.dart';
import '../../domain/entities/user_follow_entity.dart';
import '../cubit/user_follow_list_cubit.dart';

Future<bool> showForceRemoveFollowEdgeConfirmDialog(
  BuildContext context, {
  required UserFollowListKind kind,
  required String displayName,
}) {
  final l10n = context.l10n;
  final isFollowersTab = kind == UserFollowListKind.followers;

  return showModerationConfirmDialog(
    context,
    title: l10n.tOr(
      isFollowersTab ? 'forceRemoveFollowerTitle' : 'forceRemoveFollowingTitle',
      isFollowersTab ? 'Remove follower' : 'Remove following',
    ),
    message: l10n.tOr(
      isFollowersTab
          ? 'forceRemoveFollowerMessage'
          : 'forceRemoveFollowingMessage',
      isFollowersTab
          ? 'Remove $displayName as a follower? This does not block or notify them.'
          : 'Remove $displayName from this user\'s following list? This does not block or notify them.',
    ),
    confirmLabel: l10n.tOr('remove', 'Remove'),
    destructive: true,
  );
}

Future<void> confirmAndForceRemoveFollowEdge({
  required BuildContext context,
  required UserFollowListKind kind,
  required UserFollowSummaryEntity user,
  required UserFollowListCubit cubit,
  VoidCallback? onRemoved,
}) async {
  final displayName = user.fullName?.isNotEmpty == true
      ? user.fullName!
      : '@${user.username}';

  final confirmed = await showForceRemoveFollowEdgeConfirmDialog(
    context,
    kind: kind,
    displayName: displayName,
  );
  if (!confirmed || !context.mounted) return;

  final removed = await cubit.removeFollowEdge(user.id);
  if (!context.mounted) return;

  if (removed) {
    onRemoved?.call();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.tOr(
              kind == UserFollowListKind.followers
                  ? 'followerRemoved'
                  : 'followingRemoved',
              kind == UserFollowListKind.followers
                  ? 'Follower removed'
                  : 'Following removed',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    return;
  }

  final state = cubit.state;
  if (state is UserFollowListLoaded && state.error != null) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(state.error!),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }
}
