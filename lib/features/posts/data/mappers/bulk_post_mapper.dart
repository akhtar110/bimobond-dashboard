import '../../../../features/post_management/data/models/managed_post_model.dart';
import '../../../../features/post_management/domain/entities/managed_post_entity.dart';
import '../../domain/enums/bulk_post_action_type.dart';
import '../models/admin_bulk_post_action.dart';
import '../models/admin_bulk_posts_dto.dart';

class BulkPostMapper {
  const BulkPostMapper._();

  static ManagedPostEntity toEntity(ManagedPostModel model) => model;

  /// Actions supported by `POST /posts/admin/bulk`.
  static bool usesAdminBulkApi(BulkPostActionType action) => switch (action) {
        BulkPostActionType.publish ||
        BulkPostActionType.draft ||
        BulkPostActionType.underReview ||
        BulkPostActionType.hide ||
        BulkPostActionType.archive ||
        BulkPostActionType.ban ||
        BulkPostActionType.unban ||
        BulkPostActionType.softDelete ||
        BulkPostActionType.permanentDelete =>
          true,
        _ => false,
      };

  static AdminBulkPostsDto toAdminBulkDto({
    required List<String> postIds,
    required BulkPostActionType action,
  }) {
    return switch (action) {
      BulkPostActionType.publish => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.publish,
        ),
      BulkPostActionType.hide => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.hide,
        ),
      BulkPostActionType.ban => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.ban,
        ),
      BulkPostActionType.softDelete ||
      BulkPostActionType.permanentDelete =>
        AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.delete,
        ),
      BulkPostActionType.draft => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.updateStatus,
          status: 'DRAFT',
        ),
      BulkPostActionType.underReview => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.updateStatus,
          status: 'UNDER_REVIEW',
        ),
      BulkPostActionType.archive => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.updateStatus,
          status: 'ARCHIVED',
        ),
      BulkPostActionType.unban => AdminBulkPostsDto(
          postIds: postIds,
          action: AdminBulkPostAction.updateStatus,
          status: 'PUBLISHED',
        ),
      _ => throw ArgumentError(
          'Action $action is not supported by the admin bulk posts API',
        ),
    };
  }

  static ManagedPostUpdateData updateDataFor(BulkPostActionType action) {
    switch (action) {
      case BulkPostActionType.enableComments:
        return const ManagedPostUpdateData(allowComments: true);
      case BulkPostActionType.disableComments:
        return const ManagedPostUpdateData(allowComments: false);
      case BulkPostActionType.enableDuets:
        return const ManagedPostUpdateData(allowDuets: true);
      case BulkPostActionType.disableDuets:
        return const ManagedPostUpdateData(allowDuets: false);
      case BulkPostActionType.enableStitch:
        return const ManagedPostUpdateData(allowStitch: true);
      case BulkPostActionType.disableStitch:
        return const ManagedPostUpdateData(allowStitch: false);
      case BulkPostActionType.setPublic:
        return const ManagedPostUpdateData(privacyStatus: 'PUBLIC');
      case BulkPostActionType.setPrivate:
        return const ManagedPostUpdateData(privacyStatus: 'PRIVATE');
      case BulkPostActionType.setFollowersOnly:
        return const ManagedPostUpdateData(privacyStatus: 'FRIENDS');
      case BulkPostActionType.feature:
        return const ManagedPostUpdateData(status: 'PUBLISHED');
      case BulkPostActionType.unfeature:
        return const ManagedPostUpdateData(status: 'PUBLISHED');
      default:
        return const ManagedPostUpdateData();
    }
  }
}
