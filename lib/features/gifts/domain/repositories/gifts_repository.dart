import '../entities/gift_entity.dart';

class CreateGiftData {
  const CreateGiftData({
    required this.name,
    required this.thumbnailUrl,
    this.animationUrl,
    required this.priceUsd,
    this.isActive = true,
  });
  final String name;
  final String thumbnailUrl;
  final String? animationUrl;
  final double priceUsd;
  final bool isActive;
}

class UpdateGiftData {
  const UpdateGiftData({
    this.name,
    this.thumbnailUrl,
    this.animationUrl,
    this.priceUsd,
    this.isActive,
  });
  final String? name;
  final String? thumbnailUrl;
  final String? animationUrl;
  final double? priceUsd;
  final bool? isActive;
}

abstract class GiftsRepository {
  Future<List<GiftEntity>> getAdminGifts();
  Future<GiftEntity> createGift(CreateGiftData data);
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data);
  Future<void> deleteGift(String giftId);
}
