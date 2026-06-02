import '../repositories/gifts_repository.dart';

class DeleteGift {
  const DeleteGift(this.repository);
  final GiftsRepository repository;
  Future<void> call(String giftId) => repository.deleteGift(giftId);
}
