import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/user_report_entities.dart';
import '../../domain/repositories/user_reports_repository.dart';
import '../datasources/user_reports_remote_data_source.dart';

class UserReportsRepositoryImpl implements UserReportsRepository {
  UserReportsRepositoryImpl(this._remote);

  final UserReportsRemoteDataSource _remote;

  @override
  Future<UserReportsOverviewEntity> getOverview({int days = 30}) =>
      _remote.getOverview(days: days);

  @override
  Future<PaginatedPage<UserReportListItemEntity>> getUsersList(
    UserReportListQuery query,
  ) =>
      _remote.getUsersList(query);

  @override
  Future<UserReportDetailEntity> getUserDetail(
    String userId, {
    int days = 30,
  }) =>
      _remote.getUserDetail(userId, days: days);
}
