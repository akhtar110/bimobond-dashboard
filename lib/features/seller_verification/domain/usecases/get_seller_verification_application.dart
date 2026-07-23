import '../entities/seller_verification_entities.dart';
import '../repositories/seller_verification_repository.dart';

class GetSellerVerificationApplication {
  const GetSellerVerificationApplication(this.repository);
  final SellerVerificationRepository repository;

  Future<SellerVerificationApplicationEntity> call(String id) =>
      repository.getApplication(id);
}
