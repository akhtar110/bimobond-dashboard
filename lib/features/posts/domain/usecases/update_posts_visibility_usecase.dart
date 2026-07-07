import '../entities/bulk_post_action_request.dart';
import '../entities/bulk_post_action_result.dart';
import '../enums/bulk_post_action_type.dart';
import 'bulk_post_action_usecase.dart';

class UpdatePostsVisibilityUseCase {
  const UpdatePostsVisibilityUseCase(this._bulkAction);

  final BulkPostActionUseCase _bulkAction;

  Future<BulkPostActionResult> call({
    required List<String> postIds,
    required BulkPostActionType visibilityAction,
  }) {
    assert(_visibilityActions.contains(visibilityAction));
    return _bulkAction(
      BulkPostActionRequest(postIds: postIds, action: visibilityAction),
    );
  }

  static const _visibilityActions = {
    BulkPostActionType.setPublic,
    BulkPostActionType.setPrivate,
    BulkPostActionType.setFollowersOnly,
  };
}
