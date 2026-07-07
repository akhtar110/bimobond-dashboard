import '../entities/bulk_post_action_request.dart';
import '../entities/bulk_post_action_result.dart';

abstract class BulkPostRepository {
  Future<BulkPostActionResult> executeBulkAction(BulkPostActionRequest request);
}
