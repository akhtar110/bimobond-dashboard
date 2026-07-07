import 'package:flutter/material.dart';

import '../../../../../core/localization/localization.dart';
import '../../../domain/entities/activity_context.dart';
import '../../../domain/entities/managed_post_entity.dart';
import '../../../../users/domain/entities/user_entity.dart';

class ActivityRelationshipBanner extends StatelessWidget {
  const ActivityRelationshipBanner({
    super.key,
    required this.sourceUser,
    required this.post,
    required this.activityContext,
  });

  final UserEntity sourceUser;
  final ManagedPostEntity post;
  final ActivityContext activityContext;

  String _ownerName() {
    if (post.userFullName != null && post.userFullName!.isNotEmpty) {
      return post.userFullName!;
    }
    if (post.userName != null && post.userName!.isNotEmpty) {
      return post.userName!;
    }
    return post.userId;
  }

  String _actorName() {
    if (sourceUser.fullName != null && sourceUser.fullName!.isNotEmpty) {
      return sourceUser.fullName!;
    }
    return sourceUser.username;
  }

  @override
  Widget build(BuildContext context) {
    if (sourceUser.id == post.userId) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final actor = _actorName();
    final owner = _ownerName();

    final message = switch (activityContext.type) {
      ActivityType.comment => context.tr('activityBannerCommented', {
          'actor': actor,
          'owner': owner,
        }),
      ActivityType.like => context.tr('activityBannerLiked', {
          'actor': actor,
          'owner': owner,
        }),
      ActivityType.mention => context.tr('activityBannerMentioned', {
          'actor': actor,
          'owner': owner,
        }),
      _ => context.tr('activityBannerGeneric', {
          'actor': actor,
          'owner': owner,
        }),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
