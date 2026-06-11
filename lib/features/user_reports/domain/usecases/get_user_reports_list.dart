import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/user_report_entities.dart';
import '../repositories/user_reports_repository.dart';

class GetUserReportsList {
  const GetUserReportsList(this._repository);

  final UserReportsRepository _repository;

  Future<PaginatedPage<UserReportListItemEntity>> call(
    UserReportListQuery query,
  ) =>
      _repository.getUsersList(query);
}
