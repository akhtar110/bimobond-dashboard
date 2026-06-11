import '../entities/post_report_entities.dart';
import '../repositories/post_reports_repository.dart';

class GetPostReportsOverview {
  const GetPostReportsOverview(this._repository);

  final PostReportsRepository _repository;

  Future<PostReportOverviewEntity> call(ReportPeriodQuery query) =>
      _repository.getOverview(query);
}
