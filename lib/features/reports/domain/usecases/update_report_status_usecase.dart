import '../entities/report_entity.dart';
import '../repositories/reports_repository.dart';

class UpdateReportStatus {
  const UpdateReportStatus(this._repository);
  final ReportsRepository _repository;

  /// [status] must be one of: `PENDING`, `RESOLVED`, `DISMISSED`.
  Future<ReportEntity> call({
    required String id,
    required String status,
  }) =>
      _repository.updateReportStatus(id: id, status: status);
}
