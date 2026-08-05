import 'package:dio/dio.dart';

import '../models/report_model.dart';

abstract class ReportsRemoteDataSource {
  Future<({List<ReportModel> reports, int total, int lastPage})> getReports({
    int page = 1,
    int limit = 15,
    String? status,
    String? type,
    String? userId,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? from,
    DateTime? to,
    String? sortBy,
    String? sortOrder,
    String? sort,
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
    String? userId,
    String? reporterId,
    String? reportedUserId,
    String? postId,
    String? commentId,
    String? storyId,
    String? search,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? from,
    DateTime? to,
    String? sortBy,
    String? sortOrder,
    String? sort,
  }) async {
    final effectiveStart = startDate ?? from;
    final effectiveEnd = endDate ?? to;
    final effectiveUserId = (userId != null && userId.isNotEmpty)
        ? userId
        : reportedUserId;

    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (status != null && status.isNotEmpty) 'status': status,
      if (type != null && type.isNotEmpty) 'type': type,
      if (reporterId != null && reporterId.isNotEmpty)
        'reporterId': reporterId,
      if (effectiveUserId != null && effectiveUserId.isNotEmpty)
        'userId': effectiveUserId,
      if (reportedUserId != null && reportedUserId.isNotEmpty)
        'reportedUserId': reportedUserId,
      if (postId != null && postId.isNotEmpty) 'postId': postId,
      if (commentId != null && commentId.isNotEmpty) 'commentId': commentId,
      if (storyId != null && storyId.isNotEmpty) 'storyId': storyId,
      if (search != null && search.isNotEmpty) 'search': search,
      if (effectiveStart != null)
        'from': effectiveStart.toUtc().toIso8601String(),
      if (effectiveStart != null)
        'startDate': effectiveStart.toUtc().toIso8601String(),
      if (effectiveEnd != null) 'to': effectiveEnd.toUtc().toIso8601String(),
      if (effectiveEnd != null)
        'endDate': effectiveEnd.toUtc().toIso8601String(),
      if (sortBy != null && sortBy.isNotEmpty) 'sortBy': sortBy,
      if (sortOrder != null && sortOrder.isNotEmpty) 'sortOrder': sortOrder,
      if (sort != null && sort.isNotEmpty)
        'sort': sort
      else if (sortOrder != null && sortOrder.isNotEmpty)
        'sort': sortOrder,
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
    ReportModel report;
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['report'] is Map<String, dynamic>
              ? data['report'] as Map<String, dynamic>
              : data;
      report = ReportModel.fromJson(payload);
    } else {
      report = await getReportById(id);
    }

    // Automatically convert confirmed valid report into a Violation record
    if (status.toUpperCase() == 'RESOLVED') {
      final targetUserId = report.reportedUserId ??
          report.reportedUser?.id ??
          report.post?.userId;

      if (targetUserId != null && targetUserId.isNotEmpty) {
        final reason = report.reason.isNotEmpty
            ? report.reason
            : 'Confirmed valid user report';
        final targetType = report.postId != null
            ? 'POST'
            : (report.commentId != null ? 'COMMENT' : 'USER');
        final targetId = report.postId ?? report.commentId ?? report.reportedUserId;

        final violationPayload = {
          'userId': targetUserId,
          'action': 'CONFIRMED_VIOLATION',
          'reason': reason,
          'category': 'MODERATION',
          'description': 'Confirmed valid report #$id: $reason',
          'reportId': id,
          'targetType': targetType,
          if (targetId != null) 'targetId': targetId,
        };

        try {
          await _dio.post(
            '/user-reports/admin/users/$targetUserId/violations',
            data: violationPayload,
          );
        } on DioException catch (e) {
          if (e.response?.statusCode == 404) {
            try {
              await _dio.post(
                '/users/admin/$targetUserId/violations',
                data: violationPayload,
              );
            } on DioException catch (_) {
              try {
                await _dio.post(
                  '/user-history/admin/logs',
                  data: violationPayload,
                );
              } catch (_) {}
            }
          }
        } catch (_) {}
      }
    }

    return report;
  }
}
