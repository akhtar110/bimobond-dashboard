import '../entities/bulk_post_action_request.dart';
import '../entities/bulk_post_action_result.dart';
import '../repositories/bulk_post_repository.dart';

class BulkPostActionUseCase {
  const BulkPostActionUseCase(this._repository);

  final BulkPostRepository _repository;

  Future<BulkPostActionResult> call(BulkPostActionRequest request) {
    return _repository.executeBulkAction(request);
  }
}
