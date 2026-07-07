import '../entities/bulk_post_action_request.dart';
import '../entities/bulk_post_action_result.dart';
import '../enums/bulk_post_action_type.dart';
import 'bulk_post_action_usecase.dart';

class UpdatePostsStatusUseCase {
  const UpdatePostsStatusUseCase(this._bulkAction);

  final BulkPostActionUseCase _bulkAction;

  Future<BulkPostActionResult> call({
    required List<String> postIds,
    required BulkPostActionType statusAction,
  }) {
    assert(_statusActions.contains(statusAction));
    return _bulkAction(
      BulkPostActionRequest(postIds: postIds, action: statusAction),
    );
  }

  static const _statusActions = {
    BulkPostActionType.publish,
    BulkPostActionType.draft,
    BulkPostActionType.underReview,
    BulkPostActionType.hide,
    BulkPostActionType.archive,
    BulkPostActionType.ban,
    BulkPostActionType.unban,
    BulkPostActionType.softDelete,
    BulkPostActionType.permanentDelete,
  };
}
