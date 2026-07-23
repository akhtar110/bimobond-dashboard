import 'package:dio/dio.dart';

import '../../domain/entities/seller_verification_entities.dart';
import '../models/seller_verification_models.dart';

abstract class SellerVerificationRemoteDataSource {
  Future<SellerVerificationPageModel> getAdminApplications({
    required int page,
    required int limit,
    required AdminSellerVerificationQuery query,
  });

  Future<SellerVerificationApplicationModel> getApplication(String id);

  Future<SellerVerificationApplicationModel> approveApplication(String id);

  Future<SellerVerificationApplicationModel> rejectApplication(
    String id, {
    required String rejectionReason,
  });
}

class SellerVerificationRemoteDataSourceImpl
    implements SellerVerificationRemoteDataSource {
  const SellerVerificationRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<SellerVerificationPageModel> getAdminApplications({
    required int page,
    required int limit,
    required AdminSellerVerificationQuery query,
  }) async {
    final response = await _dio.get(
      '/seller-verification/admin/all',
      queryParameters: query.toQueryParameters(page: page, limit: limit),
    );
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return SellerVerificationPageModel.fromJson(data);
    }
    if (data is List) {
      final applications = data
          .map(
            (e) => SellerVerificationApplicationModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList();
      return SellerVerificationPageModel(
        applications: applications,
        currentPage: page,
        lastPage: 1,
        total: applications.length,
      );
    }
    throw Exception('Invalid seller verification list response');
  }

  @override
  Future<SellerVerificationApplicationModel> getApplication(String id) async {
    // Admin detail/approve/reject are keyed by **userId**.
    final response = await _dio.get('/seller-verification/admin/$id');
    return _parseApplication(response.data);
  }

  @override
  Future<SellerVerificationApplicationModel> approveApplication(
    String userId,
  ) async {
    final response = await _dio.patch(
      '/seller-verification/admin/$userId/approve',
    );
    return _parseApplication(response.data);
  }

  @override
  Future<SellerVerificationApplicationModel> rejectApplication(
    String userId, {
    required String rejectionReason,
  }) async {
    final response = await _dio.patch(
      '/seller-verification/admin/$userId/reject',
      data: {'rejectionReason': rejectionReason.trim()},
    );
    return _parseApplication(response.data);
  }

  SellerVerificationApplicationModel _parseApplication(dynamic data) {
    if (data is Map<String, dynamic>) {
      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data['application'] is Map<String, dynamic>
              ? data['application'] as Map<String, dynamic>
              : data;
      return SellerVerificationApplicationModel.fromJson(payload);
    }
    throw Exception('Invalid seller verification response');
  }
}
