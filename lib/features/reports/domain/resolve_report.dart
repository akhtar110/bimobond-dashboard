import 'reports_repository.dart';

class ResolveReport {
  const ResolveReport(this.repository);
  final ReportsRepository repository;

  Future<void> call(String reportId, String action) =>
      repository.resolveReport(reportId, action);
}
