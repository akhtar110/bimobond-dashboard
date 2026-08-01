import '../../../promotions/domain/entities/pagination_meta.dart';
import '../../domain/entities/log_entity.dart';
import '../../domain/repositories/logs_repository.dart';
import '../datasources/logs_remote_datasource.dart';

class LogsRepositoryImpl implements LogsRepository {
  LogsRepositoryImpl(this._remoteDataSource);

  final LogsRemoteDataSource _remoteDataSource;

  @override
  Future<PaginatedResult<LogEntity>> getLogs(LogsQuery query) {
    return _remoteDataSource.getLogs(query);
  }
}
