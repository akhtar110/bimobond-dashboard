import '../../../promotions/domain/entities/pagination_meta.dart';
import '../entities/log_entity.dart';

abstract class LogsRepository {
  Future<PaginatedResult<LogEntity>> getLogs(LogsQuery query);
}
