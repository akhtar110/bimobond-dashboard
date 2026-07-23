import '../entities/seller_verification_entities.dart';
import '../repositories/seller_verification_repository.dart';

class ApproveSellerVerification {
  const ApproveSellerVerification(this.repository);
  final SellerVerificationRepository repository;

  Future<SellerVerificationApplicationEntity> call(String id) =>
      repository.approveApplication(id);
}
