import 'dart:typed_data';

import '../entities/bulk_gift_action_request.dart';
import '../entities/bulk_gift_action_result.dart';
import '../entities/gift_entity.dart';
import '../entities/gift_group_entities.dart';
import '../entities/gift_reorder_item.dart';
import '../enums/gift_size.dart';
import '../enums/gift_type.dart';

/// Payload for creating a new gift.
class CreateGiftData {
  const CreateGiftData({
    required this.name,
    this.imageBytes,
    this.imageName,
    required this.priceCoins,
    this.size = GiftSize.medium,
    this.type = GiftType.image,
    this.tag,
    this.color,
    this.sortOrder,
    this.isActive = true,
    this.publishedAt,
    this.animationUrl,
    this.animationBytes,
    this.animationName,
    this.audioUrl,
    this.audioBytes,
    this.audioName,
    this.assignGroupId,
  });

  final String name;

  /// Required for [GiftType.image]. Optional for [GiftType.audio]
  /// (a solid-color thumbnail is generated from [color] when omitted).
  final Uint8List? imageBytes;
  final String? imageName;
  final double priceCoins;
  final GiftSize size;
  final GiftType type;
  final String? tag;
  final String? color;
  final int? sortOrder;
  final bool isActive;
  final DateTime? publishedAt;
  final String? animationUrl;
  final Uint8List? animationBytes;
  final String? animationName;
  final String? audioUrl;
  final Uint8List? audioBytes;
  final String? audioName;

  /// Optional panel tab to add the gift to after create.
  final String? assignGroupId;
}

class UpdateGiftData {
  const UpdateGiftData({
    this.name,
    this.thumbnailUrl,
    this.animationUrl,
    this.audioUrl,
    this.color,
    this.type,
    this.tag,
    this.priceCoins,
    this.size,
    this.sortOrder,
    this.isActive,
    this.publishedAt,
    this.clearPublishedAt = false,
    this.clearTag = false,
    this.clearColor = false,
    this.clearAudioUrl = false,
    this.imageBytes,
    this.imageName,
    this.animationBytes,
    this.animationName,
    this.audioBytes,
    this.audioName,
    this.clearAnimationUrl = false,
    this.assignGroupId,
    this.previousAssignGroupId,
  });

  final String? name;
  final String? thumbnailUrl;
  final String? animationUrl;
  final String? audioUrl;
  final String? color;
  final GiftType? type;
  final String? tag;
  final double? priceCoins;
  final GiftSize? size;
  final int? sortOrder;
  final bool? isActive;
  final DateTime? publishedAt;
  final bool clearPublishedAt;
  final bool clearTag;
  final bool clearColor;
  final bool clearAudioUrl;
  final Uint8List? imageBytes;
  final String? imageName;
  final Uint8List? animationBytes;
  final String? animationName;
  final Uint8List? audioBytes;
  final String? audioName;
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
  Future<List<GiftEntity>> reorderGifts(List<GiftReorderItem> items);
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
