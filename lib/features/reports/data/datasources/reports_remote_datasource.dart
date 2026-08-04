import 'package:dio/dio.dart';

import '../models/report_model.dart';

abstract class ReportsRemoteDataSource {
  Future<({List<ReportModel> reports, int total, int lastPage})> getReports({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  });

  Future<ReportModel> getReportById(String id);

  Future<ReportModel> updateReportStatus({
    required String id,
    required String status,
  });
}

class ReportsRemoteDataSourceImpl implements ReportsRemoteDataSource {
  const ReportsRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<({List<ReportModel> reports, int total, int lastPage})> getReports({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    String? sortBy,
    String? sortOrder,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
      if (reporterId != null && reporterId.isNotEmpty)
        'reporterId': reporterId,
      if (reportedUserId != null && reportedUserId.isNotEmpty) ...{
        'userId': reportedUserId,
        'reportedUserId': reportedUserId,
      },
      if (postId != null && postId.isNotEmpty) 'postId': postId,
      if (commentId != null && commentId.isNotEmpty) 'commentId': commentId,
      if (storyId != null && storyId.isNotEmpty) 'storyId': storyId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (startDate != null) 'from': startDate.toUtc().toIso8601String(),
      if (startDate != null) 'startDate': startDate.toUtc().toIso8601String(),
      if (endDate != null) 'to': endDate.toUtc().toIso8601String(),
      if (endDate != null) 'endDate': endDate.toUtc().toIso8601String(),
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sort': sortOrder,
    };

    final response = await _dio.get('/reports', queryParameters: params);
    return _parseReportsPage(response.data);
  }

  ({List<ReportModel> reports, int total, int lastPage}) _parseReportsPage(
    dynamic data,
  ) {
    // Some backends return a bare array.
    if (data is List) {
      final reports = data
          .whereType<Map<String, dynamic>>()
          .map(ReportModel.fromJson)
          .toList();
      return (reports: reports, total: reports.length, lastPage: 1);
    }

    if (data is! Map<String, dynamic>) {
      throw Exception('Unexpected reports response format');
    }

    final raw = data;
    dynamic rawList = raw['reports'] ?? raw['data'];

    // Nested envelope: { data: { reports: [...] } }
    if (rawList is Map<String, dynamic>) {
      rawList = rawList['reports'] ?? rawList['data'] ?? rawList['items'];
    }

    final list = rawList is List ? rawList : const [];
    final reports = list
        .whereType<Map<String, dynamic>>()
        .map(ReportModel.fromJson)
        .toList();

    final meta = raw['meta'] is Map<String, dynamic>
        ? raw['meta'] as Map<String, dynamic>
        : raw['pagination'] is Map<String, dynamic>
            ? raw['pagination'] as Map<String, dynamic>
            : <String, dynamic>{};

    final total = (meta['total'] as num?)?.toInt() ?? reports.length;
    final lastPage = (meta['lastPage'] as num?)?.toInt() ??
        (meta['totalPages'] as num?)?.toInt() ??
        1;

    return (reports: reports, total: total, lastPage: lastPage);
  }

  @override
  Future<ReportModel> getReportById(String id) async {
    final response = await _dio.get('/reports/$id');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['report'] is Map<String, dynamic>
              ? data['report'] as Map<String, dynamic>
              : data;
      return ReportModel.fromJson(payload);
    }
    throw Exception('Unexpected report detail response format');
  }

  @override
  Future<ReportModel> updateReportStatus({
    required String id,
    required String status,
  }) async {
    final response = await _dio.patch(
      '/reports/$id/status',
      data: {'status': status},
      options: Options(contentType: Headers.jsonContentType),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['report'] is Map<String, dynamic>
              ? data['report'] as Map<String, dynamic>
              : data;
      return ReportModel.fromJson(payload);
    }
    throw Exception('Unexpected report status response format');
  }
}
