import '../entities/paginated_page.dart';
import '../entities/user_device_entity.dart';
import '../repositories/user_activity_repository.dart';

class GetUserActivityDevices {
  GetUserActivityDevices(this._repository);

  final UserActivityRepository _repository;

  Future<PaginatedPage<UserDeviceEntity>> call(
    String userId, {
    required int page,
    required int limit,
  }) =>
      _repository.getUserDevices(userId, page: page, limit: limit);
}
