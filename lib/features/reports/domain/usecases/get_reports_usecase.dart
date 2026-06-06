import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class GetReports {
  const GetReports(this._repository);
  final ReportsRepository _repository;

  Future<({List<ReportEntity> reports, int total, int lastPage})> call({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
  }) =>
      _repository.getReports(
        page: page,
        limit: limit,
        status: status,
        type: type,
      );
}
