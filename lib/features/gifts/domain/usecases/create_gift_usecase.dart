import '../entities/gift_entity.dart';
import '../repositories/gifts_repository.dart';

class CreateGift {
  const CreateGift(this.repository);
  final GiftsRepository repository;
  Future<GiftEntity> call(CreateGiftData data) =>
      repository.createGift(data);
}
