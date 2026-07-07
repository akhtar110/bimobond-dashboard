import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../enums/bulk_post_action_type.dart';

/// Local preview updates when the bulk API succeeds without returning bodies.
ManagedPostEntity applyBulkPostLocalUpdate(
  ManagedPostEntity post,
  BulkPostActionType action,
) {
  return switch (action) {
    BulkPostActionType.publish || BulkPostActionType.unban => post.copyWith(
        status: 'PUBLISHED',
      ),
    BulkPostActionType.draft => post.copyWith(status: 'DRAFT'),
    BulkPostActionType.underReview => post.copyWith(status: 'UNDER_REVIEW'),
    BulkPostActionType.hide => post.copyWith(status: 'HIDDEN'),
    BulkPostActionType.archive => post.copyWith(status: 'ARCHIVED'),
    BulkPostActionType.ban => post.copyWith(status: 'BANNED'),
    BulkPostActionType.enableComments => post.copyWith(allowComments: true),
    BulkPostActionType.disableComments => post.copyWith(allowComments: false),
    BulkPostActionType.enableDuets => post.copyWith(allowDuets: true),
    BulkPostActionType.disableDuets => post.copyWith(allowDuets: false),
    BulkPostActionType.enableStitch => post.copyWith(allowStitch: true),
    BulkPostActionType.disableStitch => post.copyWith(allowStitch: false),
    BulkPostActionType.setPublic => post.copyWith(privacyStatus: 'PUBLIC'),
    BulkPostActionType.setPrivate => post.copyWith(privacyStatus: 'PRIVATE'),
    BulkPostActionType.setFollowersOnly =>
      post.copyWith(privacyStatus: 'FRIENDS'),
    _ => post,
  };
}
