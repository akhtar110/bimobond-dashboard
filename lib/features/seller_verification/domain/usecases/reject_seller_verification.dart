import '../entities/seller_verification_entities.dart';
import '../repositories/seller_verification_repository.dart';

class RejectSellerVerification {
  const RejectSellerVerification(this.repository);
  final SellerVerificationRepository repository;

  Future<SellerVerificationApplicationEntity> call(
    String id, {
    required String rejectionReason,
  }) =>
      repository.rejectApplication(
        id,
        rejectionReason: rejectionReason,
      );
}
