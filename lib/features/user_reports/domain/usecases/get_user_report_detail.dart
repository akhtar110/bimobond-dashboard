import '../entities/user_report_entities.dart';
import '../repositories/user_reports_repository.dart';

class GetUserReportDetail {
  const GetUserReportDetail(this._repository);

  final UserReportsRepository _repository;

  Future<UserReportDetailEntity> call(String userId, {int days = 30}) =>
      _repository.getUserDetail(userId, days: days);
}
