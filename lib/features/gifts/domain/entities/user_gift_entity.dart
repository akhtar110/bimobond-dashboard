import 'gift_entity.dart';

class UserGiftEntity {
  const UserGiftEntity({
    required this.id,
    required this.userId,
    required this.giftId,
    required this.quantity,
    required this.createdAt,
    required this.updatedAt,
    this.gift,
  });

  final String id;
  final String userId;
  final String giftId;
  final int quantity;
  final DateTime createdAt;
  final DateTime updatedAt;
  final GiftEntity? gift;
}
