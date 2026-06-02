import '../../../auctions/domain/entities/auction_entity.dart';
import '../entities/paginated_page.dart';
import '../repositories/user_activity_repository.dart';

class GetUserActivityAuctions {
  GetUserActivityAuctions(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<AuctionEntity>> call(
    String userId, {
    required int page,
    required int limit,
    required String type,
  }) =>
      _repository.getUserAuctions(
        userId,
        page: page,
        limit: limit,
        type: type,
      );
}
