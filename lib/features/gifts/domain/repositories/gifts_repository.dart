import 'dart:typed_data';

import '../entities/gift_entity.dart';
import '../entities/bulk_gift_action_request.dart';
import '../entities/bulk_gift_action_result.dart';

/// Payload for creating a new gift.
/// The [imageBytes] + [imageName] are uploaded first; the returned URL
/// is used as [thumbnailUrl] when calling POST /gifts/admin.
/// Optional [animationBytes] are uploaded the same way and sent as [animationUrl].
class CreateGiftData {
  const CreateGiftData({
    required this.name,
    required this.imageBytes,
    required this.imageName,
    required this.priceCoins,
    this.isActive = true,
    this.publishedAt,
    this.animationBytes,
    this.animationName,
  });

  final String name;
  final Uint8List imageBytes;
  final String imageName;
  final double priceCoins;
  final bool isActive;

  /// Explicit publish timestamp. Defaults to server-side `DateTime.now()` when null.
  final DateTime? publishedAt;

  /// Optional animation file uploaded before create; result becomes `animationUrl`.
  final Uint8List? animationBytes;
  final String? animationName;
}

class UpdateGiftData {
  const UpdateGiftData({
    this.name,
    this.thumbnailUrl,
    this.animationUrl,
    this.priceCoins,
    this.isActive,
    this.publishedAt,
    this.imageBytes,
    this.imageName,
    this.animationBytes,
    this.animationName,
  });

  final String? name;
  final String? thumbnailUrl;
  final String? animationUrl;
  final double? priceCoins;
  final bool? isActive;

  /// Update the published timestamp. Pass `null` to leave it unchanged.
  final DateTime? publishedAt;

  /// When set, the image is uploaded first and the resulting URL replaces [thumbnailUrl].
  final Uint8List? imageBytes;
  final String? imageName;

  /// When set, the animation is uploaded first and the resulting URL replaces [animationUrl].
  final Uint8List? animationBytes;
  final String? animationName;
}

abstract class GiftsRepository {
  Future<List<GiftEntity>> getAdminGifts();
  Future<GiftEntity> createGift(CreateGiftData data);
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data);
  Future<void> deleteGift(String giftId);
  Future<BulkGiftActionResult> executeBulkAction(BulkGiftActionRequest request);
}
