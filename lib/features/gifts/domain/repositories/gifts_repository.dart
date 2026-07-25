import 'dart:typed_data';

import '../entities/bulk_gift_action_request.dart';
import '../entities/bulk_gift_action_result.dart';
import '../entities/gift_entity.dart';
import '../entities/gift_group_entities.dart';
import '../enums/gift_size.dart';

/// Payload for creating a new gift.
class CreateGiftData {
  const CreateGiftData({
    required this.name,
    required this.imageBytes,
    required this.imageName,
    required this.priceCoins,
    this.size = GiftSize.medium,
    this.isActive = true,
    this.publishedAt,
    this.animationUrl,
    this.animationBytes,
    this.animationName,
    this.assignGroupId,
  });

  final String name;
  final Uint8List imageBytes;
  final String imageName;
  final double priceCoins;
  final GiftSize size;
  final bool isActive;
  final DateTime? publishedAt;
  final String? animationUrl;
  final Uint8List? animationBytes;
  final String? animationName;

  /// Optional panel tab to add the gift to after create.
  final String? assignGroupId;
}

class UpdateGiftData {
  const UpdateGiftData({
    this.name,
    this.thumbnailUrl,
    this.animationUrl,
    this.priceCoins,
    this.size,
    this.isActive,
    this.publishedAt,
    this.clearPublishedAt = false,
    this.imageBytes,
    this.imageName,
    this.animationBytes,
    this.animationName,
    this.clearAnimationUrl = false,
    this.assignGroupId,
    this.previousAssignGroupId,
  });

  final String? name;
  final String? thumbnailUrl;
  final String? animationUrl;
  final double? priceCoins;
  final GiftSize? size;
  final bool? isActive;
  final DateTime? publishedAt;
  final bool clearPublishedAt;
  final Uint8List? imageBytes;
  final String? imageName;
  final Uint8List? animationBytes;
  final String? animationName;
  final bool clearAnimationUrl;

  /// Desired panel tab after update (`null` = none / remove from tab).
  final String? assignGroupId;

  /// Tab the gift was in when the edit dialog opened (for move/remove).
  final String? previousAssignGroupId;
}

abstract class GiftsRepository {
  Future<List<GiftEntity>> getAdminGifts();
  Future<GiftEntity> createGift(CreateGiftData data);
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data);
  Future<void> deleteGift(String giftId);
  Future<BulkGiftActionResult> executeBulkAction(BulkGiftActionRequest request);
  Future<String> uploadGiftFile(Uint8List bytes, String filename);

  Future<List<GiftGroupEntity>> getGiftGroups();
  Future<GiftGroupEntity> createGiftGroup(CreateGiftGroupData data);
  Future<List<GiftGroupEntity>> reorderGiftGroups(
    List<GiftGroupReorderItem> items,
  );
  Future<GiftGroupEntity> updateGiftGroup(
    String groupId,
    UpdateGiftGroupData data,
  );
  Future<void> deleteGiftGroup(String groupId);
  Future<GiftGroupEntity> replaceGroupGifts(
    String groupId,
    List<GiftGroupMembershipItem> gifts,
  );
}
