import '../entities/bulk_gift_action_request.dart';
import '../entities/bulk_gift_action_result.dart';
import '../repositories/gifts_repository.dart';

class BulkGiftActionUseCase {
  const BulkGiftActionUseCase(this._repository);

  final GiftsRepository _repository;

  Future<BulkGiftActionResult> call(BulkGiftActionRequest request) {
    return _repository.executeBulkAction(request);
  }
}
