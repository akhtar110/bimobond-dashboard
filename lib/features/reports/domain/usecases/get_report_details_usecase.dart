import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class GetReportDetails {
  const GetReportDetails(this._repository);
  final ReportsRepository _repository;

  Future<ReportEntity> call(String id) => _repository.getReportById(id);
}
