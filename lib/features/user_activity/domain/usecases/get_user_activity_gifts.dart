import '../entities/paginated_page.dart';
import '../entities/user_gift_transaction_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserActivityGifts {
  GetUserActivityGifts(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserGiftTransactionEntity>> call(
    String userId, {
    required int page,
    required int limit,
    required String direction,
  }) =>
      _repository.getUserGifts(
        userId,
        page: page,
        limit: limit,
        direction: direction,
      );
}
