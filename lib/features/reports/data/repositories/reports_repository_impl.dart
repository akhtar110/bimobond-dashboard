import '../../domain/entities/report_entity.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._dataSource);

  final ReportsRemoteDataSource _dataSource;

  @override
  Future<({List<ReportEntity> reports, int total, int lastPage})> getReports({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
  }) =>
      _dataSource.getReports(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );

  @override
  Future<ReportEntity> getReportById(String id) =>
      _dataSource.getReportById(id);

  @override
  Future<ReportEntity> updateReportStatus({
    required String id,
    required String status,
  }) =>
      _dataSource.updateReportStatus(id: id, status: status);
}
