import '../../domain/entities/seller_verification_entities.dart';
import '../../domain/repositories/seller_verification_repository.dart';
import '../datasources/seller_verification_remote_datasource.dart';

class SellerVerificationRepositoryImpl implements SellerVerificationRepository {
  const SellerVerificationRepositoryImpl(this._dataSource);

  final SellerVerificationRemoteDataSource _dataSource;

  @override
  Future<SellerVerificationPageEntity> getAdminApplications({
    required int page,
    required int limit,
    required AdminSellerVerificationQuery query,
  }) =>
      _dataSource.getAdminApplications(
        page: page,
        limit: limit,
        query: query,
      );

  @override
  Future<SellerVerificationApplicationEntity> getApplication(String id) =>
      _dataSource.getApplication(id);

  @override
  Future<SellerVerificationApplicationEntity> approveApplication(String id) =>
      _dataSource.approveApplication(id);

  @override
  Future<SellerVerificationApplicationEntity> rejectApplication(
    String id, {
    required String rejectionReason,
  }) =>
      _dataSource.rejectApplication(
        id,
        rejectionReason: rejectionReason,
      );
}
