import '../entities/seller_verification_entities.dart';
import '../repositories/seller_verification_repository.dart';

class GetSellerVerificationApplications {
  const GetSellerVerificationApplications(this.repository);
  final SellerVerificationRepository repository;

  Future<SellerVerificationPageEntity> call({
    required int page,
    required int limit,
    required AdminSellerVerificationQuery query,
  }) =>
      repository.getAdminApplications(
        page: page,
        limit: limit,
        query: query,
      );
}
