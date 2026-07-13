import '../../domain/entities/bulk_gift_action_request.dart';
import '../../domain/entities/bulk_gift_action_result.dart';
import '../../domain/entities/gift_entity.dart';
import '../../domain/enums/bulk_gift_action_type.dart';
import '../../domain/repositories/gifts_repository.dart';
import '../datasources/gifts_remote_datasource.dart';
import '../models/admin_bulk_gift_action.dart';
import '../models/admin_bulk_gifts_dto.dart';

class GiftsRepositoryImpl implements GiftsRepository {
  const GiftsRepositoryImpl(this._dataSource);
  final GiftsRemoteDataSource _dataSource;

  @override
  Future<List<GiftEntity>> getAdminGifts() => _dataSource.getAdminGifts();

  /// Upload the selected image first, then create the gift with the returned URL.
  @override
  Future<GiftEntity> createGift(CreateGiftData data) async {
    final thumbnailUrl = await _dataSource.uploadGiftImage(
      data.imageBytes,
      data.imageName,
    );

    String? animationUrl;
    if (data.animationBytes != null && data.animationBytes!.isNotEmpty) {
      animationUrl = await _dataSource.uploadGiftImage(
        data.animationBytes!,
        data.animationName ?? 'gift-animation.gif',
      );
    }

    return _dataSource.createGiftWithUrl(
      name: data.name,
      thumbnailUrl: thumbnailUrl,
      animationUrl: animationUrl,
      priceCoins: data.priceCoins,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
    );
  }

  /// Update an existing gift.
  /// If [data.imageBytes] is provided the image is uploaded first and the
  /// resulting URL is used as [thumbnailUrl]; any explicit [data.thumbnailUrl]
  /// value is ignored in that case.
  /// Same for [data.animationBytes] → [animationUrl].
  @override
  Future<GiftEntity> updateGift(String giftId, UpdateGiftData data) async {
    String? resolvedThumbnailUrl = data.thumbnailUrl;
    String? resolvedAnimationUrl = data.animationUrl;

    if (data.imageBytes != null && data.imageBytes!.isNotEmpty) {
      resolvedThumbnailUrl = await _dataSource.uploadGiftImage(
        data.imageBytes!,
        data.imageName ?? 'gift.jpg',
      );
    }

    if (data.animationBytes != null && data.animationBytes!.isNotEmpty) {
      resolvedAnimationUrl = await _dataSource.uploadGiftImage(
        data.animationBytes!,
        data.animationName ?? 'gift-animation.gif',
      );
    }

    final patchedData = UpdateGiftData(
      name: data.name,
      thumbnailUrl: resolvedThumbnailUrl,
      animationUrl: resolvedAnimationUrl,
      priceCoins: data.priceCoins,
      isActive: data.isActive,
      publishedAt: data.publishedAt,
    );

    return _dataSource.updateGift(giftId, patchedData);
  }

  @override
  Future<void> deleteGift(String giftId) => _dataSource.deleteGift(giftId);

  @override
  Future<BulkGiftActionResult> executeBulkAction(
    BulkGiftActionRequest request,
  ) async {
    if (request.giftIds.isEmpty) {
      return const BulkGiftActionResult(
        removedGiftIds: [],
        failedGiftIds: [],
      );
    }

    try {
      final dto = AdminBulkGiftsDto(
        giftIds: request.giftIds,
        action: _toAdminAction(request.action),
      );
      final result = await _dataSource.executeAdminBulkAction(dto);

      return BulkGiftActionResult(
        succeededGiftIds: result.affectedGiftIds,
        removedGiftIds:
            result.isDelete ? result.affectedGiftIds : const [],
        failedGiftIds: result.failedGiftIds,
        errorMessage: result.isFullSuccess
            ? null
            : '${result.failedGiftIds.length} gift(s) could not be updated',
      );
    } catch (e) {
      return BulkGiftActionResult(
        removedGiftIds: const [],
        failedGiftIds: request.giftIds,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  AdminBulkGiftAction _toAdminAction(BulkGiftActionType action) =>
      switch (action) {
        BulkGiftActionType.delete => AdminBulkGiftAction.delete,
        BulkGiftActionType.activate => AdminBulkGiftAction.activate,
        BulkGiftActionType.deactivate => AdminBulkGiftAction.deactivate,
      };
}
