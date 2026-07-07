import '../../domain/enums/bulk_post_action_type.dart';
import '../models/admin_bulk_posts_dto.dart';
import '../models/bulk_admin_action_result.dart';
import '../models/bulk_single_post_result.dart';

abstract class BulkPostsRemoteDataSource {
  Future<BulkAdminActionResult> executeAdminBulkAction(AdminBulkPostsDto dto);

  /// Fallback for actions not supported by the bulk admin endpoint.
  Future<BulkSinglePostResult> applyBulkActionToPost({
    required String postId,
    required BulkPostActionType action,
  });
}
