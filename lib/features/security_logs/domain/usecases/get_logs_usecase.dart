import '../../../promotions/domain/entities/pagination_meta.dart';
import '../entities/log_entity.dart';
import '../repositories/logs_repository.dart';

class GetLogsUseCase {
  const GetLogsUseCase(this._repository);

  final LogsRepository _repository;

  Future<PaginatedResult<LogEntity>> call(LogsQuery query) {
    return _repository.getLogs(query);
  }
}
