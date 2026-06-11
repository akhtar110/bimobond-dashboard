import '../../../user_activity/domain/entities/paginated_page.dart';
import '../entities/user_report_entities.dart';

abstract class UserReportsRepository {
  Future<UserReportsOverviewEntity> getOverview({int days = 30});

  Future<PaginatedPage<UserReportListItemEntity>> getUsersList(
    UserReportListQuery query,
  );

  Future<UserReportDetailEntity> getUserDetail(
    String userId, {
    int days = 30,
  });
}
