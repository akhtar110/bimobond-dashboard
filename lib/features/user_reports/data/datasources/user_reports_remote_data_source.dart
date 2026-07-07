import 'package:dio/dio.dart';

import '../../../user_activity/domain/entities/paginated_page.dart';
import '../../domain/entities/user_report_entities.dart';
import '../models/user_report_models.dart';

abstract class UserReportsRemoteDataSource {
  Future<UserReportsOverviewEntity> getOverview({int days = 30});

  Future<PaginatedPage<UserReportListItemEntity>> getUsersList(
    UserReportListQuery query,
  );

  Future<UserReportDetailEntity> getUserDetail(
    String userId, {
    int days = 30,
  });
}

class UserReportsRemoteDataSourceImpl implements UserReportsRemoteDataSource {
  UserReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<UserReportsOverviewEntity> getOverview({int days = 30}) async {
    final response = await _dio.get(
      '/user-reports/admin/overview',
      queryParameters: {'days': days},
    );
    return UserReportModels.overviewFromJson(response.data);
  }

  @override
  Future<PaginatedPage<UserReportListItemEntity>> getUsersList(
    UserReportListQuery query,
  ) async {
    final params = <String, dynamic>{
      'page': query.page,
      'limit': query.limit,
      'sort': query.sort.apiValue,
    };

    final search = query.search.trim();
    if (search.isNotEmpty) params['search'] = search;
    if (query.isVerified != null) params['isVerified'] = query.isVerified;
    if (query.isBanned != null) params['isBanned'] = query.isBanned;
    if (query.role != null && query.role!.isNotEmpty) {
      params['role'] = query.role;
    }

    final response = await _dio.get(
      '/user-reports/admin/users',
      queryParameters: params,
    );
    return UserReportModels.usersPageFromJson(response.data);
  }

  @override
  Future<UserReportDetailEntity> getUserDetail(
    String userId, {
    int days = 30,
  }) async {
    final response = await _dio.get(
      '/user-reports/admin/users/$userId',
      queryParameters: {'days': days},
    );
    return UserReportModels.detailFromJson(response.data);
  }
}
