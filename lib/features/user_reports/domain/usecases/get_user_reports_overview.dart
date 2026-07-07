import '../entities/user_report_entities.dart';
import '../repositories/user_reports_repository.dart';

class GetUserReportsOverview {
  const GetUserReportsOverview(this._repository);

  final UserReportsRepository _repository;

  Future<UserReportsOverviewEntity> call({int days = 30}) =>
      _repository.getOverview(days: days);
}
