import '../entities/gift_entity.dart';
import '../repositories/gifts_repository.dart';

class UpdateGift {
  const UpdateGift(this.repository);
  final GiftsRepository repository;
  Future<GiftEntity> call(String giftId, UpdateGiftData data) =>
      repository.updateGift(giftId, data);
}
