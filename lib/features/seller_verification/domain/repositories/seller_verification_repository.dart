import '../entities/seller_verification_entities.dart';

abstract class SellerVerificationRepository {
  Future<SellerVerificationPageEntity> getAdminApplications({
    required int page,
    required int limit,
    required AdminSellerVerificationQuery query,
  });

  Future<SellerVerificationApplicationEntity> getApplication(String id);

  Future<SellerVerificationApplicationEntity> approveApplication(String id);

  Future<SellerVerificationApplicationEntity> rejectApplication(
    String id, {
    required String rejectionReason,
  });
}
