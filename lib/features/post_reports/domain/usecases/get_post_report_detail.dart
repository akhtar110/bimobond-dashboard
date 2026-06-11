import '../entities/post_report_entities.dart';
import '../repositories/post_reports_repository.dart';

class GetPostReportDetail {
  const GetPostReportDetail(this._repository);

  final PostReportsRepository _repository;

  Future<PostReportDetailEntity> call({
    required String postId,
    required ReportPeriodQuery query,
  }) =>
      _repository.getPostDetail(postId: postId, query: query);
}
